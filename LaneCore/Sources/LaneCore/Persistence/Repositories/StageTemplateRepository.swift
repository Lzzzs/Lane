import Foundation
import GRDB

struct StageTemplateRepository: Repository {
    typealias Entity = StageTemplate

    let pool: DatabaseWriter

    func all() throws -> [StageTemplate] {
        try pool.read { db in
            try StageTemplate.fetchAll(db, sql: "SELECT * FROM stage_template ORDER BY name ASC")
        }
    }

    func find(id: String) throws -> StageTemplate? {
        try pool.read { db in
            try StageTemplate.fetchOne(db, sql: "SELECT * FROM stage_template WHERE id = ?", arguments: [id])
        }
    }

    func upsert(_ entity: StageTemplate) throws {
        try pool.write { db in
            try db.execute(sql: """
                INSERT INTO stage_template (id, name, is_default, created_at)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    is_default = excluded.is_default
            """, arguments: [entity.id, entity.name, entity.isDefault, entity.createdAt])
        }
    }

    func delete(id: String) throws {
        try pool.write { db in
            do {
                try db.execute(sql: "DELETE FROM stage_template WHERE id = ?", arguments: [id])
            } catch let error as DatabaseError where error.resultCode == .SQLITE_CONSTRAINT {
                throw RepositoryError.foreignKeyViolation(
                    reason: "stage_template \(id) has referencing requirements")
            }
        }
    }

    func createWithItems(template: StageTemplate, items: [StageTemplateItem]) throws {
        try pool.write { db in
            try db.execute(sql: """
                INSERT INTO stage_template (id, name, is_default, created_at)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    is_default = excluded.is_default
            """, arguments: [template.id, template.name, template.isDefault, template.createdAt])
            for item in items {
                try db.execute(sql: """
                    INSERT INTO stage_template_item (id, template_id, name, sort_order)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET
                        name = excluded.name,
                        sort_order = excluded.sort_order
                """, arguments: [item.id, item.templateId, item.name, item.sortOrder])
            }
        }
    }

    func replaceItems(templateId: String, items: [StageTemplateItem]) throws {
        try pool.write { db in
            try db.execute(sql: "DELETE FROM stage_template_item WHERE template_id = ?", arguments: [templateId])
            for item in items {
                try db.execute(sql: """
                    INSERT INTO stage_template_item (id, template_id, name, sort_order)
                    VALUES (?, ?, ?, ?)
                """, arguments: [item.id, item.templateId, item.name, item.sortOrder])
            }
        }
    }

    func itemsFor(templateId: String) throws -> [StageTemplateItem] {
        try pool.read { db in
            try StageTemplateItem.fetchAll(db,
                sql: "SELECT * FROM stage_template_item WHERE template_id = ? ORDER BY sort_order ASC",
                arguments: [templateId])
        }
    }

    func setDefault(id: String) throws {
        try pool.write { db in
            try db.execute(sql: "UPDATE stage_template SET is_default = 0")
            try db.execute(sql: "UPDATE stage_template SET is_default = 1 WHERE id = ?", arguments: [id])
        }
    }

    func defaultTemplate() throws -> StageTemplate? {
        try pool.read { db in
            try StageTemplate.fetchOne(db,
                sql: "SELECT * FROM stage_template WHERE is_default = 1 LIMIT 1")
        }
    }
}
