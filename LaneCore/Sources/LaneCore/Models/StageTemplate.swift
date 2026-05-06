import Foundation

struct StageTemplate: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var isDefault: Bool
    var createdAt: Date
}
