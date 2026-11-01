// repository: https://github.com/JonathanStorey/swift-permutation
// path: Cards.swift
// dependencies: [PermutableCollection.swift]

import Permutation

/// An array-backed collection that reorders its elements only through `PermutableCollection`.
struct Cards: PermutableCollection, RandomAccessCollection {

    var elements: [Int]

    var endIndex: Int { elements.endIndex }

    var startIndex: Int { elements.startIndex }

    subscript(position: Int) -> Int { elements[position] }

    mutating func swapAt(_ i: Int, _ j: Int) {
        elements.swapAt(i, j)
    }
}
