// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableDictionaryTests.swift
// dependencies: [Collections/Arrangement.swift, Collections/Offsets.swift, Collections/PermutableCollection.swift, Collections/PermutableDictionary.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Foundation
import Testing
@testable import Permutation

@Suite struct PermutableDictionaryTests {

    /// Checks that keys, values, the order, the hash index and the value table agree, and that the dictionary matches the expected entries.
    func expectConsistent<Key: Hashable, Value: Equatable>(_ dictionary: PermutableDictionary<Key, Value>, equals expected: [(Key, Value)]? = nil) {
        let count: Int = dictionary.count
        #expect(dictionary.keyStorage.count == count)
        #expect(dictionary.valueStorage.count == count)
        #expect(dictionary.offsets.sorted() == Array(0..<count))
        #expect(dictionary.offsets.table.isEmpty ? count <= Offsets.linearLimit : dictionary.offsets.table.count { $0 >= 0 } == count)
        if dictionary.offsets.isInStorageOrder { #expect(Array(dictionary.offsets) == Array(0..<count)) }
        #expect(dictionary.valueSlots.isEmpty || dictionary.valueSlots.map { Int($0) }.sorted() == Array(0..<count))
        let iterated: [(key: Key, value: Value)] = Array(dictionary)
        #expect(iterated.count == count)
        for (position, entry) in iterated.enumerated() {
            #expect(dictionary[position].key == entry.key)
            #expect(dictionary[position].value == entry.value)
            #expect(dictionary.keys[position] == entry.key)
            #expect(dictionary.values[position] == entry.value)
            #expect(dictionary[entry.key] == entry.value)
            #expect(dictionary.contains(key: entry.key))
            #expect(dictionary.index(forKey: entry.key) == position)
        }
        if let expected {
            #expect(iterated.map { $0.key } == expected.map { $0.0 })
            #expect(iterated.map { $0.value } == expected.map { $0.1 })
        }
    }

    // MARK: Building

    @Test func literalAndInitializersKeepTheOrderGiven() {
        let literal: PermutableDictionary<String, Int> = ["b": 2, "a": 1, "c": 3]
        expectConsistent(literal, equals: [("b", 2), ("a", 1), ("c", 3)])
        let zipped: PermutableDictionary<String, Int> = PermutableDictionary(uniqueKeys: ["x", "y"], values: [9, 8])
        expectConsistent(zipped, equals: [("x", 9), ("y", 8)])
        let large: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeysWithValues: (0..<100).map { ($0, $0 * $0) })
        expectConsistent(large)
        #expect(large[9] == 81)
        #expect(large[100] == nil)
    }

    // MARK: Lookup and update

    @Test func subscriptUpdatesAppendsAndRemoves() {
        var dictionary: PermutableDictionary<String, Int> = ["a": 1, "b": 2]
        dictionary["a"] = 10
        dictionary["c"] = 3
        dictionary["b"] = nil
        expectConsistent(dictionary, equals: [("a", 10), ("c", 3)])
        let old: Int? = dictionary.updateValue(4, forKey: "d", insertingAt: 0)
        let replaced: Int? = dictionary.updateValue(30, forKey: "c", insertingAt: 0)
        #expect(old == nil && replaced == 3)
        expectConsistent(dictionary, equals: [("d", 4), ("a", 10), ("c", 30)])
    }

    @Test func defaultSubscriptEditsInPlace() {
        var counts: PermutableDictionary<Character, Int> = [:]
        for letter in "mississippi" { counts[letter, default: 0] += 1 }
        expectConsistent(counts, equals: [("m", 1), ("i", 4), ("s", 4), ("p", 2)])
        #expect(counts["z", default: 7] == 7)
        #expect(counts["z"] == nil)
    }

    // MARK: Reordering entries

    @Test func reorderingTheDictionaryOrItsKeysKeepsEachKeyWithItsValue() {
        var dictionary: PermutableDictionary<String, Int> = ["c": 3, "a": 1, "b": 2]
        dictionary.keys.sort()
        expectConsistent(dictionary, equals: [("a", 1), ("b", 2), ("c", 3)])
        dictionary.sort { $0.value > $1.value }
        expectConsistent(dictionary, equals: [("c", 3), ("b", 2), ("a", 1)])
        let reversed: Permutation = dictionary.keys.reverse()
        #expect(reversed == Permutation(reversing: 3))
        expectConsistent(dictionary, equals: [("a", 1), ("b", 2), ("c", 3)])
        #expect(dictionary.keyStorage == ["c", "a", "b"])
        #expect(dictionary.valueStorage == [3, 1, 2])
    }

