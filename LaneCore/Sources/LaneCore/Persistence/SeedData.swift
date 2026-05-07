import Foundation
import GRDB

public enum SeedData {
    public static func seedIfEmpty(pool: DatabaseWriter) throws {
        let count = try pool.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM requirement") ?? 0
        }
        guard count == 0 else { return }

        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())

        try pool.write { db in
            try db.execute(sql: """
                INSERT INTO group_ (id, name, color, icon, sort_order, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, arguments: ["g_req", "需求", "#7A8C7A", "●", 0, today])

            try db.execute(sql: """
                INSERT INTO group_ (id, name, color, icon, sort_order, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, arguments: ["g_tech", "技建", "#8A7A6A", "◆", 1, today])

            try db.execute(sql: """
                INSERT INTO stage_template (id, name, is_default, created_at)
                VALUES (?, ?, ?, ?)
            """, arguments: ["tmpl_std", "标准开发流程", true, today])

            let items = ["评审", "设计", "开发", "联调", "测试", "上线"]
            for (i, name) in items.enumerated() {
                try db.execute(sql: """
                    INSERT INTO stage_template_item (id, template_id, name, sort_order)
                    VALUES (?, ?, ?, ?)
                """, arguments: ["tmpl_std_item_\(i)", "tmpl_std", name, i])
            }

            let reqs: [(id: String, groupId: String, title: String, sortOrder: Int)] = [
                ("r1", "g_req", "用户登录流程优化", 0),
                ("r2", "g_req", "消息推送功能", 1),
                ("r3", "g_req", "数据导出支持", 2),
                ("r4", "g_tech", "CI/CD 流水线搭建", 0),
                ("r5", "g_tech", "监控告警接入", 1),
            ]

            for req in reqs {
                try db.execute(sql: """
                    INSERT INTO requirement
                        (id, group_id, title, description, template_id, status,
                         sort_order, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [req.id, req.groupId, req.title, "", "tmpl_std", "active",
                                 req.sortOrder, today, today])
            }

            let plans: [(reqId: String, plan: [StagePlan])] = [
                ("r1", [
                    .done(daysAgo: 20, duration: 3),
                    .done(daysAgo: 17, duration: 4),
                    .done(daysAgo: 13, duration: 5),
                    .done(daysAgo: 8, duration: 3),
                    .active(startDaysAgo: 5, endDaysFromNow: 2),
                    .pending,
                ]),
                ("r2", [
                    .done(daysAgo: 10, duration: 2),
                    .done(daysAgo: 8, duration: 3),
                    .active(startDaysAgo: 5, endDaysFromNow: 5),
                    .pending,
                    .pending,
                    .pending,
                ]),
                ("r3", [
                    .done(daysAgo: 5, duration: 2),
                    .active(startDaysAgo: 3, endDaysFromNow: 4),
                    .pending,
                    .pending,
                    .pending,
                    .pending,
                ]),
                ("r4", [
                    .done(daysAgo: 15, duration: 3),
                    .done(daysAgo: 12, duration: 4),
                    .done(daysAgo: 8, duration: 6),
                    .done(daysAgo: 2, duration: 2),
                    .active(startDaysAgo: 0, endDaysFromNow: 3),
                    .pending,
                ]),
                ("r5", [
                    .active(startDaysAgo: 2, endDaysFromNow: 5),
                    .pending,
                    .pending,
                    .pending,
                    .pending,
                    .pending,
                ]),
            ]

            let stageNames = ["评审", "设计", "开发", "联调", "测试", "上线"]
            for entry in plans {
                try insertStages(db: db, reqId: entry.reqId, today: today, cal: cal,
                                 stageNames: stageNames, plan: entry.plan)
            }
        }
    }

    private enum StagePlan {
        case done(daysAgo: Int, duration: Int)
        case active(startDaysAgo: Int, endDaysFromNow: Int)
        case pending
    }

    private static func insertStages(
        db: GRDB.Database,
        reqId: String,
        today: Date,
        cal: Calendar,
        stageNames: [String],
        plan: [StagePlan]
    ) throws {
        for (i, stage) in plan.enumerated() {
            let id = "\(reqId)_s\(i)"
            let name = stageNames[i]
            switch stage {
            case .done(let daysAgo, let duration):
                let start = cal.date(byAdding: .day, value: -daysAgo, to: today)!
                let end = cal.date(byAdding: .day, value: duration - 1, to: start)!
                try db.execute(sql: """
                    INSERT INTO stage_instance
                        (id, requirement_id, name, sort_order, start_date, end_date, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, arguments: [id, reqId, name, i, start, end, "done"])
            case .active(let startDaysAgo, let endDaysFromNow):
                let start = cal.date(byAdding: .day, value: -startDaysAgo, to: today)!
                let end = cal.date(byAdding: .day, value: endDaysFromNow, to: today)!
                try db.execute(sql: """
                    INSERT INTO stage_instance
                        (id, requirement_id, name, sort_order, start_date, end_date, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, arguments: [id, reqId, name, i, start, end, "active"])
            case .pending:
                try db.execute(sql: """
                    INSERT INTO stage_instance
                        (id, requirement_id, name, sort_order, start_date, end_date, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, arguments: [id, reqId, name, i, nil, nil, "pending"])
            }
        }
    }
}
