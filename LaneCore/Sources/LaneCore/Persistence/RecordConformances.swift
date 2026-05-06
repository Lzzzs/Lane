import GRDB

extension Group: FetchableRecord, PersistableRecord {
    static let databaseTableName = "group_"
    static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
}

extension StageTemplate: FetchableRecord, PersistableRecord {
    static let databaseTableName = "stage_template"
    static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
}

extension StageTemplateItem: FetchableRecord, PersistableRecord {
    static let databaseTableName = "stage_template_item"
    static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
}

extension Requirement: FetchableRecord, PersistableRecord {
    static let databaseTableName = "requirement"
    static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
}

extension StageInstance: FetchableRecord, PersistableRecord {
    static let databaseTableName = "stage_instance"
    static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
}

extension Todo: FetchableRecord, PersistableRecord {
    static let databaseTableName = "todo"
    static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
}

extension ExternalLink: FetchableRecord, PersistableRecord {
    static let databaseTableName = "external_link"
    static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
}
