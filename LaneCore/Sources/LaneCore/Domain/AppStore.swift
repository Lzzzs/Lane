import Foundation
import GRDB
import Observation

@Observable
@MainActor
final class AppStore {
    private(set) var groups: [Group] = []
    private(set) var requirementsByGroup: [String: [Requirement]] = [:]
    private(set) var stagesByRequirement: [String: [StageInstance]] = [:]

    private let pool: DatabaseWriter
    private let groupRepo: GroupRepository
    private let reqRepo: RequirementRepository
    private let stageRepo: StageInstanceRepository

    init(pool: DatabaseWriter) {
        self.pool = pool
        self.groupRepo = GroupRepository(pool: pool)
        self.reqRepo = RequirementRepository(pool: pool)
        self.stageRepo = StageInstanceRepository(pool: pool)
    }

    func load() async throws {
        let allGroups = try groupRepo.all()
        let allReqs = try reqRepo.allActive()
        let allStages = try stageRepo.all()

        groups = allGroups
        requirementsByGroup = Dictionary(grouping: allReqs, by: \.groupId)
        stagesByRequirement = Dictionary(grouping: allStages, by: \.requirementId)
    }
}
