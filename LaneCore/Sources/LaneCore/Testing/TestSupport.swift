import Foundation

/// Helpers exposed for tests so test files can avoid `import Foundation`.
/// CLT ships a broken `_Testing_Foundation` cross-import overlay (binary only,
/// no swiftmodule), so tests that import both `Testing` and `Foundation` fail
/// to build. Construct Foundation values in source via these helpers and let
/// tests use them by type inference.
enum TestSupport {
    static func date(_ year: Int, _ month: Int, _ day: Int,
                     hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        c.hour = hour; c.minute = minute; c.second = second
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    static func iso(_ year: Int, _ month: Int, _ day: Int) -> String {
        String(format: "%04d-%02d-%02d 00:00:00", year, month, day)
    }

    static func tempStoreURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("lane-test-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("store.db")
    }

    static func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}
