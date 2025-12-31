// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Benchmarks",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.0.0"),
        .package(url: "https://github.com/appstefan/HighlightSwift", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "HighlightBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "SwiftHighlight", package: "swift-highlight"),
                .product(name: "HighlightSwift", package: "HighlightSwift"),
            ],
            path: "HighlightBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
    ]
)
