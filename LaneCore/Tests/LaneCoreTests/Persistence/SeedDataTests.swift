import Testing
import GRDB
@testable import LaneCore

@Suite struct SeedDataTests {
    @Test func seedIfEmptyPopulatesAndIsIdempotent() throws {
        let queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)

        try SeedData.seedIfEmpty(pool: queue)

        let firstCounts = try queue.read { db in
            (
                groups: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM group_") ?? 0,
                templates: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stage_template") ?? 0,
                templateItems: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stage_template_item") ?? 0,
                requirements: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM requirement") ?? 0,
                stages: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stage_instance") ?? 0
            )
        }
        #expect(firstCounts.groups == 2)
        #expect(firstCounts.templates == 1)
        #expect(firstCounts.templateItems == 6)
        #expect(firstCounts.requirements == 5)
        #expect(firstCounts.stages == 30)  // 5 requirements × 6 stages each

        // Idempotent: second seed must not double up
        try SeedData.seedIfEmpty(pool: queue)
        let secondCount = try queue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM requirement") ?? 0
        }
        #expect(secondCount == 5)
    }

    @Test func defaultTemplateIsMarked() throws {
        let queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        try SeedData.seedIfEmpty(pool: queue)

        let defaultId = try queue.read { db in
            try String.fetchOne(db, sql: "SELECT id FROM stage_template WHERE is_default = 1")
        }
        #expect(defaultId == "tmpl_std")
    }
}
