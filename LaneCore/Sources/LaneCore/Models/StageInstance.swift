import Foundation

enum StageStatus: String, Codable, Equatable {
    case pending
    case active
    case done
    case skipped
}

struct StageInstance: Codable, Equatable {
    var id: String
    var requirementId: String
    var name: String
    var sortOrder: Int
    var startDate: Date?
    var endDate: Date?
    var status: StageStatus
}
