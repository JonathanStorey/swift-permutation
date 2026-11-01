// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+CompositionTests.swift
// dependencies: [PermutableCollection.swift, Permutation+Composition.swift, Permutation+Shuffle.swift, Permutation.swift]

import Testing
@testable import Permutation

@Suite struct PermutationCompositionTests {

    @Test func advanceByReplacesWithAdvanced() {
        var generator: SeededGenerator = SeededGenerator(state: 8)
        var permutation: Permutation = Permutation(shuffles: 9, using: &generator)
        let expected: Permutation = permutation.advanced(by: 4)
        permutation.advance(by: 4)
        #expect(permutation == expected)
    }

    @Test func advancedByCycleLengthIsEmpty() {
        var deck: Deck = Deck(cards: (0..<6).map(String.init))
        let rotation: Permutation = deck.rotate(toStartAt: 2)
        #expect(rotation.advanced(by: 3).cycle.isEmpty)
        #expect(rotation.advanced(by: 0).cycle.isEmpty)
    }

    @Test func advancedByMatchesRepeatedFollowedBy() {
        let original: [String] = (0..<10).map(String.init)
        var generator: SeededGenerator = SeededGenerator(state: 3)
        let permutation: Permutation = Permutation(shuffles: 10, using: &generator)
        var repeated: Deck = Deck(cards: original)
        repeated.permute(using: permutation.followed(by: permutation).followed(by: permutation))
        var advanced: Deck = Deck(cards: original)
        advanced.permute(using: permutation.advanced(by: 3))
        #expect(advanced.cards == repeated.cards)
    }

    @Test func advancedByNegativeOneUndoes() {
        let original: [String] = (0..<10).map(String.init)
        var generator: SeededGenerator = SeededGenerator(state: 4)
        let permutation: Permutation = Permutation(shuffles: 10, using: &generator)
        var deck: Deck = Deck(cards: original)
        deck.permute(using: permutation)
        deck.permute(using: permutation.advanced(by: -1))
        #expect(deck.cards == original)
    }

    @Test func followedByAppliesBothInOrder() {
        let original: [String] = (0..<8).map(String.init)
        for _ in 0..<50 {
            var deck: Deck = Deck(cards: original)
            let first: Permutation = deck.shuffle()
            let second: Permutation = deck.rotate(toStartAt: 3)
            var replay: Deck = Deck(cards: original)
            replay.permute(using: first.followed(by: second))
            #expect(replay.cards == deck.cards)
        }
    }

    @Test func followedByInvertedIsEmpty() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        let permutation: Permutation = deck.shuffle()
        #expect(permutation.followed(by: permutation.inverted).cycle.isEmpty)
    }

    @Test func followedByShorterPermutationLeavesLaterOffsetsToTheLonger() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        let swap: Permutation = deck.move(from: 0, to: 1)
        let reverse: Permutation = deck.reverse()
        var replay: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        replay.permute(using: swap.followed(by: reverse))
        #expect(replay.cards == deck.cards)
        #expect(swap.followed(by: reverse).minimumCount == 5)
    }
}
