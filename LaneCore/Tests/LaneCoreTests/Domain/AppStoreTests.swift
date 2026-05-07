import Testing
import GRDB
@testable import LaneCore

@Suite @MainActor
struct AppStoreTests {

    @Test func loadHydratesGroupsAndRequirements() async throws {
        let queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        try SeedData.seedIfEmpty(pool: queue)

        let store = AppStore(pool: queue)
        try await store.load()

        #expect(store.groups.map(\.id) == ["g_req", "g_tech"])
        #expect(store.requirementsByGroup["g_req"]?.count == 3)
        #expect(store.requirementsByGroup["g_tech"]?.count == 2)
    }

    @Test func stagesByRequirementContainsAllStages() async throws {
        let queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        try SeedData.seedIfEmpty(pool: queue)

        let store = AppStore(pool: queue)
        try await store.load()

        #expect(store.stagesByRequirement["r1"]?.count == 6)
    }
}
