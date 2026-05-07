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
    private let templateRepo: StageTemplateRepository

    public init(pool: DatabaseWriter) {
        self.pool = pool
        self.groupRepo = GroupRepository(pool: pool)
        self.reqRepo = RequirementRepository(pool: pool)
        self.stageRepo = StageInstanceRepository(pool: pool)
        self.templateRepo = StageTemplateRepository(pool: pool)
    }

    public func load() async throws {
        let allGroups = try groupRepo.all()
        let allReqs = try reqRepo.allActive()
        let allStages = try stageRepo.all()

        groups = allGroups
        requirementsByGroup = Dictionary(grouping: allReqs, by: \.groupId)
        stagesByRequirement = Dictionary(grouping: allStages, by: \.requirementId)
    }

    public func createRequirement(
        title: String,
        groupId: String,
        scheduleFirstStageToday: Bool
    ) async throws -> Requirement {
        let now = Date()
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: now)
        let id = "r_\(UUID().uuidString.prefix(8).lowercased())"

        let template = try templateRepo.defaultTemplate()
        let templateItems: [StageTemplateItem]
        if let template {
            templateItems = try templateRepo.itemsFor(templateId: template.id)
        } else {
            templateItems = []
        }

        let nextSortOrder = (requirementsByGroup[groupId] ?? []).count

        let req = Requirement(
            id: id,
            groupId: groupId,
            title: title,
            description: "",
            templateId: template?.id,
            status: .active,
            sortOrder: nextSortOrder,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil
        )
        try reqRepo.upsert(req)

        let stages: [StageInstance] = templateItems.enumerated().map { i, item in
            let scheduleFirst = scheduleFirstStageToday && i == 0
            return StageInstance(
                id: "\(id)_s\(i)",
                requirementId: id,
                name: item.name,
                sortOrder: i,
                startDate: scheduleFirst ? today : nil,
                endDate: scheduleFirst ? cal.date(byAdding: .day, value: 3, to: today) : nil,
                status: scheduleFirst ? .active : .pending
            )
        }
        for stage in stages {
            try stageRepo.upsert(stage)
        }

        try await load()
        return req
    }
}
