// repository: https://github.com/JonathanStorey/swift-permutation
// path: Examples/Sources/FunFacts/main.swift
// dependencies: [HatCheckProblem.swift, FaroShuffles.swift, FifteenPuzzle.swift, HundredPrisoners.swift, PiFromShuffles.swift, SecretSanta.swift, UlamsProblem.swift]

import Foundation

/// Formats a number with a fixed count of digits after the point.
func format(_ value: Double, digits: Int = 4) -> String {
    String(format: "%.\(digits)f", value)
}

HatCheckProblem.run()
print()
HundredPrisoners.run()
print()
FaroShuffles.run()
print()
FifteenPuzzle.run()
print()
UlamsProblem.run()
print()
SecretSanta.run()
print()
PiFromShuffles.run()
