// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "EasyTree",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "EasyTreeKit",
            targets: ["EasyTreeKit"]
        ),
        .executable(
            name: "easy-tree",
            targets: ["EasyTreeCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "EasyTreeKit"
        ),
        .executableTarget(
            name: "EasyTreeCLI",
            dependencies: [
                "EasyTreeKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "EasyTreeKitTests",
            dependencies: ["EasyTreeKit"]
        ),
        .testTarget(
            name: "EasyTreeCLITests",
            dependencies: [
                "EasyTreeCLI",
                "EasyTreeKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
