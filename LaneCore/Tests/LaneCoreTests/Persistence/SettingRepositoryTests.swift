import Testing
import GRDB
import Foundation
@testable import LaneCore

@Suite struct SettingRepositoryTests {
    let queue: DatabaseQueue
    let repo: SettingRepository

    init() throws {
        queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        repo = SettingRepository(pool: queue)
    }

    @Test func setAndGet() throws {
        try repo.set(key: "theme", value: "dark")
        #expect(try repo.get(key: "theme") == "dark")
    }

    @Test func overwrite() throws {
        try repo.set(key: "theme", value: "light")
        try repo.set(key: "theme", value: "dark")
        #expect(try repo.get(key: "theme") == "dark")
    }

    @Test func getMissingReturnsNil() throws {
        #expect(try repo.get(key: "nonexistent") == nil)
    }
}
