import Testing
import GRDB
@testable import LaneCore

@Suite struct GroupRepositoryTests {
    let queue: DatabaseQueue
    let repo: GroupRepository

    init() throws {
        queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        repo = GroupRepository(pool: queue)
    }

    @Test func upsertAndFind() throws {
        let g = makeGroup(id: "g1", name: "需求", sortOrder: 0)
        try repo.upsert(g)
        let found = try repo.find(id: "g1")
        #expect(found == g)
    }

    @Test func allReturnsBySortOrder() throws {
        try repo.upsert(makeGroup(id: "g2", name: "技建", sortOrder: 1))
        try repo.upsert(makeGroup(id: "g1", name: "需求", sortOrder: 0))
        let all = try repo.all()
        #expect(all.map(\.id) == ["g1", "g2"])
    }

    @Test func upsertOverwritesExisting() throws {
        try repo.upsert(makeGroup(id: "g1", name: "old", sortOrder: 0))
        try repo.upsert(makeGroup(id: "g1", name: "new", sortOrder: 0))
        let found = try repo.find(id: "g1")
        #expect(found?.name == "new")
    }

    @Test func deleteRemoves() throws {
        try repo.upsert(makeGroup(id: "g1", name: "x", sortOrder: 0))
        try repo.delete(id: "g1")
        #expect(try repo.find(id: "g1") == nil)
    }

    @Test func deleteWithReferencedRequirementThrows() throws {
        try repo.upsert(makeGroup(id: "g1", name: "x", sortOrder: 0))
        let now = TestSupport.date(2024, 1, 1)
        try queue.write { db in
            try db.execute(sql: """
                INSERT INTO requirement (id, group_id, title, description, status,
                    sort_order, created_at, updated_at)
                VALUES ('r1','g1','t','','active', 0, ?, ?)
            """, arguments: [now, now])
        }
        #expect(throws: (any Error).self) { try repo.delete(id: "g1") }
    }

    private func makeGroup(id: String, name: String, sortOrder: Int) -> Group {
        Group(id: id, name: name, color: "#7A8C7A", icon: "●",
              sortOrder: sortOrder, createdAt: TestSupport.date(2024, 1, 1))
    }
}
