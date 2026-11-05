# Permutation

A Swift package for reordering collections through permutations.

## Requirements

- Swift 6.0+
- iOS 17+ / macOS 14+

## Installation

Add the package to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/JonathanStorey/swift-permutation.git", branch: "main")
```

Then add `.product(name: "Permutation", package: "swift-permutation")` to your target's dependencies and `import Permutation`.

## Development

```sh
swift build
swift test
```

## Benchmarks

`Benchmarks/PermutationBenchmarks` times each `PermutableCollection` operation against the same reordering written with `MutableCollection` and with `RangeReplaceableCollection` on an `[Int]`, and checks first that all three give the same order. Run it in release mode:

```sh
swift run -c release PermutationBenchmarks
```

It prints a Markdown table of median times. Each `MutableCollection` and `RangeReplaceableCollection` time says how many times faster or slower it is than the `PermutableCollection` time. `stablePartition(by:)` is timed against `MutableCollection`'s unstable `partition(by:)`, which is not checked for the same order.
