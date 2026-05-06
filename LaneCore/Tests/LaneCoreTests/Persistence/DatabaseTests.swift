import Testing
import GRDB
@testable import LaneCore

@Suite struct DatabaseTests {
    @Test func inMemoryQueueOpens() throws {
        let queue = try Database.makeInMemoryQueue()
        let result = try queue.read { db in
            try Int.fetchOne(db, sql: "SELECT 1")
        }
        #expect(result == 1)
    }
}
