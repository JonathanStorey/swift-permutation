// repository: https://github.com/JonathanStorey/swift-permutation
// path: Support/Deck.swift
// dependencies: [PermutableCollection.swift, Permutation+Shuffleable.swift]

@testable import Permutation

struct Deck: PermutableCollection {

    var cards: [String]

    var endIndex: Int { cards.endIndex }

    var startIndex: Int { cards.startIndex }

    subscript(position: Int) -> String { cards[position] }

    func index(after i: Int) -> Int {
        cards.index(after: i)
    }

    mutating func swapAt(_ i: Int, _ j: Int) {
        cards.swapAt(i, j)
    }
}

/// Fails to compile if the `PermutableCollection` shuffling API stops matching `Shuffleable`.
extension Deck: Shuffleable {}
