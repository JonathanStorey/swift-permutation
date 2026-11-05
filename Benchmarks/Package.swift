// swift-tools-version: 6.1
// A separate package, so the benchmark dependencies and their newer platform minimums never reach users of the library.

import PackageDescription

let package = Package(
    name: "PermutationBenchmarks",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/apple/swift-collections-benchmark", from: "0.0.4"),
    ],
    targets: [
        .executableTarget(
            name: "PermutationBenchmarks",
            dependencies: [
                .product(name: "Permutation", package: "swift-permutation"),
                .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
            ]
        ),
        .executableTarget(
            name: "PermutationComparisons",
            dependencies: [
                .product(name: "Permutation", package: "swift-permutation"),
            ]
        ),
    ]
)
