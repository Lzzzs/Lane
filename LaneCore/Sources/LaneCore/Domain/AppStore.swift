import Foundation
import GRDB
import Observation

@Observable
@MainActor
public final class AppStore {
    public private(set) var groups: [Group] = []
    public private(set) var requirementsByGroup: [String: [Requirement]] = [:]
    public private(set) var stagesByRequirement: [String: [StageInstance]] = [:]

    private let pool: DatabaseWriter
    private let groupRepo: GroupRepository
    private let reqRepo: RequirementRepository
    private let stageRepo: StageInstanceRepository

    public init(pool: DatabaseWriter) {
        self.pool = pool
        self.groupRepo = GroupRepository(pool: pool)
        self.reqRepo = RequirementRepository(pool: pool)
        self.stageRepo = StageInstanceRepository(pool: pool)
    }

    public func load() async throws {
        let allGroups = try groupRepo.all()
        let allReqs = try reqRepo.allActive()
        let allStages = try stageRepo.all()

        groups = allGroups
        requirementsByGroup = Dictionary(grouping: allReqs, by: \.groupId)
        stagesByRequirement = Dictionary(grouping: allStages, by: \.requirementId)
    }
}
