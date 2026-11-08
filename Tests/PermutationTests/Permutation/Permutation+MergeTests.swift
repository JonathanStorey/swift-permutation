// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+MergeTests.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+Composition.swift, Permutation/Permutation+Merge.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationMergeTests {

    @Test func mergingOfDisjointChangesAppliesBoth() {
        var generator: SeededGenerator = SeededGenerator(state: 12)
        let base: Permutation = Permutation(shuffles: 8, using: &generator)
        let ourChange: Permutation = Permutation(cycle: [1, 0])
        let theirChange: Permutation = Permutation(cycle: [5, 3, 4])
        let ours: Permutation = base.followed(by: ourChange)
        let theirs: Permutation = base.followed(by: theirChange)
        let merged: Permutation? = ours.merging(with: theirs, from: base)
        var expected: Deck = Deck(cards: (0..<8).map(String.init))
        expected.apply(ours)
        expected.apply(theirChange)
        var actual: Deck = Deck(cards: (0..<8).map(String.init))
        if let merged: Permutation = merged { actual.apply(merged) }
        #expect(merged != nil)
        #expect(actual.cards == expected.cards)
        #expect(merged == theirs.merging(with: ours, from: base))
    }

    @Test func mergingOfIdenticalChangesAppliesItOnce() {
        let base: Permutation = Permutation(cycle: [2, 0, 1])
        let ours: Permutation = base.followed(by: Permutation(cycle: [4, 3]))
        #expect(ours.merging(with: ours, from: base) == ours)
    }

    @Test func mergingOfOverlappingDifferentCyclesIsNil() {
        let base: Permutation = Permutation(cycle: [])
        let ours: Permutation = Permutation(cycle: [1, 0])
        let theirs: Permutation = Permutation(cycle: [2, 1])
        #expect(ours.merging(with: theirs, from: base) == nil)
    }

    @Test func mergingWithSharedCycleKeepsItOnceAlongsideTheRest() {
        let base: Permutation = Permutation(cycle: [])
        let ours: Permutation = Permutation(cycle: [1, 0, 3, 2])
        let theirs: Permutation = Permutation(cycle: [1, 0, 5, 4])
        #expect(ours.merging(with: theirs, from: base) == Permutation(cycle: [1, 0, 3, 2, 5, 4]))
    }

    @Test func mergingWithUnchangedSideReturnsTheOtherSide() {
        let base: Permutation = Permutation(cycle: [3, 1, 2])
        let ours: Permutation = base.followed(by: Permutation(cycle: [5, 0]))
        #expect(ours.merging(with: base, from: base) == ours)
        #expect(base.merging(with: ours, from: base) == ours)
    }

    @Test func mergingWithoutBaseCombinesDisjointChanges() {
        let ours: Permutation = Permutation(cycle: [1, 0])
        let theirs: Permutation = Permutation(cycle: [4, 2, 3])
        #expect(ours.merging(with: theirs) == Permutation(cycle: [1, 0, 4, 2, 3]))
        #expect(ours.merging(with: theirs) == ours.merging(with: theirs, from: Permutation(cycle: [])))
    }

    @Test func mergingWithoutBaseOfConflictingCyclesIsNil() {
        let ours: Permutation = Permutation(cycle: [2, 0, 1])
        let theirs: Permutation = Permutation(cycle: [2, 1])
        #expect(ours.merging(with: theirs) == nil)
    }

    @Test func denseMergeMatchesTheCycleMerge() {
        var generator: SeededGenerator = SeededGenerator(state: 37)
        for _ in 0..<300 {
            let count: Int = Int.random(in: 0...10, using: &generator)
            let whole: [[Int]] = Permutation(shuffles: count, using: &generator).cycleArrays
            let ours: Permutation = Permutation(cycles: whole.filter { _ in Bool.random(using: &generator) })
            let theirs: Permutation = Bool.random(using: &generator)
                ? Permutation(cycles: whole.filter { _ in Bool.random(using: &generator) })
                : Permutation(shuffles: count, using: &generator)
            #expect(ours.merging(with: theirs) == ours.mergingSparse(with: theirs))
            #expect(theirs.merging(with: ours) == theirs.mergingSparse(with: ours))
        }
    }

    @Test func favoringMergeMatchesTheStrictMergeWheneverItSucceeds() {
        var generator: SeededGenerator = SeededGenerator(state: 41)
        for _ in 0..<300 {
            let count: Int = Int.random(in: 0...10, using: &generator)
            let base: Permutation = Permutation(shuffles: count, using: &generator)
            let whole: [[Int]] = Permutation(shuffles: count, using: &generator).cycleArrays
            let ours: Permutation = base.followed(by: Permutation(cycles: whole.filter { _ in Bool.random(using: &generator) }))
            let theirs: Permutation = base.followed(by: Permutation(cycles: whole.filter { _ in Bool.random(using: &generator) }))
            guard let strict: Permutation = ours.merging(with: theirs, from: base) else { continue }
            #expect(ours.merging(with: theirs, from: base, favoring: .ours) == strict)
            #expect(ours.merging(with: theirs, from: base, favoring: .theirs) == strict)
        }
    }

    @Test func favoringMergeKeepsTwoDragsOfDifferentElements() {
        let base: Permutation = Permutation()
        let ours: Permutation = Permutation(sources: [5, 0, 1, 2, 3, 4])
        let theirs: Permutation = Permutation(sources: [1, 2, 3, 4, 5, 0])
        #expect(ours.merging(with: theirs, from: base) == nil)
        let expected: Permutation = Permutation(sources: [5, 1, 2, 3, 4, 0])
        #expect(ours.merging(with: theirs, from: base, favoring: .ours) == expected)
        #expect(ours.merging(with: theirs, from: base, favoring: .theirs) == expected)
    }

    @Test func favoringMergeOfTheSameElementDraggedTwiceKeepsTheFurtherMove() {
        let base: Permutation = Permutation()
        let ours: Permutation = Permutation(sources: [3, 0, 1, 2])
        let theirs: Permutation = Permutation(sources: [0, 3, 1, 2])
        #expect(ours.merging(with: theirs, from: base, favoring: .ours) == ours)
        #expect(ours.merging(with: theirs, from: base, favoring: .theirs) == ours)
    }

    @Test func favoringMergeSettlesALoopOnAValidOrder() {
        let base: Permutation = Permutation()
        let ours: Permutation = Permutation(sources: [1, 0, 2])
        let theirs: Permutation = Permutation(sources: [0, 2, 1])
        #expect(ours.merging(with: theirs, from: base) == nil)
        #expect(ours.merging(with: theirs, from: base, favoring: .ours) == Permutation(sources: [2, 1, 0]))
        #expect(ours.merging(with: theirs, from: base, favoring: .theirs) == ours)
    }

    @Test func favoringMergeAlwaysReturnsAPermutationOfTheSameOffsets() {
        var generator: SeededGenerator = SeededGenerator(state: 43)
        for _ in 0..<300 {
            let count: Int = Int.random(in: 0...12, using: &generator)
            let base: Permutation = Permutation(shuffles: count, using: &generator)
            let ours: Permutation = Permutation(shuffles: count, using: &generator)
            let theirs: Permutation = Permutation(shuffles: count, using: &generator)
            for preference in [Permutation.MergePreference.ours, .theirs] {
                let merged: Permutation = ours.merging(with: theirs, from: base, favoring: preference)
                #expect(merged.minimumCount <= count)
                #expect(merged.sources(count: count).sorted() == Array(0..<count))
                #expect(base.merging(with: theirs, from: base, favoring: preference) == theirs)
                #expect(ours.merging(with: base, from: base, favoring: preference) == ours)
            }
        }
    }

    @Test func twoWayFavoringMergeIsTheThreeWayMergeFromTheIdentity() {
        var generator: SeededGenerator = SeededGenerator(state: 47)
        for _ in 0..<200 {
            let count: Int = Int.random(in: 0...10, using: &generator)
            let ours: Permutation = Permutation(shuffles: count, using: &generator)
            let theirs: Permutation = Permutation(shuffles: count, using: &generator)
            for preference in [Permutation.MergePreference.ours, .theirs] {
                #expect(ours.merging(with: theirs, favoring: preference) == ours.merging(with: theirs, from: Permutation(), favoring: preference))
            }
            if let strict: Permutation = ours.merging(with: theirs) {
                #expect(ours.merging(with: theirs, favoring: .ours) == strict)
            }
        }
    }
}
