// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LaneCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LaneCore", targets: ["LaneCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "LaneCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        .testTarget(
            name: "LaneCoreTests",
            dependencies: ["LaneCore"]
        )
    ]
)
