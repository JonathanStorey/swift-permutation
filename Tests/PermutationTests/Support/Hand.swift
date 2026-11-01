// repository: https://github.com/JonathanStorey/swift-permutation
// path: Support/Hand.swift
// dependencies: [PermutableCollection.swift]

@testable import Permutation

struct Hand: PermutableCollection, RandomAccessCollection {

    var cards: [String]

    var endIndex: Int { cards.endIndex }

    var startIndex: Int { cards.startIndex }

    subscript(position: Int) -> String { cards[position] }

    mutating func swapAt(_ i: Int, _ j: Int) {
        cards.swapAt(i, j)
    }
}
