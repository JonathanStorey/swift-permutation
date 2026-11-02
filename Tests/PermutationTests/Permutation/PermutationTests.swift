// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/PermutationTests.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation.swift]

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

    @Test func forEachCycleSplitsTheLineAtEachNewLargestOffset() {
        var cycles: [[Int]] = []
        Permutation(cycle: [2, 0, 5, 3, 4, 7, 6]).forEachCycle { cycles.append($0) }
        #expect(cycles == [[2, 0], [5, 3, 4], [7, 6]])
    }

    @Test func forEachCycleOfEmptyPermutationCallsNothing() {
        var calls: Int = 0
        Permutation(shuffles: 0).forEachCycle { _ in calls += 1 }
        #expect(calls == 0)
    }

    @Test func forEachCycleMovesEachElementToTheNextOffset() {
        var generator: SeededGenerator = SeededGenerator(state: 7)
        let original: [String] = (0..<40).map(String.init)
        let permutation: Permutation = Permutation(shuffles: 40, using: &generator)
        var deck: Deck = Deck(cards: original)
        deck.apply(permutation)
        var rotated: [String] = original
        permutation.forEachCycle { cycle in
            let last: Int = rotated[cycle[cycle.count - 1]]
            for position in stride(from: cycle.count - 1, to: 0, by: -1) {
                rotated[cycle[position]] = rotated[cycle[position - 1]]
            }
            rotated[cycle[0]] = last
        }
        #expect(rotated == deck.cards)
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
