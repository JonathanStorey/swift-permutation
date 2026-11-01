// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+ShuffleableTests.swift
// dependencies: [PermutableCollection.swift, Permutation+Shuffleable.swift, Permutation.swift]

import Testing
@testable import Permutation

@Suite struct PermutationShuffleableTests {

    @Test func permutationShuffleOfEmptyPermutationIsEmpty() {
        var permutation: Permutation = Permutation(shuffles: 0)
        permutation.shuffle()
        #expect(permutation.cycle.isEmpty)
    }

    @Test func permutationShuffleStaysWithinMinimumCount() {
        var deck: Deck = Deck(cards: (0..<12).map(String.init))
        var permutation: Permutation = deck.reverse()
        permutation.shuffle()
        #expect(permutation.minimumCount <= 12)
        var replay: Deck = Deck(cards: (0..<12).map(String.init))
        replay.permute(using: permutation)
        #expect(replay.cards.sorted() == (0..<12).map(String.init).sorted())
    }

    @Test func permutationShuffleUsingGeneratorIsDeterministic() {
        var first: SeededGenerator = SeededGenerator(state: 11)
        var second: SeededGenerator = SeededGenerator(state: 11)
        let firstPermutation: Permutation = Permutation(shuffles: 40, using: &first)
        let secondPermutation: Permutation = Permutation(shuffles: 40, using: &second)
        #expect(firstPermutation == secondPermutation)
        #expect(first.state == second.state)
    }

    @Test func permutationShuffledLeavesOriginalUnchanged() {
        var generator: SeededGenerator = SeededGenerator(state: 5)
        let original: Permutation = Permutation(shuffles: 30, using: &generator)
        let copy: Permutation = original
        var expectedGenerator: SeededGenerator = generator
        let shuffled: Permutation = original.shuffled(using: &generator)
        #expect(original == copy)
        let expected: Permutation = Permutation(shuffles: original.minimumCount, using: &expectedGenerator)
        #expect(shuffled == expected)
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

    @Test func shuffleKeepsEveryElement() {
        var deck: Deck = Deck(cards: (0..<20).map(String.init))
        deck.shuffle()
        #expect(deck.cards.sorted() == (0..<20).map(String.init).sorted())
    }

    @Test func shuffleOfZeroHasNoCycles() {
        #expect(Permutation(shuffles: 0).cycle.isEmpty)
        #expect(Permutation(shuffles: 1).cycle.isEmpty)
    }

    @Test func shuffleUsingGeneratorMatchesArray() {
        var deckGenerator: SeededGenerator = SeededGenerator(state: 99)
        var arrayGenerator: SeededGenerator = SeededGenerator(state: 99)
        var deck: Deck = Deck(cards: (0..<30).map(String.init))
        var array: [String] = (0..<30).map(String.init)
        deck.shuffle(using: &deckGenerator)
        array.shuffle(using: &arrayGenerator)
        #expect(deck.cards == array)
        #expect(deckGenerator.state == arrayGenerator.state)
    }

    @Test func shuffleUsingGeneratorOnSingleElementLeavesItInPlace() {
        var generator: SeededGenerator = SeededGenerator(state: 3)
        var deck: Deck = Deck(cards: ["a"])
        deck.shuffle(using: &generator)
        #expect(deck.cards == ["a"])
    }
}
