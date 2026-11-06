// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+ForEachTests.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+ForEach.swift, Permutation/Permutation+Move.swift, Permutation/Permutation+Reverse.swift, Permutation/Permutation+Rotate.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift, Support/Deck.swift, Support/SeededGenerator.swift]

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

    /// The original replay: find each element by a linear search, remove it, and insert it after the element before it in the final order.
    func replayedMoves(of permutation: Permutation) -> [[Int]] {
        let count: Int = permutation.minimumCount
        guard count > 1 else { return [] }
        let sources: [Int] = permutation.sources(count: count)
        var tails: [Int] = []
        var previous: [Int] = Array(repeating: -1, count: count)
        for position in 0..<count {
            var low: Int = 0
            var high: Int = tails.count
            while low < high {
                let middle: Int = (low + high) / 2
                if sources[tails[middle]] < sources[position] { low = middle + 1 } else { high = middle }
            }
            if low > 0 { previous[position] = tails[low - 1] }
            if low == tails.count { tails.append(position) } else { tails[low] = position }
        }
        var stays: [Bool] = Array(repeating: false, count: count)
        var position: Int = tails.last ?? -1
        while position >= 0 {
            stays[position] = true
            position = previous[position]
        }
        var current: [Int] = Array(0..<count)
        var moves: [[Int]] = []
        for position in 0..<count where !stays[position] {
            let element: Int = sources[position]
            let from: Int = current.firstIndex(of: element)!
            current.remove(at: from)
            let to: Int = position == 0 ? 0 : current.firstIndex(of: sources[position - 1])! + 1
            current.insert(element, at: to)
            moves.append([from, to])
        }
        return moves
    }

    @Test func forEachMoveMatchesTheLinearReplay() {
        var generator: SeededGenerator = SeededGenerator(state: 41)
        for _ in 0..<300 {
            let permutation: Permutation = Permutation(shuffles: Int.random(in: 0...40, using: &generator), using: &generator)
            var moves: [[Int]] = []
            permutation.forEachMove { moves.append([$0, $1]) }
            #expect(moves == replayedMoves(of: permutation))
        }
    }
}