    @Test func assigningWholeKeysMustRearrangeTheSameKeys() {
        var dictionary: PermutableDictionary<Int, String> = PermutableDictionary(uniqueKeysWithValues: (0..<30).map { ($0, "v\($0)") })
        dictionary.keys = Arrangement((0..<30).reversed())
        expectConsistent(dictionary, equals: (0..<30).reversed().map { ($0, "v\($0)") })
        var copy: PermutableDictionary<Int, String> = dictionary
        copy.keys.sort()
        dictionary.keys = copy.keys
        expectConsistent(dictionary, equals: (0..<30).map { ($0, "v\($0)") })
    }

    // MARK: Reordering values

    @Test func sortingValuesSortsTheWholeDictionaryStably() {
        var dictionary: PermutableDictionary<String, Int> = ["a": 3, "b": 1, "c": 2, "d": 1, "e": 3]
        let sorting: Permutation = dictionary.values.sort()
        expectConsistent(dictionary, equals: [("b", 1), ("d", 1), ("c", 2), ("a", 3), ("e", 3)])
        #expect(dictionary.valueStorage == [3, 1, 2, 1, 3])
        #expect(["a", "b", "c", "d", "e"].applying(sorting) == Array(dictionary.keys))
        dictionary.values.reverse()
        expectConsistent(dictionary, equals: [("e", 3), ("a", 3), ("c", 2), ("d", 1), ("b", 1)])
        dictionary.values.swapAt(0, 1)
        expectConsistent(dictionary, equals: [("a", 3), ("e", 3), ("c", 2), ("d", 1), ("b", 1)])
        #expect(dictionary.values.sorted() == [1, 1, 2, 3, 3])
    }

    @Test func reassigningValuesHandsThemAroundWhileKeysStay() {
        var dictionary: PermutableDictionary<String, Int> = ["a": 3, "b": 1, "c": 2]
        dictionary.reassignValues(Permutation(reversing: 3))
        expectConsistent(dictionary, equals: [("a", 2), ("b", 1), ("c", 3)])
        #expect(dictionary.valueStorage == [3, 1, 2])
        dictionary.reassignValues(Permutation(cycle: [1, 0]))
        expectConsistent(dictionary, equals: [("a", 1), ("b", 2), ("c", 3)])
        dictionary.values.sort(by: >)
        expectConsistent(dictionary, equals: [("c", 3), ("b", 2), ("a", 1)])
    }

    @Test func derangedValuesGiveEveryKeySomeoneElsesValue() {
        var generator: SeededGenerator = SeededGenerator(state: 11)
        let names: [String] = ["Ava", "Ben", "Cy", "Dee", "Eli", "Fay", "Gus"]
        var santas: PermutableDictionary<String, String> = PermutableDictionary(uniqueKeys: names, values: names)
        santas.reassignValues(shuffling: .derangement, using: &generator)
        expectConsistent(santas)
        #expect(santas.allSatisfy { $0.key != $0.value })
        #expect(Set(santas.values) == Set(names))
        #expect(Array(santas.keys) == names)
    }

    @Test func valueEditsThroughPositionsLandOnTheRightKey() {
        var dictionary: PermutableDictionary<String, Int> = ["a": 1, "b": 2, "c": 3]
        dictionary.keys.reverse()
        dictionary.reassignValues(Permutation(rotating: 3, by: 1))
        dictionary.values[0] += 100
        expectConsistent(dictionary, equals: [("c", 102), ("b", 1), ("a", 3)])
    }

    @Test func assigningWholeValuesStoresThemInOrder() {
        var dictionary: PermutableDictionary<String, Int> = ["a": 1, "b": 2, "c": 3]
        dictionary.keys.reverse()
        let other: PermutableDictionary<Int, Int> = [7: 70, 8: 80, 9: 90]
        dictionary.values = PermutableDictionary<String, Int>(uniqueKeys: ["x", "y", "z"], values: other.values).values
        expectConsistent(dictionary, equals: [("c", 70), ("b", 80), ("a", 90)])
    }

    // MARK: Removing

