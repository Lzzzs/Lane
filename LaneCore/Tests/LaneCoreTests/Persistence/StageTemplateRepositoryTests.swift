import Testing
import GRDB
import Foundation
@testable import LaneCore

@Suite struct StageTemplateRepositoryTests {
    let queue: DatabaseQueue
    let repo: StageTemplateRepository

    init() throws {
        queue = try Database.makeInMemoryQueue()
        try Migrations.register().migrate(queue)
        repo = StageTemplateRepository(pool: queue)
    }

    @Test func createTemplateWithItems() throws {
        let t = StageTemplate(id: "t1", name: "Standard", isDefault: true,
                              createdAt: TestSupport.date(2024, 1, 1))
        let items = ["评审", "设计", "开发"].enumerated().map { i, name in
            StageTemplateItem(id: "i\(i)", templateId: "t1", name: name, sortOrder: i)
        }
        try repo.createWithItems(template: t, items: items)
        let fetched = try repo.itemsFor(templateId: "t1")
        #expect(fetched.map(\.name) == ["评审", "设计", "开发"])
    }

    @Test func replaceItemsRemovesAndInserts() throws {
        let t = StageTemplate(id: "t1", name: "x", isDefault: false,
                              createdAt: TestSupport.date(2024, 1, 1))
        try repo.createWithItems(template: t, items: [
            StageTemplateItem(id: "a", templateId: "t1", name: "a", sortOrder: 0)
        ])
        try repo.replaceItems(templateId: "t1", items: [
            StageTemplateItem(id: "b", templateId: "t1", name: "b", sortOrder: 0),
            StageTemplateItem(id: "c", templateId: "t1", name: "c", sortOrder: 1)
        ])
        #expect(try repo.itemsFor(templateId: "t1").map(\.name) == ["b", "c"])
    }

    @Test func setDefaultClearsOtherDefaults() throws {
        try repo.createWithItems(
            template: StageTemplate(id: "t1", name: "a", isDefault: true,
                                    createdAt: TestSupport.date(2024, 1, 1)),
            items: [])
        try repo.createWithItems(
            template: StageTemplate(id: "t2", name: "b", isDefault: false,
                                    createdAt: TestSupport.date(2024, 1, 1)),
            items: [])
        try repo.setDefault(id: "t2")
        #expect(try repo.find(id: "t1")?.isDefault == false)
        #expect(try repo.find(id: "t2")?.isDefault == true)
    }
}
