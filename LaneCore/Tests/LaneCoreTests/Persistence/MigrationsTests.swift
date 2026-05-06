import Testing
import GRDB
@testable import LaneCore

@Suite struct MigrationsTests {

    @Test func runsCleanlyOnFreshDatabase() throws {
        let queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)

        try queue.read { db in
            let tables = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type='table' AND name NOT LIKE 'sqlite_%'
                  AND name NOT LIKE 'grdb_%'
                ORDER BY name
            """)
            #expect(tables == [
                "external_link",
                "group_",
                "requirement",
                "setting",
                "stage_instance",
                "stage_template",
                "stage_template_item",
                "today_pin",
                "todo"
            ])
        }
    }

    @Test func runIsIdempotent() throws {
        let queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        try Migrations.register().migrate(queue)
    }

    @Test func foreignKeysEnforcedWhenEnabled() throws {
        var config = Configuration()
        config.foreignKeysEnabled = true
        let queue = try DatabaseQueue(configuration: config)

        try Migrations.register().migrate(queue)

        do {
            try queue.write { db in
                try db.execute(sql: """
                    INSERT INTO requirement (id, group_id, title, description, status,
                        sort_order, created_at, updated_at)
                    VALUES ('r1','nonexistent','t','','active', 0, ?, ?)
                """, arguments: ["2026-01-01T00:00:00Z", "2026-01-01T00:00:00Z"])
            }
            #expect(Bool(false), "FK violation should have thrown")
        } catch {
            // expected
        }
    }
}
