// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftHighlight",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SwiftHighlight",
            targets: ["SwiftHighlight"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftHighlight",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftHighlightTests",
            dependencies: ["SwiftHighlight"],
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
