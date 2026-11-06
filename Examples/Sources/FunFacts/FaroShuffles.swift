// repository: https://github.com/JonathanStorey/swift-permutation
// path: Examples/Sources/FunFacts/FaroShuffles.swift
// dependencies: []

import Permutation

/// Perfect shuffles: eight out-faro shuffles put a 52-card deck back in order, while in-faros need 52.
///
/// Explained in [Docs/FaroShuffles.md](../../Docs/FaroShuffles.md).
enum FaroShuffles {

    static func run() {
        let deck: Int = 52
        let outFaro: Permutation = Permutation(shuffles: deck, .outFaro)
        let inFaro: Permutation = Permutation(shuffles: deck, .inFaro)
        print("3. Perfect shuffles of a \(deck)-card deck")
        print("   out-faros to restore the deck: \(outFaro.order), cycle lengths \(outFaro.cycleLengths)")
        print("   in-faros to restore the deck: \(inFaro.order), cycle lengths \(inFaro.cycleLengths)")
        // The order is the least common multiple of the cycle lengths, read off the Foata line without shuffling once.
        precondition(outFaro.order == 8 && inFaro.order == 52)
        // Eight applications compose back to the identity.
        precondition(outFaro.advanced(by: 8).cycle.isEmpty)
    }
}
