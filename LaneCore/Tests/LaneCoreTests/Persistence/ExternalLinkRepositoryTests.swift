import Testing
import GRDB
import Foundation
@testable import LaneCore

@Suite struct ExternalLinkRepositoryTests {
    let queue: DatabaseQueue
    let repo: ExternalLinkRepository

    init() throws {
        queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        repo = ExternalLinkRepository(pool: queue)
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

    @Test func upsertAndByRequirement() throws {
        let l1 = ExternalLink(id: "l1", requirementId: "r1",
                              label: "Docs", url: "https://example.com", sortOrder: 0)
        let l2 = ExternalLink(id: "l2", requirementId: "r1",
                              label: "Repo", url: "https://github.com", sortOrder: 1)
        try repo.upsert(l1)
        try repo.upsert(l2)
        let result = try repo.byRequirement(requirementId: "r1")
        #expect(result.map(\.id) == ["l1", "l2"])
    }
}
