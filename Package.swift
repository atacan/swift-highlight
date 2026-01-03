// swift-tools-version: 6.0

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
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "ProfileRunner",
            dependencies: ["SwiftHighlight"],
            path: "Sources/ProfileRunner",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SwiftHighlightTests",
            dependencies: ["SwiftHighlight"],
            resources: [
                .copy("Fixtures")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
