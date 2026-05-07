import Foundation
import GRDB

struct ExternalLinkRepository: Repository {
    typealias Entity = ExternalLink

    let pool: DatabaseWriter

    func all() throws -> [ExternalLink] {
        try pool.read { db in
            try ExternalLink.fetchAll(db,
                sql: "SELECT * FROM external_link ORDER BY requirement_id, sort_order")
        }
    }

    func find(id: String) throws -> ExternalLink? {
        try pool.read { db in
            try ExternalLink.fetchOne(db,
                sql: "SELECT * FROM external_link WHERE id = ?", arguments: [id])
        }
    }

    func upsert(_ entity: ExternalLink) throws {
        try pool.write { db in
            try db.execute(sql: """
                INSERT INTO external_link (id, requirement_id, label, url, sort_order)
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    label = excluded.label,
                    url = excluded.url,
                    sort_order = excluded.sort_order
            """, arguments: [entity.id, entity.requirementId, entity.label,
                             entity.url, entity.sortOrder])
        }
    }

    func delete(id: String) throws {
        try pool.write { db in
            try db.execute(sql: "DELETE FROM external_link WHERE id = ?", arguments: [id])
        }
    }

    func byRequirement(requirementId: String) throws -> [ExternalLink] {
        try pool.read { db in
            try ExternalLink.fetchAll(db,
                sql: "SELECT * FROM external_link WHERE requirement_id = ? ORDER BY sort_order",
                arguments: [requirementId])
        }
    }
}
