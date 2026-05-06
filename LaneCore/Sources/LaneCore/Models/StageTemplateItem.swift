import Foundation

struct StageTemplateItem: Codable, Equatable, Identifiable {
    var id: String
    var templateId: String
    var name: String
    var sortOrder: Int
}
