import Testing
import GRDB
import Foundation
@testable import LaneCore

@Suite struct TodayQueryTests {
    let queue: DatabaseQueue
    let query: TodayQuery

    init() throws {
        queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        query = TodayQuery(pool: queue)
        try queue.write { db in
            try db.execute(sql: """
                INSERT INTO group_ (id, name, color, icon, sort_order, created_at)
                VALUES ('g1', '需求', '#000', '●', 0, ?)
            """, arguments: [TestSupport.date(2024, 1, 1)])
        }
    }

    @Test func includesRequirementWithStageSpanningToday() throws {
        let today = TestSupport.date(2026, 5, 6)
        try insertReq(id: "r1")
        try insertStage(id: "s1", reqId: "r1",
                        start: TestSupport.date(2026, 5, 4),
                        end: TestSupport.date(2026, 5, 9),
                        status: "active")

        #expect(try query.inProgressRequirementIds(on: today) == ["r1"])
    }

    @Test func excludesRequirementWithStageInPastOnly() throws {
        let today = TestSupport.date(2026, 5, 6)
        try insertReq(id: "r1")
        try insertStage(id: "s1", reqId: "r1",
                        start: TestSupport.date(2026, 5, 1),
                        end: TestSupport.date(2026, 5, 4),
                        status: "done")

        #expect(try query.inProgressRequirementIds(on: today) == [])
    }

    @Test func excludesUnscheduledStages() throws {
        let today = TestSupport.date(2026, 5, 6)
        try insertReq(id: "r1")
        try insertStage(id: "s1", reqId: "r1", start: nil, end: nil, status: "pending")

        #expect(try query.inProgressRequirementIds(on: today) == [])
    }

    @Test func excludesArchivedAndDeleted() throws {
        let today = TestSupport.date(2026, 5, 6)
        try insertReq(id: "r1", status: "archived")
        try insertReq(id: "r2", deletedAt: today)
        try insertStage(id: "s1", reqId: "r1",
                        start: TestSupport.date(2026, 5, 4),
                        end: TestSupport.date(2026, 5, 9),
                        status: "active")
        try insertStage(id: "s2", reqId: "r2",
                        start: TestSupport.date(2026, 5, 4),
                        end: TestSupport.date(2026, 5, 9),
                        status: "active")

        #expect(try query.inProgressRequirementIds(on: today) == [])
    }

    @Test func dedupesRequirementWithMultipleActiveStages() throws {
        let today = TestSupport.date(2026, 5, 6)
        try insertReq(id: "r1")
        try insertStage(id: "s1", reqId: "r1",
                        start: TestSupport.date(2026, 5, 4),
                        end: TestSupport.date(2026, 5, 9),
                        status: "active")
        try insertStage(id: "s2", reqId: "r1",
                        start: TestSupport.date(2026, 5, 5),
                        end: TestSupport.date(2026, 5, 7),
                        status: "pending")

        #expect(try query.inProgressRequirementIds(on: today) == ["r1"])
    }

    private func insertReq(id: String, status: String = "active",
                           deletedAt: Date? = nil) throws {
        try queue.write { db in
            try db.execute(sql: """
                INSERT INTO requirement (id, group_id, title, description, status,
                    sort_order, created_at, updated_at, deleted_at)
                VALUES (?, 'g1', 'x', '', ?, 0, ?, ?, ?)
            """, arguments: [id, status,
                             TestSupport.date(2024, 1, 1),
                             TestSupport.date(2024, 1, 1),
                             deletedAt])
        }
    }

    private func insertStage(id: String, reqId: String,
                             start: Date?, end: Date?, status: String) throws {
        try queue.write { db in
            try db.execute(sql: """
                INSERT INTO stage_instance (id, requirement_id, name, sort_order,
                    start_date, end_date, status)
                VALUES (?, ?, '阶段', 0, ?, ?, ?)
            """, arguments: [id, reqId, start, end, status])
        }
    }
}
