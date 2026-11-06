// repository: https://github.com/JonathanStorey/swift-permutation
// path: Examples/Sources/FunFacts/Derangements.swift
// dependencies: [SplitMix64.swift]

import Foundation
import Permutation

/// The hat-check problem: the chance that a random permutation moves every element tends to 1/e.
///
/// Explained in [Docs/Derangements.md](../../Docs/Derangements.md).
enum Derangements {

    /// The exact number of derangements of `n` items, from the recurrence D(n) = (n − 1)(D(n − 1) + D(n − 2)).
    static func count(_ n: Int) -> Double {
        var previous: Double = 1
        var current: Double = 0
        guard n > 0 else { return previous }
        for k in stride(from: 2, through: n, by: 1) {
            (previous, current) = (current, Double(k - 1) * (current + previous))
        }
        return current
    }

    static func run() {
        let guests: Int = 20
        let trials: Int = 200_000
        var generator: SplitMix64 = SplitMix64(state: 1)
        var everyoneMoved: Int = 0
        for _ in 0..<trials {
            // The Foata line lists exactly the moved offsets, so a derangement is a line that holds every offset.
            if Permutation(shuffles: guests, using: &generator).cycle.count == guests { everyoneMoved += 1 }
        }
        var factorial: Double = 1
        for k in 1...guests { factorial *= Double(k) }
        let exact: Double = count(guests) / factorial
        print("1. Derangements: \(guests) guests, \(trials) random hat returns")
        print("   simulated chance nobody gets their own hat: \(format(Double(everyoneMoved) / Double(trials)))")
        print("   exact D(\(guests)) / \(guests)!: \(format(exact))    1/e: \(format(1 / M_E))")
        precondition(abs(Double(everyoneMoved) / Double(trials) - exact) < 0.005)
    }
}
