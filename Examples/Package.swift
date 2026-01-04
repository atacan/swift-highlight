// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HighlightDemo",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [.library(name: "HighlightDemoViews", targets: ["HighlightDemoViews"])],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        // Library target for SwiftUI views (enables previews)
        .target(
            name: "HighlightDemoViews",
            dependencies: [
                .product(name: "SwiftHighlight", package: "swift-highlight"),
            ],
            path: "Sources/HighlightDemoViews"
        ),
        // Executable target for command-line demo
        .executableTarget(
            name: "HighlightDemo",
            dependencies: [
                .product(name: "SwiftHighlight", package: "swift-highlight"),
                "HighlightDemoViews",
            ],
            path: "Sources/HighlightDemo"
        ),
    ]
)
