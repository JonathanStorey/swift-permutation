// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+RangeReplaceTests.swift
// dependencies: [Permutation+RangeReplace.swift, Permutation.swift]

import Testing
@testable import Permutation

@Suite struct PermutationRangeReplaceTests {

    @Test func insertAtFrontShiftsEveryOffset() {
        var permutation: Permutation = Permutation(cycle: [1, 0])
        permutation.insert(at: 0)
        #expect(permutation.cycle == [2, 1])
    }

    @Test func insertBeyondMinimumCountLeavesPermutationUnchanged() {
        var permutation: Permutation = Permutation(cycle: [])
        permutation.insert(count: 3, at: 5)
        #expect(permutation.cycle.isEmpty)
    }

    @Test func insertCountShiftsLaterOffsetsAndLeavesNewOnesInPlace() {
        var permutation: Permutation = Permutation(cycle: [1, 0, 3, 2])
        permutation.insert(count: 2, at: 2)
        #expect(permutation.cycle == [1, 0, 5, 4])
    }

    @Test func insertInsideCycleKeepsTheCycle() {
        var permutation: Permutation = Permutation(cycle: [1, 0, 3, 2])
        permutation.insert(at: 1)
        #expect(permutation.cycle == [2, 0, 4, 3])
    }

    @Test func removeAtOnFarOffsetsSplicesWithoutTouchingTheRest() {
        var permutation: Permutation = Permutation(cycle: [1, 0, 1_000_002, 1_000_000, 1_000_001])
        permutation.remove(at: 1_000_001)
        #expect(permutation.cycle == [1, 0, 1_000_001, 1_000_000])
    }

    @Test func removeAtSplicesOffsetOutOfItsCycle() {
        var permutation: Permutation = Permutation(cycle: [2, 0, 4, 1, 3])
        permutation.remove(at: 1)
        #expect(permutation.cycle == [1, 0, 3, 2])
    }

    @Test func removeSubrangeBeyondMinimumCountOnlySplicesOffsetsInside() {
        var permutation: Permutation = Permutation(cycle: [2, 0, 4, 1, 3])
        permutation.removeSubrange(4..<8)
        #expect(permutation.cycle == [2, 0, 3, 1])
    }

    @Test func removeSubrangeDropsWholeCycles() {
        var permutation: Permutation = Permutation(cycle: [2, 0, 4, 1, 3])
        permutation.removeSubrange(0..<3)
        #expect(permutation.cycle == [1, 0])
    }

    @Test func replaceSubrangeMatchesRemoveThenInsert() {
        var replaced: Permutation = Permutation(cycle: [2, 0, 4, 1, 3])
        replaced.replaceSubrange(1..<3, withCount: 3)
        var removedThenInserted: Permutation = Permutation(cycle: [2, 0, 4, 1, 3])
        removedThenInserted.removeSubrange(1..<3)
        removedThenInserted.insert(count: 3, at: 1)
        #expect(replaced == removedThenInserted)
    }

    @Test func replaceSubrangeWithSameCountOfEmptyRangeLeavesPermutationUnchanged() {
        var permutation: Permutation = Permutation(cycle: [2, 0, 4, 1, 3])
        permutation.replaceSubrange(2..<2, withCount: 0)
        #expect(permutation.cycle == [2, 0, 4, 1, 3])
    }
}
