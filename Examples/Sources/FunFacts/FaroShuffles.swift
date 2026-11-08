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
        let outFaro: Permutation = Permutation.outFaro(count: deck)
        let inFaro: Permutation = Permutation.inFaro(count: deck)
        print("3. Perfect shuffles of a \(deck)-card deck")
        print("   out-faros to restore the deck: \(outFaro.cycles.order), cycle lengths \(outFaro.cycles.map(\.count))")
        print("   in-faros to restore the deck: \(inFaro.cycles.order), cycle lengths \(inFaro.cycles.map(\.count))")
        // The order is the least common multiple of the cycle lengths, read off the Foata line without shuffling once.
        precondition(outFaro.cycles.order == 8 && inFaro.cycles.order == 52)
        // Eight applications compose back to the identity.
        precondition(outFaro.raised(to: 8).cycles.isEmpty)
        // Shuffling a real deck agrees: an arrangement knows when its cards are back where they started.
        var cards: Arrangement<String> = Arrangement(Self.cards)
        var shuffles: Int = 0
        repeat {
            cards.shuffle(.outFaro)
            shuffles += 1
            if shuffles == 4 { print("   after 4 out-faros the top cards read \(cards.prefix(4).joined(separator: " "))") }
        } while !cards.permutation.cycles.isEmpty
        print("   shuffling an Arrangement by hand restores the deck after \(shuffles) out-faros")
        precondition(shuffles == outFaro.cycles.order)
    }

    /// A standard deck in new-deck order: spades, hearts, clubs and diamonds, each from ace to king.
    static let cards: [String] = ["♠", "♥", "♣", "♦"].flatMap { suit in
        ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"].map { $0 + suit }
    }
}
