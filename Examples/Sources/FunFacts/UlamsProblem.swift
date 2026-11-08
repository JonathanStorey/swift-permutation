// repository: https://github.com/JonathanStorey/swift-permutation
// path: Examples/Sources/FunFacts/UlamsProblem.swift
// dependencies: [SplitMix64.swift]

import Permutation

/// Ulam's problem: the longest increasing run hidden in a random shuffle of n cards has length close to 2√n.
///
/// Explained in [Docs/UlamsProblem.md](../../Docs/UlamsProblem.md).
enum UlamsProblem {

    static func run() {
        var generator: SplitMix64 = SplitMix64(state: 5)
        print("5. Ulam's problem: longest increasing subsequence of a random shuffle")
        for n in [100, 10_000, 1_000_000] {
            let trials: Int = n >= 1_000_000 ? 3 : 20
            var total: Int = 0
            for _ in 0..<trials {
                var hand: Arrangement<Int> = Arrangement(0..<n)
                hand.shuffle(using: &generator)
                // Sorting returns the permutation it applied, and its moves replay it with the fewest single-card moves, leaving a longest increasing subsequence in place.
                let sorting: Permutation = hand.sort()
                precondition(hand.isInOriginalOrder)
                var moves: Int = 0
                for _ in sorting.moves { moves += 1 }
                total += n - moves
            }
            let average: Double = Double(total) / Double(trials)
            let root: Double = Double(n).squareRoot()
            print("   n = \(n): average longest run \(format(average, digits: 1)), 2√n = \(format(2 * root, digits: 1)), ratio \(format(average / root))")
        }
    }
}
