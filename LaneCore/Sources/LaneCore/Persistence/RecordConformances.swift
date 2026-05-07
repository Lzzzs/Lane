import GRDB

extension Group: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "group_"
    public static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    public static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
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
    public static let databaseTableName = "requirement"
    public static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    public static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
}

extension StageInstance: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "stage_instance"
    public static let databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy = .convertFromSnakeCase
    public static let databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy = .convertToSnakeCase
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
