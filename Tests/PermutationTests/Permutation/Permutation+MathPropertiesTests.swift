// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+MathPropertiesTests.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+Composition.swift, Permutation/Permutation+MathProperties.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation+Power.swift, Permutation/Permutation.swift, Support/Deck.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationMathPropertiesTests {

    func randomPermutations(seed: UInt64, maximumCount: Int = 9) -> [Permutation] {
        var generator: SeededGenerator = SeededGenerator(state: seed)
        return (0..<200).map { _ in Permutation(shuffles: Int.random(in: 0...maximumCount, using: &generator), using: &generator) }
    }

    @Test func subscriptGivesWhereEachElementMoves() {
        #expect(Permutation(cycle: [2, 0, 1])[2] == 0)
        #expect(Permutation(cycle: [2, 0, 1])[1] == 2)
        #expect(Permutation(cycle: [2, 0, 1])[7] == 7)
        for permutation in randomPermutations(seed: 15) {
            let count: Int = permutation.minimumCount
            let sources: [Int] = permutation.sources(count: count)
            for destination in 0..<count {
                #expect(permutation[sources[destination]] == destination)
            }
            #expect(permutation[count + 3] == count + 3)
        }
    }

    @Test func swappingMatchesFollowingWithASwap() {
        var generator: SeededGenerator = SeededGenerator(state: 16)
        for permutation in randomPermutations(seed: 17) {
            let count: Int = permutation.minimumCount + 3
            let first: Int = Int.random(in: 0..<count, using: &generator)
            let second: Int = Int.random(in: 0..<count, using: &generator)
            let swap: Permutation = first == second ? Permutation(cycle: []) : Permutation(cycle: [max(first, second), min(first, second)])
            #expect(permutation.swapping(first, second) == permutation.followed(by: swap))
        }
    }

    @Test func swapReturnsThePermutationItApplied() {
        let original: [String] = (0..<6).map(String.init)
        var deck: Deck = Deck(cards: original)
        let applied: Permutation = deck.swap(1, 4)
        #expect(deck.cards == ["0", "4", "2", "3", "1", "5"])
        #expect(Deck(cards: original).applying(applied).cards == deck.cards)
        #expect(deck.swap(2, 2).cycle.isEmpty)
    }
}
