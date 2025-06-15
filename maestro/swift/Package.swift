// swift-tools-version:5.7
import PackageDescription
let package = Package(
    name: "HassMaestro",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.59.0")
    ],
    targets: [
        .executableTarget(name: "HassMaestro", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOHTTP1", package: "swift-nio")
        ])
    ]
)
