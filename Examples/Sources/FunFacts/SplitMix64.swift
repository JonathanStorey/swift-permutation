// repository: https://github.com/JonathanStorey/swift-permutation
// path: Examples/Sources/FunFacts/SplitMix64.swift
// dependencies: []

/// A small seeded generator, so every run of the examples prints the same numbers.
struct SplitMix64: RandomNumberGenerator {

    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value: UInt64 = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
