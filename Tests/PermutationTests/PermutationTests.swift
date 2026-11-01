// repository: https://github.com/JonathanStorey/swift-permutation
// path: PermutationTests.swift
// dependencies: [PermutableCollection.swift, Permutation+Shuffle.swift, Permutation.swift]

import Testing
@testable import Permutation

@Suite struct PermutationTests {

    @Test func invertedOfEmptyPermutationIsEmpty() {
        #expect(Permutation(shuffles: 0).inverted.cycle.isEmpty)
    }

    @Test func invertedUndoesShuffle() {
        let original: [String] = (0..<25).map(String.init)
        var deck: Deck = Deck(cards: original)
        let permutation: Permutation = deck.shuffle()
        deck.apply(permutation.inverted)
        #expect(deck.cards == original)
    }

    @Test func minimumCountIsOneMoreThanLargestOffset() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        #expect(deck.reverse().minimumCount == 5)
        #expect(deck.rotate(toStartAt: 1).minimumCount == 5)
    }

    @Test func minimumCountOfEmptyPermutationIsZero() {
        #expect(Permutation(shuffles: 0).minimumCount == 0)
    }
}
