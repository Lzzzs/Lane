import Foundation

enum RequirementStatus: String, Codable, Equatable {
    case active
    case archived
}

struct Requirement: Codable, Equatable {
    var id: String
    var groupId: String
    var title: String
    var description: String
    var templateId: String?
    var status: RequirementStatus
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}
