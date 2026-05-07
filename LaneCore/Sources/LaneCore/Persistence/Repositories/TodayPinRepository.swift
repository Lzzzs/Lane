import Foundation
import GRDB

struct TodayPinRepository {
    let pool: DatabaseWriter

    func pin(requirementId: String, date: Date) throws {
        try pool.write { db in
            try db.execute(sql: """
                INSERT OR IGNORE INTO today_pin (requirement_id, pinned_date) VALUES (?, ?)
            """, arguments: [requirementId, date])
        }
    }

    func unpin(requirementId: String, date: Date) throws {
        try pool.write { db in
            try db.execute(sql: """
                DELETE FROM today_pin WHERE requirement_id = ? AND pinned_date = ?
            """, arguments: [requirementId, date])
        }
    }

    func pinnedRequirementIds(on date: Date) throws -> [String] {
        try pool.read { db in
            let rows = try Row.fetchAll(db,
                sql: "SELECT requirement_id FROM today_pin WHERE pinned_date = ?",
                arguments: [date])
            return rows.map { $0["requirement_id"] }
        }
    }

    func purgeOlderThan(date: Date) throws {
        try pool.write { db in
            try db.execute(sql: "DELETE FROM today_pin WHERE pinned_date < ?",
                           arguments: [date])
        }
    }
}
