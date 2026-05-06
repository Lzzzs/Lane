// LaneCore/Tests/LaneCoreTests/Models/ModelsTests.swift
import Testing
import GRDB
@testable import LaneCore

@Suite struct ModelsTests {

    @Test func groupRoundTripsThroughJSON() throws {
        let g = Group(id: "g1", name: "需求", color: "#7A8C7A",
                      icon: "●", sortOrder: 0,
                      createdAt: TestSupport.date(2024, 1, 1))
        let data = try TestSupport.encode(g)
        let decoded = try TestSupport.decode(Group.self, from: data)
        #expect(decoded == g)
    }

    @Test func stageInstanceAcceptsNilDates() {
        let s = StageInstance(id: "s1", requirementId: "r1", name: "评审",
                              sortOrder: 0, startDate: nil, endDate: nil,
                              status: .pending)
        #expect(s.startDate == nil)
        #expect(s.endDate == nil)
        #expect(s.status == .pending)
    }

    @Test func requirementStatusRawValues() {
        #expect(RequirementStatus.active.rawValue == "active")
        #expect(RequirementStatus.archived.rawValue == "archived")
    }

    @Test func stageStatusRawValues() {
        #expect(StageStatus.pending.rawValue == "pending")
        #expect(StageStatus.active.rawValue == "active")
        #expect(StageStatus.done.rawValue == "done")
        #expect(StageStatus.skipped.rawValue == "skipped")
    }
}
