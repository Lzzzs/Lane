import Testing
import GRDB
import Foundation
@testable import LaneCore

@Suite struct RequirementRepositoryTests {
    let queue: DatabaseQueue
    let repo: RequirementRepository
    let groupRepo: GroupRepository

    init() throws {
        queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        repo = RequirementRepository(pool: queue)
        groupRepo = GroupRepository(pool: queue)
        try groupRepo.upsert(
            Group(id: "g1", name: "需求", color: "#7A8C7A", icon: "●",
                  sortOrder: 0, createdAt: TestSupport.date(2024, 1, 1)))
    }

    @Test func upsertAndFind() throws {
        let r = makeReq(id: "r1", title: "登录改造", sortOrder: 0)
        try repo.upsert(r)
        #expect(try repo.find(id: "r1")?.title == "登录改造")
    }

    @Test func allActiveExcludesArchivedAndDeleted() throws {
        try repo.upsert(makeReq(id: "r1", title: "active", sortOrder: 0))
        var archived = makeReq(id: "r2", title: "archived", sortOrder: 1)
        archived.status = .archived
        try repo.upsert(archived)
        var deleted = makeReq(id: "r3", title: "deleted", sortOrder: 2)
        deleted.deletedAt = TestSupport.date(2024, 6, 1)
        try repo.upsert(deleted)

        #expect(try repo.allActive().map(\.id) == ["r1"])
    }

    @Test func byGroupSortedByOrder() throws {
        try repo.upsert(makeReq(id: "r2", title: "b", sortOrder: 1))
        try repo.upsert(makeReq(id: "r1", title: "a", sortOrder: 0))
        let inGroup = try repo.activeByGroup(groupId: "g1")
        #expect(inGroup.map(\.id) == ["r1", "r2"])
    }

    @Test func softDeleteSetsDeletedAt() throws {
        try repo.upsert(makeReq(id: "r1", title: "x", sortOrder: 0))
        try repo.softDelete(id: "r1", at: TestSupport.date(2024, 6, 1))
        #expect(try repo.find(id: "r1")?.deletedAt != nil)
        #expect(try repo.allActive().count == 0)
    }

    @Test func restoreClearsDeletedAt() throws {
        try repo.upsert(makeReq(id: "r1", title: "x", sortOrder: 0))
        try repo.softDelete(id: "r1", at: TestSupport.date(2024, 6, 1))
        try repo.restore(id: "r1")
        #expect(try repo.find(id: "r1")?.deletedAt == nil)
        #expect(try repo.allActive().count == 1)
    }

    @Test func hardDeleteCascadesStages() throws {
        try repo.upsert(makeReq(id: "r1", title: "x", sortOrder: 0))
        try queue.write { db in
            try db.execute(sql: """
                INSERT INTO stage_instance (id, requirement_id, name, sort_order, status)
                VALUES ('s1', 'r1', '评审', 0, 'pending')
            """)
        }
        try repo.hardDelete(id: "r1")
        let count = try queue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stage_instance WHERE id = 's1'") ?? 0
        }
        #expect(count == 0)
    }

    private func makeReq(id: String, title: String, sortOrder: Int) -> Requirement {
        Requirement(
            id: id, groupId: "g1", title: title, description: "",
            templateId: nil, status: .active, sortOrder: sortOrder,
            createdAt: TestSupport.date(2024, 1, 1),
            updatedAt: TestSupport.date(2024, 1, 1),
            deletedAt: nil)
    }
}
