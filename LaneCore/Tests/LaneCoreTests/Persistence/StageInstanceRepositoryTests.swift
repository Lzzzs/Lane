import Testing
import GRDB
import Foundation
@testable import LaneCore

@Suite struct StageInstanceRepositoryTests {
    let queue: DatabaseQueue
    let repo: StageInstanceRepository

    init() throws {
        queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        repo = StageInstanceRepository(pool: queue)

        try queue.write { db in
            try db.execute(sql: """
                INSERT INTO group_ (id, name, color, icon, sort_order, created_at)
                VALUES ('g1', 'x', '#000', '●', 0, ?)
            """, arguments: [TestSupport.date(2024, 1, 1)])
            try db.execute(sql: """
                INSERT INTO requirement (id, group_id, title, description, status,
                    sort_order, created_at, updated_at)
                VALUES ('r1', 'g1', 't', '', 'active', 0, ?, ?)
            """, arguments: [TestSupport.date(2024, 1, 1), TestSupport.date(2024, 1, 1)])
        }
    }

    @Test func upsertAndFetchForRequirement() throws {
        try repo.upsert(makeStage(id: "s1", reqId: "r1", name: "评审", sort: 0))
        try repo.upsert(makeStage(id: "s2", reqId: "r1", name: "设计", sort: 1))
        let result = try repo.byRequirement(requirementId: "r1")
        #expect(result.map(\.name) == ["评审", "设计"])
    }

    @Test func replaceForRequirement() throws {
        try repo.upsert(makeStage(id: "s1", reqId: "r1", name: "old", sort: 0))
        try repo.replaceForRequirement(requirementId: "r1", stages: [
            makeStage(id: "s2", reqId: "r1", name: "new", sort: 0)
        ])
        #expect(try repo.byRequirement(requirementId: "r1").map(\.name) == ["new"])
    }

    @Test func upsertWithDates() throws {
        let s = StageInstance(id: "s1", requirementId: "r1", name: "设计",
                              sortOrder: 0,
                              startDate: TestSupport.date(2026, 5, 1),
                              endDate: TestSupport.date(2026, 5, 5),
                              status: .active)
        try repo.upsert(s)
        let fetched = try repo.find(id: "s1")
        #expect(fetched?.status == .active)
        #expect(fetched?.startDate != nil)
        #expect(fetched?.endDate != nil)
    }

    private func makeStage(id: String, reqId: String, name: String, sort: Int) -> StageInstance {
        StageInstance(id: id, requirementId: reqId, name: name,
                      sortOrder: sort, startDate: nil, endDate: nil, status: .pending)
    }
}
