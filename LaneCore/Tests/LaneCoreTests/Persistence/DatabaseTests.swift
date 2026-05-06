// LaneCore/Tests/LaneCoreTests/Persistence/DatabaseTests.swift
import Testing
import GRDB
@testable import LaneCore

@Suite struct DatabaseTests {
    @Test func inMemoryPoolOpens() throws {
        let pool = try Database.makeInMemoryPool()
        let result = try pool.read { db in
            try Int.fetchOne(db, sql: "SELECT 1")
        }
        #expect(result == 1)
    }
}
