import Foundation
import GRDB

struct TodayQuery {
    let pool: DatabaseReader

    func inProgressRequirementIds(on date: Date) throws -> [String] {
        try pool.read { db in
            try String.fetchAll(db, sql: """
                SELECT DISTINCT r.id
                FROM requirement r
                JOIN stage_instance s ON s.requirement_id = r.id
                WHERE r.status = 'active'
                  AND r.deleted_at IS NULL
                  AND s.start_date IS NOT NULL
                  AND s.end_date IS NOT NULL
                  AND s.start_date <= ?
                  AND s.end_date >= ?
                  AND s.status IN ('active','pending')
                ORDER BY r.sort_order ASC
            """, arguments: [date, date])
        }
    }
}
