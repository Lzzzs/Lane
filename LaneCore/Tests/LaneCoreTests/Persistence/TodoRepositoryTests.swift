import Testing
import GRDB
import Foundation
@testable import LaneCore

@Suite struct TodoRepositoryTests {
    let queue: DatabaseQueue
    let repo: TodoRepository

    init() throws {
        queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        repo = TodoRepository(pool: queue)
        try queue.write { db in
            try db.execute(sql: """
                INSERT INTO group_ (id,name,color,icon,sort_order,created_at)
                VALUES ('g1','x','#000','●',0,?)
            """, arguments: [TestSupport.date(2024, 1, 1)])
            try db.execute(sql: """
                INSERT INTO requirement (id,group_id,title,description,status,sort_order,created_at,updated_at)
                VALUES ('r1','g1','t','','active',0,?,?)
            """, arguments: [TestSupport.date(2024, 1, 1), TestSupport.date(2024, 1, 1)])
            try db.execute(sql: """
                INSERT INTO stage_instance (id,requirement_id,name,sort_order,status)
                VALUES ('s1','r1','x',0,'pending')
            """)
        }
    }

    @Test func upsertAndByStage() throws {
        let day = TestSupport.date(2026, 1, 1)
        let t1 = Todo(id: "t1", stageInstanceId: "s1", title: "first",
                      done: false, doneAt: nil, sortOrder: 0, createdAt: day)
        let t2 = Todo(id: "t2", stageInstanceId: "s1", title: "second",
                      done: false, doneAt: nil, sortOrder: 1, createdAt: day)
        try repo.upsert(t1)
        try repo.upsert(t2)
        let result = try repo.byStage(stageInstanceId: "s1")
        #expect(result.map(\.id) == ["t1", "t2"])
    }

    @Test func markDoneSetsDoneAt() throws {
        let day = TestSupport.date(2026, 1, 1)
        let t = Todo(id: "t1", stageInstanceId: "s1", title: "x",
                     done: false, doneAt: nil, sortOrder: 0, createdAt: day)
        try repo.upsert(t)
        let now = TestSupport.date(2026, 5, 6)
        try repo.markDone(id: "t1", at: now)
        let found = try repo.find(id: "t1")
        #expect(found?.done == true)
        #expect(found?.doneAt != nil)
    }

    @Test func completedOnDateReturnsTodayCompletions() throws {
        let day = TestSupport.date(2026, 5, 6)
        try repo.upsert(Todo(id: "t1", stageInstanceId: "s1", title: "x",
                             done: true, doneAt: day, sortOrder: 0,
                             createdAt: day))
        #expect(try repo.completedOn(date: day).count == 1)
    }
}
