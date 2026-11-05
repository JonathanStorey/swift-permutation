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

extension Record {

    /// Records made once, outside any timed region, for benchmarks that add new records.
    static let extras: [Record] = (0..<100).map { Record(rank: -1 - $0) }

    /// Ids that no benchmark collection contains.
    static let missingIDs: [UUID] = (0..<100).map { _ in UUID() }
}
