// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+StrideTests.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+Composition.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation+Stride.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationStrideTests {

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
        repeated.apply(permutation.followed(by: permutation).followed(by: permutation))
        var advanced: Deck = Deck(cards: original)
        advanced.apply(permutation.advanced(by: 3))
        #expect(advanced.cards == repeated.cards)
    }

    @Test func advancedByNegativeOneUndoes() {
        let original: [String] = (0..<10).map(String.init)
        var generator: SeededGenerator = SeededGenerator(state: 4)
        let permutation: Permutation = Permutation(shuffles: 10, using: &generator)
        var deck: Deck = Deck(cards: original)
        deck.apply(permutation)
        deck.apply(permutation.advanced(by: -1))
        #expect(deck.cards == original)
    }

    @Test func advancedBySplitsCycleByGreatestCommonDivisor() {
        let permutation: Permutation = Permutation(cycle: [1_000_005, 1_000_000, 1_000_001, 1_000_002, 1_000_003, 1_000_004])
        #expect(permutation.advanced(by: 2).cycle == [1_000_004, 1_000_000, 1_000_002, 1_000_005, 1_000_001, 1_000_003])
    }

    @Test func advancedMatchesRepeatedComposition() {
        var generator: SeededGenerator = SeededGenerator(state: 43)
        for _ in 0..<300 {
            let permutation: Permutation = Permutation(shuffles: Int.random(in: 0...14, using: &generator), using: &generator)
            let distance: Int = Int.random(in: -20...20, using: &generator)
            let base: Permutation = distance < 0 ? permutation.inverted : permutation
            var repeated: Permutation = Permutation(cycle: [])
            for _ in 0..<abs(distance) {
                repeated = repeated.followed(by: base)
            }
            #expect(permutation.advanced(by: distance) == repeated)
        }
    }
}
