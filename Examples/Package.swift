// swift-tools-version: 6.0
// A separate package, so the examples never reach users of the library.

import PackageDescription

let package = Package(
    name: "PermutationExamples",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "FunFacts",
            dependencies: [
                .product(name: "Permutation", package: "swift-permutation"),
            ]
        ),
    ]
)
