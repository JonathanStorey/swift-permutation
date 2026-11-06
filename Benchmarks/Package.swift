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
        .package(url: "https://github.com/apple/swift-collections", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "PermutationBenchmarks",
            dependencies: [
                .product(name: "Permutation", package: "swift-permutation"),
                .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
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
