import Foundation

public enum StageStatus: String, Codable, Equatable {
    case pending
    case active
    case done
    case skipped
}

public struct StageInstance: Codable, Equatable, Identifiable {
    public var id: String
    public var requirementId: String
    public var name: String
    public var sortOrder: Int
    public var startDate: Date?
    public var endDate: Date?
    public var status: StageStatus
}
