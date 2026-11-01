// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Permutation",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Permutation",
            targets: ["Permutation"]
        ),
    ],
    targets: [
        .target(
            name: "Permutation"
        ),
        .executableTarget(
            name: "PermutationBenchmarks",
            dependencies: ["Permutation"],
            path: "Benchmarks/PermutationBenchmarks"
        ),
        .testTarget(
            name: "PermutationTests",
            dependencies: ["Permutation"]
        ),
    ]
)
