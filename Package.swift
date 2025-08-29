// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VideoEditingKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "VideoEditingKit",
            targets: ["VideoEditingKit"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .target(
            name: "VideoEditingKit",
            dependencies: [],
            path: "Sources/VideoEditingKit"
        ),
        .testTarget(
            name: "VideoEditingKitTests",
            dependencies: ["VideoEditingKit"],
            path: "Tests/VideoEditingKitTests"
        ),
    ]
)