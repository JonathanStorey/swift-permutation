// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+ForEachTests.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+ForEach.swift, Permutation/Permutation+Move.swift, Permutation/Permutation+Reverse.swift, Permutation/Permutation+Rotate.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation.swift]

import Testing
@testable import Permutation

@Suite struct PermutationForEachTests {

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
            let last: String = rotated[cycle[cycle.count - 1]]
            for position in stride(from: cycle.count - 1, to: 0, by: -1) {
                rotated[cycle[position]] = rotated[cycle[position - 1]]
            }
            rotated[cycle[0]] = last
        }
        #expect(rotated == deck.cards)
    }

    @Test func forEachMoveReplaysTheShuffle() {
        var generator: SeededGenerator = SeededGenerator(state: 11)
        for count in 0..<30 {
            let original: [String] = (0..<count).map(String.init)
            let permutation: Permutation = Permutation(shuffles: count, using: &generator)
            var deck: Deck = Deck(cards: original)
            deck.apply(permutation)
            var moved: [String] = original
            permutation.forEachMove { from, to in moved.insert(moved.remove(at: from), at: to) }
            #expect(moved == deck.cards)
        }
    }

    @Test func forEachMoveUsesOneMoveForARotation() {
        var moves: [(Int, Int)] = []
        Permutation(rotating: 6, by: 1).forEachMove { moves.append(($0, $1)) }
        #expect(moves.count == 1)
    }

    @Test func forEachMoveUsesOneMoveForASingleMove() {
        var moves: [(Int, Int)] = []
        Permutation(moving: 1, to: 7, count: 10).forEachMove { moves.append(($0, $1)) }
        #expect(moves.count == 1)
        #expect(moves.first?.0 == 1)
        #expect(moves.first?.1 == 7)
    }

    @Test func forEachMoveUsesCountMinusOneMovesForAReversal() {
        var moves: Int = 0
        Permutation(reversing: 8).forEachMove { _, _ in moves += 1 }
        #expect(moves == 7)
    }

    @Test func forEachMoveOfEmptyPermutationCallsNothing() {
        var moves: Int = 0
        Permutation(shuffles: 0).forEachMove { _, _ in moves += 1 }
        #expect(moves == 0)
    }
}
