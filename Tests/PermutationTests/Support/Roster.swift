// repository: https://github.com/JonathanStorey/swift-permutation
// path: Support/Roster.swift
// dependencies: [Collections/PermutableCollection.swift, Collections/UpsertableCollection.swift, Support/Player.swift]

@testable import Permutation

/// The smallest upsertable collection: players in an array, matched by id with a linear search, so every other operation comes from the protocol's defaults.
struct Roster: UpsertableCollection {

    var players: [Player]

    var startIndex: Int { players.startIndex }

    var endIndex: Int { players.endIndex }

    subscript(position: Int) -> Player { players[position] }

    mutating func swapAt(_ i: Int, _ j: Int) {
        players.swapAt(i, j)
    }

    mutating func insert(_ element: Player, at index: Int) -> Bool {
        guard !players.contains(where: { $0.id == element.id }) else { return false }
        players.insert(element, at: index)
        return true
    }

    mutating func replace(_ element: Player) -> Player? {
        guard let position: Int = players.firstIndex(where: { $0.id == element.id }) else { return nil }
        defer { players[position] = element }
        return players[position]
    }

    mutating func remove(at index: Int) -> Player {
        players.remove(at: index)
    }
}
