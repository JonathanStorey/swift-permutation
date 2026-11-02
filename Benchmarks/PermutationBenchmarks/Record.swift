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
