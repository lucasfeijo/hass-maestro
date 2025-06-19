// swift-tools-version: 5.7.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "maestro",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        // Executable containing the HTTP server and orchestration logic.
        .executableTarget(
            name: "maestro",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources"
        ),
        // Unit tests exercising the orchestration logic.
        .testTarget(
            name: "maestroTests",
            dependencies: [
                .target(name: "maestro")
            ],
            swiftSettings: [
                .define("TESTING")
            ]
        ),
    ]
)
