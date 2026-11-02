// repository: https://github.com/JonathanStorey/swift-permutation
// path: Record.swift
// dependencies: []

import Foundation

/// A typical app model: a UUID id, a sort key, and 64 bytes of other fields.
struct Record: Identifiable {

    let id: UUID

    var rank: Int

    var payload: SIMD8<Int64>
}
