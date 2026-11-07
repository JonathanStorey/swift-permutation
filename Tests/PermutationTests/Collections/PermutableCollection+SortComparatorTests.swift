// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection+SortComparatorTests.swift
// dependencies: [Collections/Collection+PermutationTests.swift, Collections/IdentifiedSet.swift, Collections/PermutableCollection+SortComparator.swift, Permutation/Permutation.swift, Support/Player.swift]

import Foundation
import Testing
@testable import Permutation

@Suite struct PermutableCollectionSortComparatorTests {

    let players: [Player] = [
        Player(id: 1, name: "cy"),
        Player(id: 2, name: "ann"),
        Player(id: 3, name: "bob"),
        Player(id: 4, name: "ann"),
    ]

    @Test func sortDescriptorSortsAndReturnsThePermutation() {
        var roster: IdentifiedSet<Player> = IdentifiedSet(players)
        let order: Permutation = roster.sort(using: SortDescriptor(\Player.name))
        #expect(roster.map(\.id) == [2, 4, 3, 1])
        #expect(players.applying(order).map(\.id) == [2, 4, 3, 1])
        roster.apply(order.inverted)
        #expect(roster.map(\.id) == [1, 2, 3, 4])
    }

    @Test func laterDescriptorsBreakTies() {
        var roster: IdentifiedSet<Player> = IdentifiedSet(players)
        roster.sort(using: [SortDescriptor(\Player.name), SortDescriptor(\Player.id, order: .reverse)])
        #expect(roster.map(\.id) == [4, 2, 3, 1])
    }

    @Test func keyPathComparatorWorksToo() {
        var roster: IdentifiedSet<Player> = IdentifiedSet(players)
        roster.sort(using: KeyPathComparator(\Player.id, order: .reverse))
        #expect(roster.map(\.id) == [4, 3, 2, 1])
    }

    @Test func permutationSortingUsingLeavesTheElements() {
        let byName: Permutation = Permutation(sorting: players, using: SortDescriptor(\Player.name))
        #expect(players.applying(byName).map(\.id) == [2, 4, 3, 1])
        let byNameThenId: Permutation = Permutation(sorting: players, using: [SortDescriptor(\Player.name), SortDescriptor(\Player.id, order: .reverse)])
        #expect(players.applying(byNameThenId).map(\.id) == [4, 2, 3, 1])
    }

    @Test func mutableCollectionKeepsFoundationsSortUntilAskedForThePermutation() {
        var tiles: Tiles = Tiles(values: [3, 1, 2])
        tiles.sort(using: KeyPathComparator(\Int.self))
        #expect(tiles.values == [1, 2, 3])
        var requested: Tiles = Tiles(values: [3, 1, 2])
        let order: Permutation = requested.sort(using: [KeyPathComparator(\Int.self, order: .reverse)])
        #expect(requested.values == [3, 2, 1])
        #expect([3, 1, 2].applying(order) == [3, 2, 1])
    }
}
