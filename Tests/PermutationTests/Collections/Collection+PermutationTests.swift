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

/// A permutable collection that is also mutable with random access, so the standard library's in-place reorders and the permutation-returning ones meet.
struct Tiles: MutableCollection, RandomAccessCollection, PermutableCollection {

    var values: [Int]

    var startIndex: Int { values.startIndex }

    var endIndex: Int { values.endIndex }

    subscript(position: Int) -> Int {
        get { values[position] }
        set { values[position] = newValue }
    }
}

/// A permutable collection that is mutable but only walks forward.
struct Chain: MutableCollection, PermutableCollection {

    var values: [Int]

    var startIndex: Int { values.startIndex }

    var endIndex: Int { values.endIndex }

    subscript(position: Int) -> Int {
        get { values[position] }
        set { values[position] = newValue }
    }

    func index(after i: Int) -> Int { i + 1 }
}

/// A permutable collection that is mutable, random access and range replaceable, like a wrapped array.
struct Rack: MutableCollection, RandomAccessCollection, RangeReplaceableCollection, PermutableCollection {

    var values: [Int]

    init() { values = [] }

    init(values: [Int]) { self.values = values }

    var startIndex: Int { values.startIndex }

    var endIndex: Int { values.endIndex }

    subscript(position: Int) -> Int {
        get { values[position] }
        set { values[position] = newValue }
    }

    mutating func replaceSubrange(_ subrange: Range<Int>, with newElements: some Collection<Int>) {
        values.replaceSubrange(subrange, with: newElements)
    }
}

/// A permutable collection that is range replaceable but not mutable, so it reorders only through its own swaps.
struct Line: RandomAccessCollection, RangeReplaceableCollection, PermutableCollection {

    private(set) var values: [Int]

    init() { values = [] }

    init(values: [Int]) { self.values = values }

    var startIndex: Int { values.startIndex }

    var endIndex: Int { values.endIndex }

    subscript(position: Int) -> Int { values[position] }

    mutating func replaceSubrange(_ subrange: Range<Int>, with newElements: some Collection<Int>) {
        values.replaceSubrange(subrange, with: newElements)
    }

    mutating func swapAt(_ i: Int, _ j: Int) {
        values.swapAt(i, j)
    }
}

@Suite struct PermutableAndStandardTests {

    /// Random permutations of up to twelve values, with the order an array gives for each.
    func cases() -> [(values: [Int], permutation: Permutation, expected: [Int])] {
        var generator: SeededGenerator = SeededGenerator(state: 11)
        return (0..<60).map { _ in
            let count: Int = Int.random(in: 0...12, using: &generator)
            let values: [Int] = Array(0..<count)
            let permutation: Permutation = Permutation(shuffles: Int.random(in: 0...count, using: &generator), using: &generator)
            return (values, permutation, values.applying(permutation))
        }
    }

    @Test func everyCombinationAppliesLikeAnArray() {
        for (values, permutation, expected) in cases() {
            var tiles: Tiles = Tiles(values: values)
            tiles.apply(permutation)
            #expect(tiles.values == expected)
            #expect(Tiles(values: values).applying(permutation).values == expected)
            var chain: Chain = Chain(values: values)
            chain.apply(permutation)
            #expect(chain.values == expected)
            var rack: Rack = Rack(values: values)
            rack.apply(permutation)
            #expect(rack.values == expected)
            #expect(Rack(values: values).applying(permutation).values == expected)
            var line: Line = Line(values: values)
            line.apply(permutation)
            #expect(line.values == expected)
            #expect(Line(values: values).applying(permutation).values == expected)
        }
    }

    @Test func mutableReordersRunInPlaceUnlessAPermutationIsRequested() {
        let values: [Int] = [3, 1, 4, 1, 5, 9, 2, 6]
        var tiles: Tiles = Tiles(values: values)
        tiles.sort()
        #expect(tiles.values == values.sorted())
        tiles.sort(by: >)
        #expect(tiles.values == values.sorted(by: >))
        tiles.reverse()
        #expect(tiles.values == values.sorted())

        var requested: Tiles = Tiles(values: values)
        let sorting: Permutation = requested.sort()
        #expect(requested.values == values.sorted())
        #expect(values.applying(sorting) == values.sorted())
        let reversing: Permutation = requested.reverse()
        #expect(requested.values == values.sorted(by: >))
        #expect(reversing == Permutation(reversing: values.count))
        let descending: Permutation = requested.sort(by: <)
        #expect(requested.values == values.sorted())
        #expect(values.sorted(by: >).applying(descending) == values.sorted())
    }

    @Test func mutablePartitionSplitsInPlace() {
        let values: [Int] = [3, 8, 1, 6, 4, 9, 2]
        var tiles: Tiles = Tiles(values: values)
        let tilesBoundary: Int = tiles.partition { $0 > 4 }
        #expect(tiles.values[..<tilesBoundary].allSatisfy { $0 <= 4 })
        #expect(tiles.values[tilesBoundary...].allSatisfy { $0 > 4 })
        #expect(tiles.values.sorted() == values.sorted())
        var chain: Chain = Chain(values: values)
        let chainBoundary: Int = chain.partition { $0 > 4 }
        #expect(chainBoundary == 4)
        #expect(chain.values[..<chainBoundary].allSatisfy { $0 <= 4 })
        #expect(chain.values[chainBoundary...].allSatisfy { $0 > 4 })
        var empty: Chain = Chain(values: [1, 2])
        #expect(empty.partition { $0 > 4 } == 2)
    }
}
