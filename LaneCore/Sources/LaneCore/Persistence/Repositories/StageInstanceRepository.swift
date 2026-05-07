import Foundation
import GRDB

struct StageInstanceRepository: Repository {
    typealias Entity = StageInstance

    let pool: DatabaseWriter

    func all() throws -> [StageInstance] {
        try pool.read { db in
            try StageInstance.fetchAll(db,
                sql: "SELECT * FROM stage_instance ORDER BY requirement_id, sort_order")
        }
    }

    func find(id: String) throws -> StageInstance? {
        try pool.read { db in
            try StageInstance.fetchOne(db,
                sql: "SELECT * FROM stage_instance WHERE id = ?", arguments: [id])
        }
    }

    func upsert(_ entity: StageInstance) throws {
        try pool.write { db in
            try Self.writeStage(entity, in: db)
        }
    }

    func delete(id: String) throws {
        try pool.write { db in
            try db.execute(sql: "DELETE FROM stage_instance WHERE id = ?", arguments: [id])
        }
    }

    func byRequirement(requirementId: String) throws -> [StageInstance] {
        try pool.read { db in
            try StageInstance.fetchAll(db,
                sql: "SELECT * FROM stage_instance WHERE requirement_id = ? ORDER BY sort_order",
                arguments: [requirementId])
        }
    }

    func replaceForRequirement(requirementId: String, stages: [StageInstance]) throws {
        try pool.write { db in
            try db.execute(sql: "DELETE FROM stage_instance WHERE requirement_id = ?",
                           arguments: [requirementId])
            for stage in stages {
                try Self.writeStage(stage, in: db)
            }
        }
    }

    private static func writeStage(_ stage: StageInstance, in db: GRDB.Database) throws {
        try db.execute(sql: """
            INSERT INTO stage_instance (id, requirement_id, name, sort_order,
                start_date, end_date, status)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                requirement_id = excluded.requirement_id,
                name = excluded.name,
                sort_order = excluded.sort_order,
                start_date = excluded.start_date,
                end_date = excluded.end_date,
                status = excluded.status
        """, arguments: [
            stage.id,
            stage.requirementId,
            stage.name,
            stage.sortOrder,
            stage.startDate,
            stage.endDate,
            stage.status.rawValue
        ])
    }
}
