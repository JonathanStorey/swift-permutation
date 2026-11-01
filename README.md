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

It prints a Markdown table of median times. The multiplier beside each `MutableCollection` and `RangeReplaceableCollection` time is that time divided by the `PermutableCollection` time, so a value below 1× is faster. `partition(by:)` through `MutableCollection` is unstable, so it is timed but not checked for the same order.
