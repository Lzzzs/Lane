import Foundation

struct StageTemplate: Codable, Equatable {
    var id: String
    var name: String
    var isDefault: Bool
    var createdAt: Date
}
