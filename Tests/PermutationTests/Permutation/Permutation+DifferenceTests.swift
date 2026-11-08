// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+DifferenceTests.swift
// dependencies: [Collections/Collection+Permutation.swift, Permutation/Permutation+Difference.swift, Permutation/Permutation+Moves.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationDifferenceTests {

    @Test func readsAPureReorder() throws {
        let old: [String] = ["a", "b", "c", "d", "e"]
        let new: [String] = ["c", "a", "b", "e", "d"]
        let permutation: Permutation = try #require(Permutation(new.difference(from: old)))
        #expect(old.applying(permutation) == new)
    }

    @Test func matchesAnyShuffleOfDistinctElements() throws {
        var generator: SeededGenerator = SeededGenerator(state: 5)
        for count in [0, 1, 2, 10, 200] {
            let old: [Int] = Array(0..<count)
            let new: [Int] = old.shuffled(using: &generator)
            let permutation: Permutation = try #require(Permutation(new.difference(from: old)))
            #expect(old.applying(permutation) == new)
        }
    }

    @Test func roundTripsThroughMoves() throws {
        var generator: SeededGenerator = SeededGenerator(state: 6)
        for _ in 0..<50 {
            let shuffle: Permutation = Permutation.random(count: 30, using: &generator)
            let old: [Int] = Array(0..<30)
            var new: [Int] = old
            for move in shuffle.moves { new.insert(new.remove(at: move.from), at: move.to) }
            let read: Permutation = try #require(Permutation(new.difference(from: old)))
            #expect(old.applying(read) == new)
        }
    }

    @Test func identicalCollectionsGiveTheIdentity() {
        #expect(Permutation(["a", "b"].difference(from: ["a", "b"])) == Permutation())
    }

    @Test func insertionsAndRemovalsGiveNil() {
        #expect(Permutation(["a", "b", "c"].difference(from: ["a", "b"])) == nil)
        #expect(Permutation(["a"].difference(from: ["a", "b"])) == nil)
        #expect(Permutation(["b", "a", "x"].difference(from: ["a", "b", "y"])) == nil)
    }

    @Test func movedDuplicatesGiveNil() {
        #expect(Permutation([2, 2, 1, 1].difference(from: [1, 1, 2, 2])) == nil)
    }

    @Test func mismatchedHandBuiltPairsGiveNil() throws {
        let difference: CollectionDifference<String> = try #require(CollectionDifference([
            .remove(offset: 0, element: "a", associatedWith: 1),
            .insert(offset: 1, element: "b", associatedWith: 0),
        ]))
        #expect(Permutation(difference) == nil)
    }
}
