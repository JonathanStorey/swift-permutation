// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/OffsetsTests.swift
// dependencies: [Collections/Offsets.swift, Collections/PermutableCollection.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation.swift, Support/Deck.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct OffsetsTests {

    /// A key whose hash only sees its value modulo three, so nearly every key collides and probing does the work.
    struct Clumped: Hashable {

        let value: Int

        func hash(into hasher: inout Hasher) {
            hasher.combine(value % 3)
        }
    }

    /// Checks that the table, the order, and the stored elements agree with each other and with the expected order.
    func expectConsistent<Key: Hashable>(_ offsets: Offsets, _ elements: [Key], order: [Key], absent: [Key]) {
        #expect(offsets.map { elements[$0] } == order)
        #expect(offsets.sorted() == Array(elements.indices))
        #expect(offsets.table.isEmpty || offsets.table.count & (offsets.table.count - 1) == 0)
        #expect(offsets.table.count { $0 >= 0 } == elements.count)
        #expect(elements.count * 4 <= offsets.table.count * 3 || elements.isEmpty)
        for (offset, element) in elements.enumerated() {
            #expect(offsets.offset(of: element, in: elements, by: { $0 }) == offset)
        }
        for key in absent {
            #expect(offsets.offset(of: key, in: elements, by: { $0 }) == nil)
        }
    }

    @Test func emptyOffsetsFindNothing() {
        let offsets: Offsets = Offsets()
        #expect(offsets.isEmpty)
        #expect(offsets.offset(of: 1, in: [Int](), by: { $0 }) == nil)
    }

    @Test func insertRejectsADuplicateKey() {
        var offsets: Offsets = Offsets()
        var elements: [String] = []
        #expect(offsets.insert("a", at: 0, into: &elements, by: { $0 }))
        #expect(offsets.insert("b", at: 0, into: &elements, by: { $0 }))
        #expect(!offsets.insert("a", at: 2, into: &elements, by: { $0 }))
        expectConsistent(offsets, elements, order: ["b", "a"], absent: ["c"])
    }

    @Test func growthKeepsEveryElementFindable() {
        var offsets: Offsets = Offsets()
        var elements: [Int] = []
        for value in 0..<10_000 {
            #expect(offsets.insert(value, at: offsets.count, into: &elements, by: { $0 }))
        }
        expectConsistent(offsets, elements, order: Array(0..<10_000), absent: [-1, 10_000])
    }

    @Test func applyMatchesTheSwapBasedDefault() {
        var generator: SeededGenerator = SeededGenerator(state: 5)
        for count in 0..<40 {
            var offsets: Offsets = Offsets()
            var elements: [String] = []
            for value in 0..<count { _ = offsets.insert(String(value), at: value, into: &elements, by: { $0 }) }
            let permutation: Permutation = Permutation(shuffles: count, using: &generator)
            let table: [Int32] = offsets.table
            offsets.apply(permutation)
            var deck: Deck = Deck(cards: elements)
            deck.apply(permutation)
            #expect(offsets.map { elements[$0] } == deck.cards)
            #expect(offsets.table == table)
        }
    }

    @Test func replaceReindexesAChangedKey() {
        var offsets: Offsets = Offsets()
        var elements: [Clumped] = []
        for value in 0..<6 { _ = offsets.insert(Clumped(value: value), at: value, into: &elements, by: { $0 }) }
        let old: Clumped = offsets.replace(offset: 2, with: Clumped(value: 20), in: &elements, by: { $0 })
        #expect(old == Clumped(value: 2))
        let order: [Clumped] = [0, 1, 20, 3, 4, 5].map(Clumped.init(value:))
        expectConsistent(offsets, elements, order: order, absent: [Clumped(value: 2)])
    }

    @Test func randomEditsWithCollidingKeysMatchAPlainArray() {
        var generator: SeededGenerator = SeededGenerator(state: 99)
        var offsets: Offsets = Offsets()
        var elements: [Clumped] = []
        var model: [Clumped] = []
        let keys: [Clumped] = (0..<60).map(Clumped.init(value:))
        for _ in 0..<3_000 {
            let key: Clumped = keys.randomElement(using: &generator)!
            switch Int.random(in: 0..<10, using: &generator) {
            case 0..<5:
                let position: Int = Int.random(in: 0...model.count, using: &generator)
                let added: Bool = offsets.insert(key, at: position, into: &elements, by: { $0 })
                #expect(added == !model.contains(key))
                if added { model.insert(key, at: position) }
            case 5..<8:
                guard !model.isEmpty else { continue }
                let position: Int = Int.random(in: 0..<model.count, using: &generator)
                let removed: Clumped = offsets.remove(at: position, from: &elements, by: { $0 })
                #expect(removed == model.remove(at: position))
            case 8:
                guard !model.isEmpty, !model.contains(key) else { continue }
                let position: Int = Int.random(in: 0..<model.count, using: &generator)
                let old: Clumped = offsets.replace(offset: offsets[position], with: key, in: &elements, by: { $0 })
                #expect(old == model[position])
                model[position] = key
            default:
                let permutation: Permutation = offsets.shuffle(using: &generator)
                var deck: Deck = Deck(cards: model.map { String($0.value) })
                deck.apply(permutation)
                model = deck.cards.map { Clumped(value: Int($0)!) }
            }
            #expect(offsets.map { elements[$0] } == model)
        }
        expectConsistent(offsets, elements, order: model, absent: keys.filter { !model.contains($0) })
    }
}
