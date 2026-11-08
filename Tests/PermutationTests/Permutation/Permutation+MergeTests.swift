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

    @Test func relativeOrderMergeKeepsEveryReorderAndGivesUpTheFewestBasePairs() {
        var generator: SeededGenerator = SeededGenerator(state: 53)
        for _ in 0..<150 {
            let count: Int = Int.random(in: 0...6, using: &generator)
            let base: Permutation = Permutation(shuffles: count, using: &generator)
            let ours: Permutation = Permutation(shuffles: count, using: &generator)
            let theirs: Permutation = Permutation(shuffles: count, using: &generator)
            let reordered: Set<[Int]> = reorderedPairs(ours, from: base, count: count).union(reorderedPairs(theirs, from: base, count: count))
            let keepers: [Permutation] = Permutation.permutations(count: count).filter { reorderedPairs($0, from: base, count: count).isSuperset(of: reordered) }
            let fewest: Int = keepers.map { reorderedPairs($0, from: base, count: count).count }.min()!
            let best: [Permutation] = keepers.filter { reorderedPairs($0, from: base, count: count).count == fewest }
            let merged: Permutation = ours.merging(with: theirs, from: base, by: .relativeOrder)
            #expect(best == [merged])
            #expect(theirs.merging(with: ours, from: base, by: .relativeOrder) == merged)
        }
    }

    @Test func relativeOrderMergeWithUnchangedSideReturnsTheOtherSide() {
        var generator: SeededGenerator = SeededGenerator(state: 43)
        for _ in 0..<100 {
            let count: Int = Int.random(in: 0...12, using: &generator)
            let base: Permutation = Permutation(shuffles: count, using: &generator)
            let ours: Permutation = Permutation(shuffles: count, using: &generator)
            #expect(base.merging(with: ours, from: base, by: .relativeOrder) == ours)
            #expect(ours.merging(with: base, from: base, by: .relativeOrder) == ours)
            #expect(ours.merging(with: ours, from: base, by: .relativeOrder) == ours)
        }
    }

    @Test func relativeOrderMergeSettlesTheLoopKeepingBothEdits() {
        let ours: Permutation = Permutation(sources: [1, 0, 2])
        let theirs: Permutation = Permutation(sources: [0, 2, 1])
        #expect(ours.merging(with: theirs, from: Permutation()) == nil)
        #expect(ours.merging(with: theirs, by: .relativeOrder) == Permutation(sources: [2, 1, 0]))
    }

    @Test func relativeOrderMergeKeepsTwoDragsOfDifferentElements() {
        let ours: Permutation = Permutation(sources: [5, 0, 1, 2, 3, 4])
        let theirs: Permutation = Permutation(sources: [1, 2, 3, 4, 5, 0])
        #expect(ours.merging(with: theirs) == nil)
        #expect(ours.merging(with: theirs, by: .relativeOrder) == Permutation(sources: [5, 1, 2, 3, 4, 0]))
    }

    @Test func relativeOrderMergeOfTheSameElementDraggedTwiceKeepsTheFurtherMove() {
        let ours: Permutation = Permutation(sources: [3, 0, 1, 2])
        let theirs: Permutation = Permutation(sources: [0, 3, 1, 2])
        #expect(ours.merging(with: theirs, by: .relativeOrder) == ours)
    }

    @Test func twoWayRelativeOrderMergeIsTheThreeWayMergeFromTheIdentity() {
        var generator: SeededGenerator = SeededGenerator(state: 47)
        for _ in 0..<200 {
            let count: Int = Int.random(in: 0...10, using: &generator)
            let ours: Permutation = Permutation(shuffles: count, using: &generator)
            let theirs: Permutation = Permutation(shuffles: count, using: &generator)
            #expect(ours.merging(with: theirs, by: .relativeOrder) == ours.merging(with: theirs, from: Permutation(), by: .relativeOrder))
        }
    }

    /// The pairs of offsets, earlier in base first, that the permutation shows in the opposite order from base.
    private func reorderedPairs(_ permutation: Permutation, from base: Permutation, count: Int) -> Set<[Int]> {
        let baseOrder: [Int] = base.sources(count: count)
        var positions: [Int] = [Int](repeating: 0, count: count)
        for (position, offset) in permutation.sources(count: count).enumerated() { positions[offset] = position }
        var pairs: Set<[Int]> = []
        for later in 0..<count {
            for earlier in 0..<later where positions[baseOrder[later]] < positions[baseOrder[earlier]] {
                pairs.insert([baseOrder[earlier], baseOrder[later]])
            }
        }
        return pairs
    }
}
