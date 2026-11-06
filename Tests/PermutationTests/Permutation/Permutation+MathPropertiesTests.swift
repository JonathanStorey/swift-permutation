// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+MathPropertiesTests.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+Composition.swift, Permutation/Permutation+MathProperties.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation+Stride.swift, Permutation/Permutation.swift, Support/Deck.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationMathPropertiesTests {

    func randomPermutations(seed: UInt64, maximumCount: Int = 9) -> [Permutation] {
        var generator: SeededGenerator = SeededGenerator(state: seed)
        return (0..<200).map { _ in Permutation(shuffles: Int.random(in: 0...maximumCount, using: &generator), using: &generator) }
    }

    @Test func cycleLengthsSplitTheLineAtEachLargestOffset() {
        #expect(Permutation(cycle: [2, 0, 1, 5, 3, 7, 6, 4]).cycleLengths == [3, 2, 3])
        #expect(Permutation(cycle: []).cycleLengths.isEmpty)
        for permutation in randomPermutations(seed: 11) {
            #expect(permutation.cycleLengths.reduce(0, +) == permutation.cycle.count)
            #expect(permutation.cycleLengths.allSatisfy { $0 > 1 })
        }
    }

    @Test func orderIsTheFirstPowerThatIsTheIdentity() {
        #expect(Permutation(cycle: []).order == 1)
        #expect(Permutation(cycle: [2, 0, 1, 4, 3]).order == 6)
        for permutation in randomPermutations(seed: 12) {
            let order: Int = permutation.order
            #expect(permutation.advanced(by: order).cycle.isEmpty)
            #expect((1..<order).allSatisfy { !permutation.advanced(by: $0).cycle.isEmpty })
        }
    }

    @Test func isEvenMatchesTheParityOfInversions() {
        #expect(Permutation(cycle: []).isEven)
        #expect(!Permutation(cycle: [1, 0]).isEven)
        #expect(Permutation(cycle: [2, 0, 1]).isEven)
        for permutation in randomPermutations(seed: 13) {
            let sources: [Int] = permutation.sources(count: permutation.minimumCount)
            var inversions: Int = 0
            for i in sources.indices {
                for j in sources.indices where i < j && sources[i] > sources[j] {
                    inversions += 1
                }
            }
            #expect(permutation.isEven == inversions.isMultiple(of: 2))
        }
    }

    @Test func isInvolutionMatchesSquaringToTheIdentity() {
        #expect(Permutation(cycle: []).isInvolution)
        #expect(Permutation(cycle: [1, 0, 4, 2]).isInvolution)
        #expect(!Permutation(cycle: [2, 0, 1]).isInvolution)
        for permutation in randomPermutations(seed: 14, maximumCount: 5) {
            #expect(permutation.isInvolution == permutation.followed(by: permutation).cycle.isEmpty)
        }
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
