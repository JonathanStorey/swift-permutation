// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableSetTests.swift
// dependencies: [Collections/Offsets.swift, Collections/PermutableCollection.swift, Collections/PermutableSet.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Foundation
import Testing
@testable import Permutation

@Suite struct PermutableSetTests {

    /// Checks that every element finds itself and its position, so the elements, the order and the hash index agree.
    func expectConsistent<Element>(_ set: PermutableSet<Element>) {
        #expect(set.elements.count == set.count)
        #expect(set.offsets.count == set.count)
        #expect(set.offsets.sorted() == Array(set.elements.indices))
        #expect(set.offsets.table.isEmpty ? set.count <= Offsets.linearLimit : set.offsets.table.count { $0 >= 0 } == set.count)
        if set.offsets.isInStorageOrder { #expect(Array(set.offsets) == Array(set.elements.indices)) }
        #expect(Array(set) == set.indices.map { set[$0] })
        for (position, element) in set.enumerated() {
            #expect(set.contains(element))
            #expect(set.firstIndex(of: element) == position)
        }
    }

    // MARK: Building

    @Test func initKeepsTheFirstOfEachRepeat() {
        let set: PermutableSet<String> = PermutableSet(["b", "a", "b", "c", "a"])
        #expect(Array(set) == ["b", "a", "c"])
        expectConsistent(set)
    }

    @Test func arrayLiteralBuildsInOrder() {
        let set: PermutableSet<Int> = [3, 1, 2]
        #expect(Array(set) == [3, 1, 2])
    }

    @Test func appendAndInsertRefuseDuplicates() {
        var set: PermutableSet<Int> = [1, 2]
        let appendedRepeat: Bool = set.append(1)
        let inserted: Bool = set.insert(5, at: 1)
        let insertedRepeat: Bool = set.insert(5, at: 0)
        #expect(!appendedRepeat && inserted && !insertedRepeat)
        #expect(Array(set) == [1, 5, 2])
        let appendedBatch: Bool = set.append(contentsOf: [7, 7])
        let insertedBatch: Bool = set.insert(contentsOf: [8, 9], at: 0)
        #expect(!appendedBatch && insertedBatch)
        #expect(Array(set) == [8, 9, 1, 5, 2])
        expectConsistent(set)
    }

    // MARK: Membership

    @Test func containsAndFirstIndexUseTheHashIndex() {
        var set: PermutableSet<String> = ["x", "y", "z"]
        set.reverse()
        #expect(set.contains("y"))
        #expect(!set.contains("w"))
        #expect(set.firstIndex(of: "x") == 2)
        #expect(set.lastIndex(of: "z") == 0)
        #expect(set.firstIndex(of: "w") == nil)
    }

    @Test func removeReturnsTheElementAndKeepsTheOrder() {
        var set: PermutableSet<Int> = [4, 2, 9, 7]
        let removed: Int? = set.remove(2)
        let removedAgain: Int? = set.remove(2)
        #expect(removed == 2)
        #expect(removedAgain == nil)
        #expect(Array(set) == [4, 9, 7])
        expectConsistent(set)
    }

    @Test func updateReplacesOrInserts() {
        var set: PermutableSet<Int> = [1, 2]
        let replaced: Int? = set.update(orAppend: 2)
        let insertedNew: Int? = set.update(orInsert: 0, at: 0)
        #expect(replaced == 2)
        #expect(insertedNew == nil)
        set.update(orAppend: [3, 1, 4, 3])
        #expect(Array(set) == [0, 1, 2, 3, 4])
        expectConsistent(set)
    }

    // MARK: Reordering

    @Test func reorderingLeavesStorageInPlace() {
        var generator: SeededGenerator = SeededGenerator(state: 21)
        var set: PermutableSet<Int> = PermutableSet(0..<50)
        let stored: [Int] = set.elements
        let permutation: Permutation = set.shuffle(using: &generator)
        #expect(set.elements == stored)
        var expected: [Int] = Array(0..<50)
        expected.apply(permutation)
        #expect(Array(set) == expected)
        set.sort()
        #expect(Array(set) == Array(0..<50))
        expectConsistent(set)
    }

    @Test func storageOrderFastPathTracksReorders() {
        var set: PermutableSet<Int> = PermutableSet(0..<40)
        #expect(set.offsets.isInStorageOrder)
        #expect(set.withContiguousStorageIfAvailable { Array($0) } == Array(0..<40))
        set.append(40)
        #expect(set.offsets.isInStorageOrder)
        set.swapAt(0, 1)
        #expect(!set.offsets.isInStorageOrder)
        #expect(set.withContiguousStorageIfAvailable { _ in true } == nil)
        #expect(Array(set) == [1, 0] + Array(2...40))
        set.removeAll { $0 == 5 }
        #expect(set.offsets.isInStorageOrder)
        #expect(Array(set) == [1, 0] + Array(2...4) + Array(6...40))
        expectConsistent(set)
    }

    // MARK: Set operations

    @Test func unionAppendsNewElementsInTheArgumentsOrder() {
        let set: PermutableSet<Int> = [3, 1, 2]
        #expect(Array(set.union([5, 1, 4, 5])) == [3, 1, 2, 5, 4])
        expectConsistent(set.union([5, 1, 4, 5]))
    }

    @Test func intersectionAndSubtractingKeepTheReceiversOrder() {
        let set: PermutableSet<Int> = [5, 3, 8, 1, 9]
        #expect(Array(set.intersection([1, 9, 5, 42])) == [5, 1, 9])
        #expect(Array(set.subtracting([1, 9, 42])) == [5, 3, 8])
        #expect(set.intersection([Int]()).isEmpty)
        #expect(set.subtracting([Int]()) == set)
        expectConsistent(set.intersection([1, 9, 5, 42]))
        expectConsistent(set.subtracting([1, 9, 42]))
    }

    @Test func symmetricDifferenceKeepsSurvivorsThenAppendsNewOnes() {
        let set: PermutableSet<Int> = [1, 2, 3, 4]
        let result: PermutableSet<Int> = set.symmetricDifference([6, 3, 5, 6, 1])
        #expect(Array(result) == [2, 4, 6, 5])
        expectConsistent(result)
    }

    @Test func setOperationsMatchSetMembership() {
        var generator: SeededGenerator = SeededGenerator(state: 22)
        for _ in 0..<100 {
            let left: [Int] = (0..<Int.random(in: 0...20, using: &generator)).map { _ in Int.random(in: 0..<25, using: &generator) }
            let right: [Int] = (0..<Int.random(in: 0...20, using: &generator)).map { _ in Int.random(in: 0..<25, using: &generator) }
            let set: PermutableSet<Int> = PermutableSet(left)
            let leftSet: Set<Int> = Set(left)
            let rightSet: Set<Int> = Set(right)
            #expect(Set(set.union(right)) == leftSet.union(rightSet))
            #expect(Set(set.intersection(right)) == leftSet.intersection(rightSet))
            #expect(Set(set.subtracting(right)) == leftSet.subtracting(rightSet))
            #expect(Set(set.symmetricDifference(right)) == leftSet.symmetricDifference(rightSet))
            #expect(set.isSubset(of: right) == leftSet.isSubset(of: rightSet))
            #expect(set.isStrictSubset(of: right) == leftSet.isStrictSubset(of: rightSet))
            #expect(set.isSuperset(of: right) == leftSet.isSuperset(of: rightSet))
            #expect(set.isStrictSuperset(of: right) == leftSet.isStrictSuperset(of: rightSet))
            #expect(set.isDisjoint(with: right) == leftSet.isDisjoint(with: rightSet))
            let other: PermutableSet<Int> = PermutableSet(right)
            #expect(Array(set.intersection(other)) == Array(set.intersection(right)))
            #expect(Array(set.subtracting(other)) == Array(set.subtracting(right)))
            #expect(set.isSubset(of: other) == leftSet.isSubset(of: rightSet))
            #expect(set.isStrictSubset(of: other) == leftSet.isStrictSubset(of: rightSet))
            #expect(set.isSuperset(of: other) == leftSet.isSuperset(of: rightSet))
            #expect(set.isStrictSuperset(of: other) == leftSet.isStrictSuperset(of: rightSet))
            #expect(set.isDisjoint(with: other) == leftSet.isDisjoint(with: rightSet))
            #expect(Array(set.intersection(right)) == Array(set).filter(rightSet.contains))
            #expect(Array(set.subtracting(right)) == Array(set).filter { !rightSet.contains($0) })
        }
    }

    // MARK: Conformances

    @Test func equalityRespectsOrder() {
        let set: PermutableSet<Int> = [1, 2, 3]
        #expect(set == [1, 2, 3])
        #expect(set != [3, 2, 1])
        #expect(set.hashValue == PermutableSet([1, 2, 3]).hashValue)
    }

    @Test func codableRoundTripsAndRejectsRepeats() throws {
        let set: PermutableSet<String> = ["b", "a", "c"]
        let data: Data = try JSONEncoder().encode(set)
        #expect(try JSONDecoder().decode(PermutableSet<String>.self, from: data) == set)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PermutableSet<String>.self, from: Data(#"["a","a"]"#.utf8))
        }
    }
}
