// repository: https://github.com/JonathanStorey/swift-permutation
// path: Examples/Sources/FunFacts/PiFromShuffles.swift
// dependencies: [SplitMix64.swift]

import Foundation
import Permutation

/// Pi from shuffles: the chance that every cycle of a random shuffle of 2n cards has even length is close to 1/√(π(n + ¼)), so counting such shuffles estimates π.
///
/// Explained in [Docs/PiFromShuffles.md](../../Docs/PiFromShuffles.md).
enum PiFromShuffles {

    static func run() {
        let n: Int = 10
        let cards: Int = 2 * n
        let trials: Int = 1_000_000
        var generator: SplitMix64 = SplitMix64(state: 7)
        var allEven: Int = 0
        for _ in 0..<trials {
            let shuffle: Permutation = Permutation.random(count: cards, using: &generator)
            // A card left in place is a cycle of length 1, and the Foata line omits it, so every card must be on the line.
            if shuffle.cycles.movedCount == cards && shuffle.cycles.allSatisfy({ $0.count % 2 == 0 }) { allEven += 1 }
        }
        let share: Double = Double(allEven) / Double(trials)
        // The exact share is C(2n, n) / 4^n, which Wallis's product ties to π.
        var exact: Double = 1
        for k in 1...n { exact *= Double(2 * k - 1) / Double(2 * k) }
        let estimate: Double = 1 / ((Double(n) + 0.25) * share * share)
        print("7. Wallis's product: \(trials) shuffles of \(cards) cards")
        print("   share whose cycles are all even: \(format(share)), exact C(\(cards), \(n)) / 4^\(n): \(format(exact))")
        print("   estimate of π: \(format(estimate)), from the exact share \(format(1 / ((Double(n) + 0.25) * exact * exact))), π = \(format(Double.pi))")
        precondition(abs(share - exact) < 0.002 && abs(estimate - Double.pi) < 0.05)
    }
}
