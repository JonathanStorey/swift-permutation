// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+SortTests.swift
// dependencies: [Collections/Arrangement.swift, Permutation/Permutation+Sort.swift, Permutation/Permutation.swift]

import Testing
@testable import Permutation

@Suite struct PermutationSortTests {

    @Test func sortingGivesThePermutationAndLeavesTheElements() {
        let scores: [Int] = [40, 10, 30, 10, 20]
        let names: [String] = ["ann", "bob", "cy", "dee", "eli"]
        let order: Permutation = Permutation(sorting: scores)
        #expect(scores.applying(order) == [10, 10, 20, 30, 40])
        #expect(names.applying(order) == ["bob", "dee", "eli", "cy", "ann"])
        let descending: Permutation = Permutation(sorting: scores, by: >)
        #expect(scores.applying(descending) == [40, 30, 20, 10, 10])
    }

    @Test func sortingMatchesWhatSortApplies() {
        var cards: Arrangement<Int> = Arrangement([5, 3, 9, 1, 3])
        let order: Permutation = Permutation(sorting: cards)
        let applied: Permutation = cards.sort()
        #expect(order == applied)
        #expect(Permutation(sorting: [1, 2, 3]).cycle.isEmpty)
    }

    @Test func reversingIsPublicAndMatchesReverse() {
        let letters: [String] = ["a", "b", "c", "d", "e"]
        #expect(letters.applying(Permutation(reversing: letters.count)) == ["e", "d", "c", "b", "a"])
    }

    @Test func defaultInitializerIsTheIdentity() {
        let order: Permutation = Permutation(sorting: [3, 1, 2])
        #expect(Permutation().cycle.isEmpty)
        #expect(Permutation().followed(by: order) == order)
        #expect([7, 8, 9].applying(Permutation()) == [7, 8, 9])
    }
}
