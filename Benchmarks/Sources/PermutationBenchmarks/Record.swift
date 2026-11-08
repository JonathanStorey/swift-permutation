// repository: https://github.com/JonathanStorey/swift-permutation
// path: Record.swift
// dependencies: []

import Foundation

/// A typical app model: a UUID id, a sort key, and 64 bytes of other fields.
struct Record: Identifiable {

    let id: UUID

    var rank: Int

    var payload: SIMD8<Int64>

    /// Creates a record with a fresh id and a payload filled from its rank.
    init(rank: Int) {
        id = UUID()
        self.rank = rank
        payload = SIMD8(repeating: Int64(rank))
    }
}

/// Records are equal when their ids are, as an app model's identity usually is, so sets and dictionaries hash them by id.
extension Record: Hashable {

    static func == (lhs: Record, rhs: Record) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Records sort by rank, so `sort()` works on every collection that holds them.
extension Record: Comparable {

    static func < (lhs: Record, rhs: Record) -> Bool {
        lhs.rank < rhs.rank
    }
}
