// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+ShuffleTests.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Stride.swift, Permutation/Permutation.swift]

import Testing
@testable import Permutation

@Suite struct PermutationShuffleTests {

    @Test func cyclicShuffleIsOneCycleThroughEveryOffset() {
        var generator: SeededGenerator = SeededGenerator(state: 31)
        for count in 2..<12 {
            let permutation: Permutation = Permutation(shuffles: count, .cyclic, using: &generator)
            #expect(permutation.cycle.count == count)
            #expect(permutation.cycle.first == count - 1)
        }
        #expect(Permutation(shuffles: 1, .cyclic).cycle.isEmpty)
    }

    @Test func derangementShuffleMovesEveryOffset() {
        var generator: SeededGenerator = SeededGenerator(state: 32)
        for count in [0, 2, 3, 10, 25] {
            #expect(Permutation(shuffles: count, .derangement, using: &generator).cycle.count == count)
        }
    }

    @Test func inFaroOnFiftyTwoCardsHasOrderFiftyTwo() {
        let faro: Permutation = Permutation(shuffles: 52, .inFaro)
        #expect(faro.advanced(by: 52).cycle.isEmpty)
        #expect([1, 2, 4, 13, 26].allSatisfy { !faro.advanced(by: $0).cycle.isEmpty })
    }

    @Test func outFaroOnFiftyTwoCardsHasOrderEight() {
        let faro: Permutation = Permutation(shuffles: 52, .outFaro)
        #expect(faro.advanced(by: 8).cycle.isEmpty)
        #expect((1..<8).allSatisfy { !faro.advanced(by: $0).cycle.isEmpty })
    }

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
        replay.apply(permutation)
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

    @Test func riffleInterleavesTwoPacketsInOrder() {
        var generator: SeededGenerator = SeededGenerator(state: 33)
        for _ in 0..<50 {
            var deck: Deck = Deck(cards: (0..<20).map(String.init))
            deck.shuffle(.riffle, using: &generator)
            let ranks: [Int] = deck.cards.compactMap { Int($0) }
            #expect((0...20).contains { cut in ranks.filter { $0 < cut } == Array(0..<cut) && ranks.filter { $0 >= cut } == Array(cut..<20) })
        }
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
}
