// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+MergeTests.swift
// dependencies: [PermutableCollection.swift, Permutation+Composition.swift, Permutation+Merge.swift, Permutation+Shuffle.swift, Permutation.swift]

import Testing
@testable import Permutation

@Suite struct PermutationMergeTests {

    @Test func mergeOfDisjointChangesAppliesBoth() {
        var generator: SeededGenerator = SeededGenerator(state: 12)
        let base: Permutation = Permutation(shuffles: 8, using: &generator)
        let ourChange: Permutation = Permutation(cycle: [1, 0])
        let theirChange: Permutation = Permutation(cycle: [5, 3, 4])
        let ours: Permutation = base.followed(by: ourChange)
        let theirs: Permutation = base.followed(by: theirChange)
        let merged: Permutation? = ours.merge(with: theirs, from: base)
        var expected: Deck = Deck(cards: (0..<8).map(String.init))
        expected.apply(ours)
        expected.apply(theirChange)
        var actual: Deck = Deck(cards: (0..<8).map(String.init))
        if let merged: Permutation = merged { actual.apply(merged) }
        #expect(merged != nil)
        #expect(actual.cards == expected.cards)
        #expect(merged == theirs.merge(with: ours, from: base))
    }

    @Test func mergeOfIdenticalChangesAppliesItOnce() {
        let base: Permutation = Permutation(cycle: [2, 0, 1])
        let ours: Permutation = base.followed(by: Permutation(cycle: [4, 3]))
        #expect(ours.merge(with: ours, from: base) == ours)
    }

    @Test func mergeOfOverlappingDifferentCyclesIsNil() {
        let base: Permutation = Permutation(cycle: [])
        let ours: Permutation = Permutation(cycle: [1, 0])
        let theirs: Permutation = Permutation(cycle: [2, 1])
        #expect(ours.merge(with: theirs, from: base) == nil)
    }

    @Test func mergeWithUnchangedSideReturnsTheOtherSide() {
        let base: Permutation = Permutation(cycle: [3, 1, 2])
        let ours: Permutation = base.followed(by: Permutation(cycle: [5, 0]))
        #expect(ours.merge(with: base, from: base) == ours)
        #expect(base.merge(with: ours, from: base) == ours)
    }

    @Test func mergeWithSharedCycleKeepsItOnceAlongsideTheRest() {
        let base: Permutation = Permutation(cycle: [])
        let ours: Permutation = Permutation(cycle: [1, 0, 3, 2])
        let theirs: Permutation = Permutation(cycle: [1, 0, 5, 4])
        #expect(ours.merge(with: theirs, from: base) == Permutation(cycle: [1, 0, 3, 2, 5, 4]))
    }
}
