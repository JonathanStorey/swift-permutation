// repository: https://github.com/JonathanStorey/swift-permutation
// path: SeededGenerator.swift
// dependencies: []

/// A deterministic SplitMix64 generator so every run shuffles the same way.
struct SeededGenerator: RandomNumberGenerator {

    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value: UInt64 = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}
