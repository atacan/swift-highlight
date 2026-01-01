// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HighlightDemo",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "HighlightDemo",
            dependencies: [
                .product(name: "SwiftHighlight", package: "swift-highlight"),
            ]
        ),
    ]
)
