// repository: https://github.com/JonathanStorey/swift-permutation
// path: Support/Ledger.swift
// dependencies: [Collections/PermutableCollection.swift, Collections/UpsertableCollection.swift, Support/Player.swift]

@testable import Permutation

/// An upsertable collection whose index is not `Int`, standing in for a store that positions rows by its own key, so the protocol's defaults must work through `Index`.
struct Ledger: UpsertableCollection {

    /// A position wrapped in its own type, so no code can treat it as an `Int`.
    struct Slot: Comparable {
        let offset: Int

        static func < (lhs: Slot, rhs: Slot) -> Bool { lhs.offset < rhs.offset }
    }

    var players: [Player]

    var startIndex: Slot { Slot(offset: 0) }

    var endIndex: Slot { Slot(offset: players.count) }

    subscript(position: Slot) -> Player { players[position.offset] }

    func index(after i: Slot) -> Slot { Slot(offset: i.offset + 1) }

    func index(before i: Slot) -> Slot { Slot(offset: i.offset - 1) }

    func index(_ i: Slot, offsetBy distance: Int) -> Slot { Slot(offset: i.offset + distance) }

    func distance(from start: Slot, to end: Slot) -> Int { end.offset - start.offset }

    mutating func swapAt(_ i: Slot, _ j: Slot) {
        players.swapAt(i.offset, j.offset)
    }

    mutating func insert(_ element: Player, at index: Slot) -> Bool {
        guard !players.contains(where: { $0.id == element.id }) else { return false }
        players.insert(element, at: index.offset)
        return true
    }

    mutating func replace(_ element: Player) -> Player? {
        guard let position: Int = players.firstIndex(where: { $0.id == element.id }) else { return nil }
        defer { players[position] = element }
        return players[position]
    }

    mutating func remove(at index: Slot) -> Player {
        players.remove(at: index.offset)
    }
}
