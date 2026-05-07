import Foundation

public enum RequirementStatus: String, Codable, Equatable {
    case active
    case archived
}

public struct Requirement: Codable, Equatable, Identifiable {
    public var id: String
    public var groupId: String
    public var title: String
    public var description: String
    public var templateId: String?
    public var status: RequirementStatus
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
}
