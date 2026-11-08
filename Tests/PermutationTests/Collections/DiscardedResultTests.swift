// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/DiscardedResultTests.swift
// dependencies: [Collections/PermutableCollection+DiscardedResult.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

/// A reorder whose result is discarded rewrites the offsets directly, and must leave the same order as the version that returns the permutation.
@Suite struct DiscardedResultTests {

    struct Item: Identifiable, Hashable, Comparable {
        let id: Int
        let rank: Int
        static func < (lhs: Item, rhs: Item) -> Bool { lhs.rank < rhs.rank }
    }

    /// Runs the same reorder both ways on fresh and already reordered copies, and checks the orders match.
    func check<C: PermutableCollection & Equatable>(_ make: () -> C, _ discarded: (inout C) -> Void, _ returned: (inout C) -> Permutation, _ label: String) {
        for prepared in [false, true] {
            var lhs: C = make()
            var rhs: C = make()
            if prepared {
                let _: Permutation = lhs.reverse()
                let _: Permutation = rhs.reverse()
            }
            discarded(&lhs)
            let permutation: Permutation = returned(&rhs)
            #expect(lhs == rhs, "\(label), prepared: \(prepared)")
            var replayed: C = make()
            if prepared { let _: Permutation = replayed.reverse() }
            replayed.apply(permutation)
            #expect(replayed == rhs, "\(label) permutation, prepared: \(prepared)")
        }
    }

    let items: [Item] = (0..<10).map { Item(id: $0, rank: ($0 * 7) % 10) }

    // The closures name the concrete type, so the calls that discard their result resolve to the versions that return nothing.
    @Test func arrangementMatches() {
        let make: () -> Arrangement<Item> = { Arrangement(items) }
        check(make, { (c: inout Arrangement<Item>) in c.move(from: 1, to: 7) }, { $0.move(from: 1, to: 7) }, "move up")
        check(make, { (c: inout Arrangement<Item>) in c.move(from: 8, to: 2) }, { $0.move(from: 8, to: 2) }, "move down")
        for source in [0, 4, 9] {
            for destination in [0, 3, 10] {
                check(make, { (c: inout Arrangement<Item>) in c.move(fromOffsets: [source], toOffset: destination) }, { $0.move(fromOffsets: [source], toOffset: destination) }, "move offset \(source) to \(destination)")
            }
        }
        check(make, { (c: inout Arrangement<Item>) in c.move(fromOffsets: [1, 5, 6], toOffset: 9) }, { $0.move(fromOffsets: [1, 5, 6], toOffset: 9) }, "move offsets")
        check(make, { (c: inout Arrangement<Item>) in c.reverse() }, { $0.reverse() }, "reverse")
        for start in [0, 3, 10] {
            check(make, { (c: inout Arrangement<Item>) in c.rotate(toStartAt: start) }, { $0.rotate(toStartAt: start) }, "rotate \(start)")
        }
        check(make, { (c: inout Arrangement<Item>) in var g: SeededGenerator = SeededGenerator(state: 5); c.shuffle(using: &g) }, { var g: SeededGenerator = SeededGenerator(state: 5); return $0.shuffle(using: &g) }, "shuffle")
        check(make, { (c: inout Arrangement<Item>) in c.sort() }, { $0.sort() }, "sort")
    }

    // The closures name the concrete type, so the calls that discard their result resolve to the versions that return nothing.
    @Test func permutableSetMatches() {
        let make: () -> PermutableSet<Item> = { PermutableSet(items) }
        check(make, { (c: inout PermutableSet<Item>) in c.move(from: 1, to: 7) }, { $0.move(from: 1, to: 7) }, "move up")
        check(make, { (c: inout PermutableSet<Item>) in c.move(from: 8, to: 2) }, { $0.move(from: 8, to: 2) }, "move down")
        for source in [0, 4, 9] {
            for destination in [0, 3, 10] {
                check(make, { (c: inout PermutableSet<Item>) in c.move(fromOffsets: [source], toOffset: destination) }, { $0.move(fromOffsets: [source], toOffset: destination) }, "move offset \(source) to \(destination)")
            }
        }
        check(make, { (c: inout PermutableSet<Item>) in c.move(fromOffsets: [1, 5, 6], toOffset: 9) }, { $0.move(fromOffsets: [1, 5, 6], toOffset: 9) }, "move offsets")
        check(make, { (c: inout PermutableSet<Item>) in c.reverse() }, { $0.reverse() }, "reverse")
        for start in [0, 3, 10] {
            check(make, { (c: inout PermutableSet<Item>) in c.rotate(toStartAt: start) }, { $0.rotate(toStartAt: start) }, "rotate \(start)")
        }
        check(make, { (c: inout PermutableSet<Item>) in var g: SeededGenerator = SeededGenerator(state: 5); c.shuffle(using: &g) }, { var g: SeededGenerator = SeededGenerator(state: 5); return $0.shuffle(using: &g) }, "shuffle")
        check(make, { (c: inout PermutableSet<Item>) in c.sort() }, { $0.sort() }, "sort")
    }

