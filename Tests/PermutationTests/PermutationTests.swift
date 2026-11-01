// repository: https://github.com/JonathanStorey/swift-permutation
// path: PermutationTests.swift
// dependencies: [PermutableCollection.swift, Permutation.swift]

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
        deck.permute(using: permutation.inverted)
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

    @Test func shuffleCycleHasNoFixedPoints() {
        let cycle: [Int] = Permutation(shuffles: 50).cycle
        #expect(Set(cycle).count == cycle.count && cycle.allSatisfy { (0..<50).contains($0) })
        var largest: Int = -1
        let starts: [Bool] = cycle.map { offset in
            defer { largest = max(largest, offset) }
            return offset > largest
        }
        #expect(zip(starts, starts.dropFirst() + [true]).allSatisfy { !($0 && $1) })
    }

    @Test func shuffleOfZeroHasNoCycles() {
        #expect(Permutation(shuffles: 0).cycle.isEmpty)
        #expect(Permutation(shuffles: 1).cycle.isEmpty)
    }

    @Test func squashedWithAppliesBothInOrder() {
        let original: [String] = (0..<8).map(String.init)
        for _ in 0..<50 {
            var deck: Deck = Deck(cards: original)
            let first: Permutation = deck.shuffle()
            let second: Permutation = deck.rotate(toStartAt: 3)
            var replay: Deck = Deck(cards: original)
            replay.permute(using: first.squashed(with: second))
            #expect(replay.cards == deck.cards)
        }
    }

    @Test func squashedWithInvertedIsEmpty() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        let permutation: Permutation = deck.shuffle()
        #expect(permutation.squashed(with: permutation.inverted).cycle.isEmpty)
    }

    @Test func squashedWithShorterPermutationLeavesLaterOffsetsToTheLonger() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        let swap: Permutation = deck.move(from: 0, to: 1)
        let reverse: Permutation = deck.reverse()
        var replay: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        replay.permute(using: swap.squashed(with: reverse))
        #expect(replay.cards == deck.cards)
        #expect(swap.squashed(with: reverse).minimumCount == 5)
    }
}
