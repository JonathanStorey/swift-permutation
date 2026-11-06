// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+CompositionTests.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+Composition.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationCompositionTests {

    @Test func followedByAppliesBothInOrder() {
        let original: [String] = (0..<8).map(String.init)
        for _ in 0..<50 {
            var deck: Deck = Deck(cards: original)
            let first: Permutation = deck.shuffle()
            let second: Permutation = deck.rotate(toStartAt: 3)
            var replay: Deck = Deck(cards: original)
            replay.apply(first.followed(by: second))
            #expect(replay.cards == deck.cards)
        }
    }

    @Test func followedByInvertedIsEmpty() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        let permutation: Permutation = deck.shuffle()
        #expect(permutation.followed(by: permutation.inverted).cycle.isEmpty)
    }

    @Test func followedByOnFarOffsetsComposesTheirCycles() {
        let first: Permutation = Permutation(cycle: [1_000_001, 1_000_000])
        let second: Permutation = Permutation(cycle: [1_000_002, 1_000_001])
        #expect(first.followed(by: second).cycle == [1_000_002, 1_000_001, 1_000_000])
    }

    @Test func followedByShorterPermutationLeavesLaterOffsetsToTheLonger() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        let swap: Permutation = deck.move(from: 0, to: 1)
        let reverse: Permutation = deck.reverse()
        var replay: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        replay.apply(swap.followed(by: reverse))
        #expect(replay.cards == deck.cards)
        #expect(swap.followed(by: reverse).minimumCount == 5)
    }

    @Test func denseProductMatchesTheCycleProduct() {
        var generator: SeededGenerator = SeededGenerator(state: 31)
        for _ in 0..<200 {
            let first: Permutation = Permutation(shuffles: Int.random(in: 0...12, using: &generator), using: &generator)
            let second: Permutation = Permutation(shuffles: Int.random(in: 0...12, using: &generator), using: &generator)
            #expect(first.followed(by: second) == first.followedSparse(by: second))
        }
    }

    @Test func distantOffsetsTakeTheSparsePath() {
        let far: Permutation = Permutation(cycle: [100_000, 0])
        let near: Permutation = Permutation(cycle: [2, 1])
        #expect(!Permutation.prefersDense(count: far.minimumCount, support: far.cycle.count + near.cycle.count))
        #expect(far.followed(by: near) == Permutation(cycles: [[0, 100_000], [1, 2]]))
        #expect(far.followed(by: far).cycle.isEmpty)
    }
}
