import Foundation

struct Todo: Codable, Equatable, Identifiable {
    var id: String
    var stageInstanceId: String
    var title: String
    var done: Bool
    var doneAt: Date?
    var sortOrder: Int
    var createdAt: Date
}
