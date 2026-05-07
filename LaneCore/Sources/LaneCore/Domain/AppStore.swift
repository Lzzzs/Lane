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

    // MARK: - Requirements

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

    public func updateRequirement(_ req: Requirement) async throws {
        var updated = req
        updated.updatedAt = Date()
        try reqRepo.upsert(updated)
        try await load()
    }

    public func archiveRequirement(id: String) async throws {
        guard let req = try reqRepo.find(id: id) else { return }
        var updated = req
        updated.status = .archived
        updated.updatedAt = Date()
        try reqRepo.upsert(updated)
        try await load()
    }

    public func deleteRequirement(id: String) async throws {
        try reqRepo.softDelete(id: id, at: Date())
        try await load()
    }

    // MARK: - Stages

    public func updateStage(_ stage: StageInstance) async throws {
        try stageRepo.upsert(stage)
        try await load()
    }

    public func updateStageDates(
        id: String,
        start: Date?,
        end: Date?
    ) async throws {
        guard let stage = try stageRepo.find(id: id) else { return }
        var updated = stage
        updated.startDate = start
        updated.endDate = end
        // Auto-update status: scheduled = pending unless already done/skipped; if today
        // falls in the new window, mark active.
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        if let s = start, let e = end,
           updated.status != .done, updated.status != .skipped {
            let sd = cal.startOfDay(for: s)
            let ed = cal.startOfDay(for: e)
            updated.status = (today >= sd && today <= ed) ? .active : .pending
        }
        try stageRepo.upsert(updated)
        try await load()
    }

    public func updateStageStatus(id: String, status: StageStatus) async throws {
        guard let stage = try stageRepo.find(id: id) else { return }
        var updated = stage
        updated.status = status
        try stageRepo.upsert(updated)
        try await load()
    }

    // MARK: - Groups

    public func createGroup(name: String, color: String, icon: String) async throws -> Group {
        let nextSortOrder = groups.count
        let id = "g_\(UUID().uuidString.prefix(8).lowercased())"
        let group = Group(
            id: id,
            name: name,
            color: color,
            icon: icon,
            sortOrder: nextSortOrder,
            createdAt: Date()
        )
        try groupRepo.upsert(group)
        try await load()
        return group
    }

    public func updateGroup(_ group: Group) async throws {
        try groupRepo.upsert(group)
        try await load()
    }

    public func deleteGroup(id: String) async throws {
        try groupRepo.delete(id: id)
        try await load()
    }
}
