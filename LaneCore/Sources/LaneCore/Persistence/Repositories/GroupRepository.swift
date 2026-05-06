import Foundation
import GRDB

struct GroupRepository: Repository {
    typealias Entity = Group

    let pool: DatabaseWriter

    func all() throws -> [Group] {
        try pool.read { db in
            try Group.fetchAll(db, sql: "SELECT * FROM group_ ORDER BY sort_order ASC, name ASC")
        }
    }

    func find(id: String) throws -> Group? {
        try pool.read { db in
            try Group.fetchOne(db, sql: "SELECT * FROM group_ WHERE id = ?", arguments: [id])
        }
    }

    func upsert(_ entity: Group) throws {
        try pool.write { db in
            try db.execute(sql: """
                INSERT INTO group_ (id, name, color, icon, sort_order, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    color = excluded.color,
                    icon = excluded.icon,
                    sort_order = excluded.sort_order
            """, arguments: [entity.id, entity.name, entity.color, entity.icon,
                             entity.sortOrder, entity.createdAt])
        }
    }

    func delete(id: String) throws {
        try pool.write { db in
            do {
                try db.execute(sql: "DELETE FROM group_ WHERE id = ?", arguments: [id])
            } catch let error as DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
                throw RepositoryError.foreignKeyViolation(
                    reason: "group \(id) has referencing requirements")
            }
        }
    }
}