    @Test func removingAfterValuesMoveKeepsEveryPairing() {
        var generator: SeededGenerator = SeededGenerator(state: 3)
        var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeysWithValues: (0..<60).map { ($0, $0 + 1000) })
        dictionary.reassignValues(using: &generator)
        dictionary.shuffle(using: &generator)
        var model: [(Int, Int)] = dictionary.map { ($0.key, $0.value) }
        for key in [5, 59, 0, 33, 17, 18, 41] {
            let expected: Int = model.first { $0.0 == key }!.1
            let removed: Int? = dictionary.removeValue(forKey: key)
            #expect(removed == expected)
            model.removeAll { $0.0 == key }
            expectConsistent(dictionary, equals: model)
        }
        let removedAgain: Int? = dictionary.removeValue(forKey: 5)
        #expect(removedAgain == nil)
    }

    @Test func bulkRemovalsCompactInOrder() {
        var dictionary: PermutableDictionary<Int, String> = PermutableDictionary(uniqueKeysWithValues: (0..<40).map { ($0, String($0)) })
        dictionary.reassignValues(Permutation(reversing: 40))
        dictionary.removeAll { $0.key % 3 == 0 }
        var model: [(Int, String)] = (0..<40).map { ($0, String(39 - $0)) }.filter { $0.0 % 3 != 0 }
        expectConsistent(dictionary, equals: model)
        #expect(dictionary.valueSlots.isEmpty)
        dictionary.remove(atOffsets: [0, 2, 4])
        model = model.enumerated().filter { ![0, 2, 4].contains($0.offset) }.map { $0.element }
        expectConsistent(dictionary, equals: model)
        let filtered: PermutableDictionary<Int, String> = dictionary.filter { $0.value.count == 1 }
        expectConsistent(filtered, equals: model.filter { $0.1.count == 1 })
        dictionary.removeAll()
        expectConsistent(dictionary, equals: [])
    }

    @Test func randomOperationsMatchAnArrayModel() {
        var generator: SeededGenerator = SeededGenerator(state: 99)
        var dictionary: PermutableDictionary<Int, Int> = [:]
        var model: [(Int, Int)] = []
        for step in 0..<600 {
            let key: Int = Int.random(in: 0..<40, using: &generator)
            switch Int.random(in: 0..<7, using: &generator) {
            case 0, 1:
                dictionary[key] = step
                if let index: Int = model.firstIndex(where: { $0.0 == key }) { model[index].1 = step } else { model.append((key, step)) }
            case 2:
                dictionary[key] = nil
                model.removeAll { $0.0 == key }
            case 3:
                let permutation: Permutation = dictionary.shuffle(using: &generator)
                model.apply(permutation)
            case 4:
                let permutation: Permutation = dictionary.reassignValues(using: &generator)
                let values: [Int] = model.map { $0.1 }.applying(permutation)
                model = zip(model.map { $0.0 }, values).map { ($0, $1) }
            case 5:
                let index: Int = Int.random(in: 0...model.count, using: &generator)
                if dictionary.updateValue(step, forKey: key, insertingAt: index) == nil {
                    model.insert((key, step), at: index)
                } else {
                    model[model.firstIndex { $0.0 == key }!].1 = step
                }
            default:
                dictionary.removeAll { $0.value % 5 == 0 }
                model.removeAll { $0.1 % 5 == 0 }
            }
            expectConsistent(dictionary, equals: model)
        }
    }

    // MARK: Conformances

    @Test func mapValuesKeepsKeysAndOrder() {
        var dictionary: PermutableDictionary<String, Int> = ["a": 1, "b": 2, "c": 3]
        dictionary.keys.reverse()
        dictionary.reassignValues(Permutation(rotating: 3, by: 1))
        let doubled: PermutableDictionary<String, Int> = dictionary.mapValues { $0 * 2 }
        expectConsistent(doubled, equals: dictionary.map { ($0.key, $0.value * 2) })
    }

    @Test func equalityFollowsEntriesInOrder() {
        var first: PermutableDictionary<String, Int> = ["a": 1, "b": 2]
        let second: PermutableDictionary<String, Int> = ["b": 2, "a": 1]
        #expect(first != second)
        first.reverse()
        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
        var third: PermutableDictionary<String, Int> = ["b": 1, "a": 2]
        third.reassignValues(Permutation(reversing: 2))
        #expect(third == second)
    }

    @Test func codableAlternatesKeysAndValues() throws {
        var dictionary: PermutableDictionary<String, Int> = ["a": 1, "b": 2]
        dictionary.reassignValues(Permutation(reversing: 2))
        let data: Data = try JSONEncoder().encode(dictionary)
        #expect(String(decoding: data, as: UTF8.self) == "[\"a\",2,\"b\",1]")
        let decoded: PermutableDictionary<String, Int> = try JSONDecoder().decode(PermutableDictionary<String, Int>.self, from: data)
        #expect(decoded == dictionary)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(PermutableDictionary<String, Int>.self, from: Data("[\"a\",1,\"a\",2]".utf8)) }
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(PermutableDictionary<String, Int>.self, from: Data("[\"a\",1,\"b\"]".utf8)) }
        #expect(dictionary.description == "[\"a\": 2, \"b\": 1]")
        #expect(PermutableDictionary<String, Int>().description == "[:]")
    }
}
