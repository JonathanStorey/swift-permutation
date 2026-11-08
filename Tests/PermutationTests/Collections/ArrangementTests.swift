// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/ArrangementTests.swift
// dependencies: [Collections/Arrangement.swift, Collections/PermutableDictionary.swift, Collections/PermutableCollection.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Foundation
import Testing
@testable import Permutation

@Suite struct ArrangementTests {

    /// A value that is neither equatable nor hashable, which an arrangement must still reorder.
    struct Card {
        let name: String
    }

    @Test func showsTheElementsInTheOrderGiven() {
        let arrangement: Arrangement<String> = ["c", "a", "b", "a"]
        #expect(Array(arrangement) == ["c", "a", "b", "a"])
        #expect(arrangement.count == 4)
        #expect(arrangement[1] == "a")
        #expect(arrangement.isInOriginalOrder)
        #expect(arrangement.permutation.cycle.isEmpty)
    }

    @Test func reordersWithoutMovingStorage() {
        var arrangement: Arrangement<Int> = Arrangement(10..<20)
        let permutation: Permutation = arrangement.reverse()
        #expect(Array(arrangement) == Array((10..<20).reversed()))
        #expect(arrangement.elements == Array(10..<20))
        #expect(arrangement.permutation == permutation)
        #expect(!arrangement.isInOriginalOrder)
        arrangement.reverse()
        #expect(arrangement.isInOriginalOrder)
    }

    @Test func permutationFoldsEveryReorderSinceCreation() {
        var generator: SeededGenerator = SeededGenerator(state: 7)
        var arrangement: Arrangement<Int> = Arrangement(0..<40)
        var mirror: [Int] = Array(0..<40)
        for _ in 0..<5 {
            let step: Permutation = arrangement.shuffle(using: &generator)
            mirror.apply(step)
        }
        let moved: Permutation = arrangement.move(from: 3, to: 30)
        mirror.apply(moved)
        #expect(Array(arrangement) == mirror)
        #expect(Array(0..<40).applying(arrangement.permutation) == mirror)
    }

    @Test func reordersElementsThatAreNotEquatable() {
        var cards: Arrangement<Card> = Arrangement(["queen", "ace", "king"].map(Card.init))
        cards.sort { $0.name < $1.name }
        #expect(cards.map(\.name) == ["ace", "king", "queen"])
        cards.swapAt(0, 2)
        #expect(cards.map(\.name) == ["queen", "king", "ace"])
    }

    @Test func outFaroShufflesReturnAfterEight() {
        var deck: Arrangement<Int> = Arrangement(0..<52)
        var shuffles: Int = 0
        repeat {
            deck.shuffle(.outFaro)
            shuffles += 1
        } while !deck.isInOriginalOrder
        #expect(shuffles == 8)
    }

    @Test func iteratorAndContiguousStorageAgreeWithTheSubscript() {
        var arrangement: Arrangement<Int> = Arrangement(0..<20)
        #expect(arrangement.withContiguousStorageIfAvailable { Array($0) } == Array(0..<20))
        arrangement.rotate(toStartAt: 5)
        #expect(arrangement.withContiguousStorageIfAvailable { Array($0) } == nil)
        #expect(Array(arrangement) == arrangement.indices.map { arrangement[$0] })
    }

    @Test func equalityAndHashingFollowTheOrderShown() {
        var first: Arrangement<Int> = [1, 2, 3]
        let second: Arrangement<Int> = [3, 2, 1]
        #expect(first != second)
        first.reverse()
        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
    }

    @Test func codableKeepsTheOriginalOrderAndThePermutation() throws {
        var arrangement: Arrangement<String> = ["x", "y", "z"]
        arrangement.rotate(toStartAt: 1)
        let encoder: JSONEncoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data: Data = try encoder.encode(arrangement)
        #expect(String(decoding: data, as: UTF8.self) == "{\"elements\":[\"x\",\"y\",\"z\"],\"permutation\":\(String(decoding: try JSONEncoder().encode(arrangement.permutation), as: UTF8.self))}")
        let decoded: Arrangement<String> = try JSONDecoder().decode(Arrangement<String>.self, from: data)
        #expect(decoded == arrangement)
        #expect(decoded.permutation == arrangement.permutation)
        #expect(!decoded.isInOriginalOrder)
        #expect(arrangement.description == "[\"y\", \"z\", \"x\"]")
    }

    @Test func decodingRejectsAPermutationPastTheElements() {
        let data: Data = Data(#"{"elements":["a","b"],"permutation":[2,0]}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Arrangement<String>.self, from: data) }
    }

    @Test func settingThePermutationJumpsStraightToThatOrder() {
        var generator: SeededGenerator = SeededGenerator(state: 11)
        var arrangement: Arrangement<Int> = Arrangement(0..<30)
        arrangement.shuffle(using: &generator)
        arrangement.reverse()
        let target: Permutation = Permutation(shuffles: 30, using: &generator)
        arrangement.permutation = target
        #expect(arrangement.permutation == target)
        #expect(Array(arrangement) == Array(0..<30).applying(target))
        #expect(arrangement.elements == Array(0..<30))
        arrangement.permutation = Permutation()
        #expect(arrangement.isInOriginalOrder)
        #expect(Array(arrangement) == Array(0..<30))
    }

    @Test func settingTheKeysPermutationReordersWholeEntries() {
        var scores: PermutableDictionary<String, Int> = ["ann": 3, "bob": 9, "cy": 5]
        scores.sort { $0.value > $1.value }
        scores.keys.permutation = Permutation()
        #expect(Array(scores.keys) == ["ann", "bob", "cy"])
        #expect(Array(scores.values) == [3, 9, 5])
        #expect(scores["bob"] == 9)
    }
}
