import Testing
import GRDB
import Foundation
@testable import LaneCore

@Suite struct TodayPinRepositoryTests {
    let queue: DatabaseQueue
    let repo: TodayPinRepository

    init() throws {
        queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        repo = TodayPinRepository(pool: queue)
        try queue.write { db in
            try db.execute(sql: """
                INSERT INTO group_ (id,name,color,icon,sort_order,created_at)
                VALUES ('g1','x','#000','●',0,?)
            """, arguments: [TestSupport.date(2024, 1, 1)])
            try db.execute(sql: """
                INSERT INTO requirement (id,group_id,title,description,status,sort_order,created_at,updated_at)
                VALUES ('r1','g1','t','','active',0,?,?)
            """, arguments: [TestSupport.date(2024, 1, 1), TestSupport.date(2024, 1, 1)])
        }
    }

    @Test func pinAndUnpin() throws {
        let day = TestSupport.date(2026, 5, 6)
        try repo.pin(requirementId: "r1", date: day)
        #expect(try repo.pinnedRequirementIds(on: day) == ["r1"])
        try repo.unpin(requirementId: "r1", date: day)
        #expect(try repo.pinnedRequirementIds(on: day).isEmpty)
    }

    @Test func purgeOlderThan() throws {
        let old = TestSupport.date(2026, 5, 1)
        let recent = TestSupport.date(2026, 5, 6)
        try repo.pin(requirementId: "r1", date: old)
        try repo.pin(requirementId: "r1", date: recent)
        try repo.purgeOlderThan(date: TestSupport.date(2026, 5, 5))
        #expect(try repo.pinnedRequirementIds(on: old).isEmpty)
        #expect(try repo.pinnedRequirementIds(on: recent) == ["r1"])
    }
}