    // The closures name the concrete type, so the calls that discard their result resolve to the versions that return nothing.
    @Test func identifiedSetMatches() {
        let make: () -> IdentifiedSet<Item> = { IdentifiedSet(items) }
        check(make, { (c: inout IdentifiedSet<Item>) in c.move(from: 1, to: 7) }, { $0.move(from: 1, to: 7) }, "move up")
        check(make, { (c: inout IdentifiedSet<Item>) in c.move(from: 8, to: 2) }, { $0.move(from: 8, to: 2) }, "move down")
        for source in [0, 4, 9] {
            for destination in [0, 3, 10] {
                check(make, { (c: inout IdentifiedSet<Item>) in c.move(fromOffsets: [source], toOffset: destination) }, { $0.move(fromOffsets: [source], toOffset: destination) }, "move offset \(source) to \(destination)")
            }
        }
        check(make, { (c: inout IdentifiedSet<Item>) in c.move(fromOffsets: [1, 5, 6], toOffset: 9) }, { $0.move(fromOffsets: [1, 5, 6], toOffset: 9) }, "move offsets")
        check(make, { (c: inout IdentifiedSet<Item>) in c.reverse() }, { $0.reverse() }, "reverse")
        for start in [0, 3, 10] {
            check(make, { (c: inout IdentifiedSet<Item>) in c.rotate(toStartAt: start) }, { $0.rotate(toStartAt: start) }, "rotate \(start)")
        }
        check(make, { (c: inout IdentifiedSet<Item>) in var g: SeededGenerator = SeededGenerator(state: 5); c.shuffle(using: &g) }, { var g: SeededGenerator = SeededGenerator(state: 5); return $0.shuffle(using: &g) }, "shuffle")
        check(make, { (c: inout IdentifiedSet<Item>) in c.sort { $0.rank < $1.rank } }, { $0.sort { $0.rank < $1.rank } }, "sort")
    }

    // The closures name the concrete type, so the calls that discard their result resolve to the versions that return nothing.
    @Test func permutableDictionaryMatches() {
        let make: () -> PermutableDictionary<Int, Int> = { PermutableDictionary(uniqueKeys: items.map(\.id), values: items.map(\.rank)) }
        check(make, { (c: inout PermutableDictionary<Int, Int>) in c.move(from: 1, to: 7) }, { $0.move(from: 1, to: 7) }, "move up")
        check(make, { (c: inout PermutableDictionary<Int, Int>) in c.move(from: 8, to: 2) }, { $0.move(from: 8, to: 2) }, "move down")
        for source in [0, 4, 9] {
            for destination in [0, 3, 10] {
                check(make, { (c: inout PermutableDictionary<Int, Int>) in c.move(fromOffsets: [source], toOffset: destination) }, { $0.move(fromOffsets: [source], toOffset: destination) }, "move offset \(source) to \(destination)")
            }
        }
        check(make, { (c: inout PermutableDictionary<Int, Int>) in c.move(fromOffsets: [1, 5, 6], toOffset: 9) }, { $0.move(fromOffsets: [1, 5, 6], toOffset: 9) }, "move offsets")
        check(make, { (c: inout PermutableDictionary<Int, Int>) in c.reverse() }, { $0.reverse() }, "reverse")
        for start in [0, 3, 10] {
            check(make, { (c: inout PermutableDictionary<Int, Int>) in c.rotate(toStartAt: start) }, { $0.rotate(toStartAt: start) }, "rotate \(start)")
        }
        check(make, { (c: inout PermutableDictionary<Int, Int>) in var g: SeededGenerator = SeededGenerator(state: 5); c.shuffle(using: &g) }, { var g: SeededGenerator = SeededGenerator(state: 5); return $0.shuffle(using: &g) }, "shuffle")
        check(make, { (c: inout PermutableDictionary<Int, Int>) in c.sort { $0.value < $1.value } }, { $0.sort { $0.value < $1.value } }, "sort")
    }

    @Test func shuffleMatchesAnArrayShuffledWithTheSameGenerator() {
        var set: PermutableSet<Item> = PermutableSet(items)
        var array: [Item] = items
        var first: SeededGenerator = SeededGenerator(state: 9)
        var second: SeededGenerator = SeededGenerator(state: 9)
        set.shuffle(using: &first)
        array.shuffle(using: &second)
        #expect(Array(set) == array)
    }

    @Test func iterationReadsStorageAndReorderedOrder() {
        var arrangement: Arrangement<Item> = Arrangement(items)
        #expect(Array(arrangement) == items)
        arrangement.reverse()
        #expect(Array(arrangement) == items.reversed())
        var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: [1, 2, 3], values: [10, 20, 30])
        #expect(dictionary.map(\.value) == [10, 20, 30])
        dictionary.reverse()
        #expect(dictionary.map(\.key) == [3, 2, 1])
    }
}
