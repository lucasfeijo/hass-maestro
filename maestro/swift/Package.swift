// swift-tools-version: 5.7.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "maestro",
    targets: [
        // Executable containing the HTTP server and orchestration logic.
        .executableTarget(
            name: "maestro"
        ),
        // Unit tests exercising the orchestration logic.
        .testTarget(
            name: "maestroTests",
            dependencies: [
                .target(name: "maestro")
            ]),
    ]
)
