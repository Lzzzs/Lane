import Foundation
import GRDB

struct RequirementRepository: Repository {
    typealias Entity = Requirement

    let pool: DatabaseWriter

    func all() throws -> [Requirement] {
        try pool.read { db in
            try Requirement.fetchAll(db,
                sql: "SELECT * FROM requirement ORDER BY sort_order ASC, created_at ASC")
        }
    }

    func find(id: String) throws -> Requirement? {
        try pool.read { db in
            try Requirement.fetchOne(db,
                sql: "SELECT * FROM requirement WHERE id = ?", arguments: [id])
        }
    }

    func upsert(_ entity: Requirement) throws {
        try pool.write { db in
            try db.execute(sql: """
                INSERT INTO requirement
                    (id, group_id, title, description, template_id, status,
                     sort_order, created_at, updated_at, deleted_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    group_id = excluded.group_id,
                    title = excluded.title,
                    description = excluded.description,
                    template_id = excluded.template_id,
                    status = excluded.status,
                    sort_order = excluded.sort_order,
                    updated_at = excluded.updated_at,
                    deleted_at = excluded.deleted_at
            """, arguments: [entity.id, entity.groupId, entity.title, entity.description,
                             entity.templateId, entity.status.rawValue, entity.sortOrder,
                             entity.createdAt, entity.updatedAt, entity.deletedAt])
        }
    }

    func delete(id: String) throws { try hardDelete(id: id) }

    func hardDelete(id: String) throws {
        try pool.write { db in
            try db.execute(sql: "DELETE FROM requirement WHERE id = ?", arguments: [id])
        }
    }

    func softDelete(id: String, at date: Date = Date()) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE requirement SET deleted_at = ? WHERE id = ?",
                           arguments: [date, id])
        }
    }

    func restore(id: String) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE requirement SET deleted_at = NULL WHERE id = ?",
                           arguments: [id])
        }
    }

    func allActive() throws -> [Requirement] {
        try pool.read { db in
            try Requirement.fetchAll(db, sql: """
                SELECT * FROM requirement
                WHERE status = 'active' AND deleted_at IS NULL
                ORDER BY sort_order ASC
            """)
        }
    }

    func activeByGroup(groupId: String) throws -> [Requirement] {
        try pool.read { db in
            try Requirement.fetchAll(db, sql: """
                SELECT * FROM requirement
                WHERE group_id = ? AND status = 'active' AND deleted_at IS NULL
                ORDER BY sort_order ASC
            """, arguments: [groupId])
        }
    }

    func deletedOlderThan(_ date: Date) throws -> [Requirement] {
        try pool.read { db in
            try Requirement.fetchAll(db, sql: """
                SELECT * FROM requirement WHERE deleted_at IS NOT NULL AND deleted_at < ?
            """, arguments: [date])
        }
    }
}
