import Foundation
import GRDB

struct TodoRepository: Repository {
    typealias Entity = Todo

    let pool: DatabaseWriter

    func all() throws -> [Todo] {
        try pool.read { db in
            try Todo.fetchAll(db,
                sql: "SELECT * FROM todo ORDER BY stage_instance_id, sort_order")
        }
    }

    func find(id: String) throws -> Todo? {
        try pool.read { db in
            try Todo.fetchOne(db,
                sql: "SELECT * FROM todo WHERE id = ?", arguments: [id])
        }
    }

    func upsert(_ entity: Todo) throws {
        try pool.write { db in
            try db.execute(sql: """
                INSERT INTO todo (id, stage_instance_id, title, done, done_at, sort_order, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    title = excluded.title,
                    done = excluded.done,
                    done_at = excluded.done_at,
                    sort_order = excluded.sort_order
            """, arguments: [entity.id, entity.stageInstanceId, entity.title,
                             entity.done, entity.doneAt, entity.sortOrder, entity.createdAt])
        }
    }

    func delete(id: String) throws {
        try pool.write { db in
            try db.execute(sql: "DELETE FROM todo WHERE id = ?", arguments: [id])
        }
    }

    func byStage(stageInstanceId: String) throws -> [Todo] {
        try pool.read { db in
            try Todo.fetchAll(db,
                sql: "SELECT * FROM todo WHERE stage_instance_id = ? ORDER BY sort_order",
                arguments: [stageInstanceId])
        }
    }

    func markDone(id: String, at date: Date = Date()) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE todo SET done = 1, done_at = ? WHERE id = ?",
                           arguments: [date, id])
        }
    }

    func markUndone(id: String) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE todo SET done = 0, done_at = NULL WHERE id = ?",
                           arguments: [id])
        }
    }

    func completedOn(date: Date) throws -> [Todo] {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return try pool.read { db in
            try Todo.fetchAll(db, sql: """
                SELECT * FROM todo
                WHERE done = 1 AND done_at >= ? AND done_at < ?
                ORDER BY done_at DESC
            """, arguments: [start, end])
        }
    }
}
