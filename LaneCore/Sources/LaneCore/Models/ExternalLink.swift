import Foundation

struct ExternalLink: Codable, Equatable, Identifiable {
    var id: String
    var requirementId: String
    var label: String
    var url: String
    var sortOrder: Int
}
