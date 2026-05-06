import Foundation
import GRDB

protocol Repository {
    associatedtype Entity: Identifiable, Codable where Entity.ID == String

    func all() throws -> [Entity]
    func find(id: String) throws -> Entity?
    func upsert(_ entity: Entity) throws
    func delete(id: String) throws
}
