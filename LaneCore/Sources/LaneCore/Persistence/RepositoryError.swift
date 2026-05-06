import Foundation

enum RepositoryError: LocalizedError, Equatable {
    case notFound(entity: String, id: String)
    case foreignKeyViolation(reason: String)
    case constraint(reason: String)
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let entity, let id):
            return "\(entity) with id \(id) not found"
        case .foreignKeyViolation(let reason):
            return "Foreign key violation: \(reason)"
        case .constraint(let reason):
            return "Constraint violation: \(reason)"
        case .underlying(let msg):
            return msg
        }
    }
}
