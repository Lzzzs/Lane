import Foundation

public struct Group: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var color: String
    public var icon: String
    public var sortOrder: Int
    public var createdAt: Date
}
