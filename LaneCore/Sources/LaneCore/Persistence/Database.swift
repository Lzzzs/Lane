import GRDB
import Foundation

enum Database {
    static func makeInMemoryPool() throws -> DatabaseQueue {
        try DatabaseQueue()
    }

    static func makeFilePool(at url: URL) throws -> DatabasePool {
        var config = Configuration()
        config.foreignKeysEnabled = true
        return try DatabasePool(path: url.path, configuration: config)
    }

    static func defaultStoreURL() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let laneDir = appSupport.appendingPathComponent("Lane", isDirectory: true)
        try FileManager.default.createDirectory(at: laneDir, withIntermediateDirectories: true)
        return laneDir.appendingPathComponent("store.db")
    }
}
