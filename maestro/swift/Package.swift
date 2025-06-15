// swift-tools-version: 5.7.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "maestro",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.64.0")
    ],
    targets: [
        // Executable containing the HTTP server and orchestration logic.
        .executableTarget(
            name: "maestro",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ],
            path: "Sources"
        ),
        // Unit tests exercising the orchestration logic.
        .testTarget(
            name: "maestroTests",
            dependencies: [
                .target(name: "maestro")
            ]),
    ]
)
