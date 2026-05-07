import Foundation
import GRDB

struct SettingRepository {
    let pool: DatabaseWriter

    func get(key: String) throws -> String? {
        try pool.read { db in
            let row = try Row.fetchOne(db,
                sql: "SELECT value FROM setting WHERE key = ?", arguments: [key])
            return row?["value"]
        }
    }

    func set(key: String, value: String) throws {
        try pool.write { db in
            try db.execute(sql: """
                INSERT INTO setting (key, value) VALUES (?, ?)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value
            """, arguments: [key, value])
        }
    }

    func remove(key: String) throws {
        try pool.write { db in
            try db.execute(sql: "DELETE FROM setting WHERE key = ?", arguments: [key])
        }
    }
}
