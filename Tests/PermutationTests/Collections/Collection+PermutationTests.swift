// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Collection+PermutationTests.swift
// dependencies: [Collections/Collection+Permutation.swift, Collections/PermutableCollection.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation.swift, Support/Deck.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

/// A mutable collection without random access, so `apply` must take the path that walks its indices once.
struct Strip: MutableCollection {

    var cards: [String]

    var startIndex: Int { cards.startIndex }

    var endIndex: Int { cards.endIndex }

    subscript(position: Int) -> String {
        get { cards[position] }
        set { cards[position] = newValue }
    }

    func index(after i: Int) -> Int { i + 1 }
}

@Suite struct CollectionPermutationTests {

    /// Random permutations shorter than or as long as the cards, with the reference order from `Deck`, which applies them through `PermutableCollection`'s swaps.
    func cases() -> [(cards: [String], permutation: Permutation, expected: [String])] {
        var generator: SeededGenerator = SeededGenerator(state: 7)
        return (0..<60).map { _ in
            let count: Int = Int.random(in: 0...12, using: &generator)
            let cards: [String] = (0..<count).map { "c\($0)" }
            let permutation: Permutation = Permutation(shuffles: Int.random(in: 0...count, using: &generator), using: &generator)
            var deck: Deck = Deck(cards: cards)
            deck.apply(permutation)
            return (cards, permutation, deck.cards)
        }
    }

    @Test func arrayAppliesInPlaceAndApplyingCopies() {
        for (cards, permutation, expected) in cases() {
            var array: [String] = cards
            array.apply(permutation)
            #expect(array == expected)
            #expect(cards.applying(permutation) == expected)
        }
    }

    @Test func sliceKeepsItsOwnIndices() {
        for (cards, permutation, expected) in cases() {
            let padded: [String] = ["x"] + cards + ["y"]
            var slice: ArraySlice<String> = padded[1..<(padded.count - 1)]
            slice.apply(permutation)
            #expect(Array(slice) == expected)
            #expect(slice.startIndex == 1)
            #expect(Array(padded[1..<(padded.count - 1)].applying(permutation)) == expected)
        }
    }

    @Test func mutableCollectionWithoutRandomAccessWalksItsIndices() {
        for (cards, permutation, expected) in cases() {
            var strip: Strip = Strip(cards: cards)
            strip.apply(permutation)
            #expect(strip.cards == expected)
            #expect(Strip(cards: cards).applying(permutation) == expected)
        }
    }

    @Test func rangeReplaceableCollectionRebuildsOnce() {
        for (cards, permutation, expected) in cases() {
            let text: String = cards.map { String($0.last!) }.joined()
            let reordered: String = expected.map { String($0.last!) }.joined()
            #expect(text.applying(permutation) == reordered)
            var copy: String = text
            copy.apply(permutation)
            #expect(copy == reordered)
        }
    }

    @Test func unsafeBufferAppliesInPlace() {
        for (cards, permutation, expected) in cases() {
            var storage: [String] = cards
            storage.withUnsafeMutableBufferPointer { buffer in buffer.apply(permutation) }
            #expect(storage == expected)
        }
    }

    @Test func identityChangesNothing() {
        var array: [Int] = [3, 1, 2]
        array.apply(Permutation(cycle: []))
        #expect(array == [3, 1, 2])
        #expect("abc".applying(Permutation(cycle: [])) == "abc")
    }
}
