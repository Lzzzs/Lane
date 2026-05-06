# LaneCore — agent guide

This is the data + domain core of Lane, packaged as a standalone Swift Package so it can be developed and tested with only the macOS Command Line Tools (full Xcode is not yet installed). When Xcode lands, the Lane app target will depend on this package.

## How to run tests

`make test` from this directory. Do not run `swift test` directly — it will fail with "no such module 'Testing'". The Makefile passes the framework search path and rpath needed to locate the Testing.framework that ships with the Command Line Tools.

`make build` to build only. `make clean` to wipe `.build/`.

## Test framework

We use **swift-testing** (Swift 6's `import Testing` + `@Test`), not XCTest. XCTest is unavailable without full Xcode. swift-testing patterns:

```swift
import Testing
@testable import LaneCore

@Test func someBehavior() async throws {
    let result = try doSomething()
    #expect(result == expected)
}

@Suite struct GroupedTests {
    @Test func a() { #expect(1 == 1) }
    @Test func b() { #expect(2 == 2) }
}
```

For tests that need a fresh fixture per test, write a `@Suite struct` and use stored properties initialized in `init()` — each `@Test` gets a new instance.

## Source layout

```
Sources/LaneCore/
  Models/        pure Codable structs, no GRDB
  Persistence/   GRDB + SQLite + repositories + migrations
  Domain/        observable stores (AppStore, TimelineStore)
```

All code is under one target named `LaneCore`. Subdirectories are organisational only.

## Conventions

- Plain SQL with parameterised queries (no GRDB query builders), to keep the surface obvious and portable
- All tests use in-memory `DatabaseQueue` via `Database.makeInMemoryQueue()` — never touch disk
- Date columns store `Date` values; the time component is ignored — treat `start_date`/`end_date` as local dates
- **Test files MUST NOT `import Foundation`.** CLT ships a broken `_Testing_Foundation` cross-import overlay (binary only, no swiftmodule), so any test file that imports both `Testing` and `Foundation` fails to build. Construct Foundation values via the `TestSupport` helpers in `Sources/LaneCore/Testing/TestSupport.swift`:
  - `TestSupport.date(2026, 5, 6)` for a `Date` (UTC)
  - `TestSupport.iso(2026, 5, 6)` for an ISO date string passable to GRDB as a SQL argument
  - `TestSupport.tempStoreURL()` for a unique temp `URL` (file pool tests)
  Tests pick up the Foundation types by inference; avoid any direct mention of `Date`, `URL`, or other Foundation types in test source.
