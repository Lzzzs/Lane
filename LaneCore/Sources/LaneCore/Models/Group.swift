import Foundation

struct Group: Codable, Equatable {
    var id: String
    var name: String
    var color: String
    var icon: String
    var sortOrder: Int
    var createdAt: Date
}
