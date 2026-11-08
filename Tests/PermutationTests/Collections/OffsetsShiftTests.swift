// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/OffsetsShiftTests.swift
// dependencies: [Collections/Arrangement.swift, Collections/Offsets.swift, Collections/PermutableDictionary.swift, Collections/PermutableSet.swift, Permutation/Permutation+Moves.swift]

import Testing
@testable import Permutation

/// The block-copy path for single moves must give exactly what the cycle walk gives.
@Suite struct OffsetsShiftTests {

    /// The order an array gives for the same move.
    func moved(_ values: [Int], from source: Int, to destination: Int) -> [Int] {
        var result: [Int] = values
        result.insert(result.remove(at: source), at: destination)
        return result
    }

    @Test func everyMoveMatchesAnArray() {
        let count: Int = 7
        let values: [Int] = Array(100..<(100 + count))
        for source in 0..<count {
            for destination in 0..<count {
                let expected: [Int] = moved(values, from: source, to: destination)
                var arrangement: Arrangement<Int> = Arrangement(values)
                let permutation: Permutation = arrangement.move(from: source, to: destination)
                #expect(Array(arrangement) == expected)
                var set: PermutableSet<Int> = PermutableSet(values)
                set.move(from: source, to: destination)
                #expect(Array(set) == expected)
                var dictionary: PermutableDictionary<Int, String> = PermutableDictionary(uniqueKeysWithValues: values.map { ($0, "\($0)") })
                dictionary.move(from: source, to: destination)
                #expect(Array(dictionary.keys) == expected)
                #expect(values.applying(permutation) == expected)
                arrangement.apply(permutation.inverted)
                #expect(Array(arrangement) == values)
            }
        }
    }

    @Test func singleOffsetMovesMatchSwiftUIsInsertBeforeRule() {
        let count: Int = 6
        let values: [Int] = Array(0..<count)
        for source in 0..<count {
            for destination in 0...count {
                var expected: [Int] = values
                let element: Int = expected.remove(at: source)
                expected.insert(element, at: destination > source ? destination - 1 : destination)
                var arrangement: Arrangement<Int> = Arrangement(values)
                let permutation: Permutation = arrangement.move(fromOffsets: [source], toOffset: destination)
                #expect(Array(arrangement) == expected)
                #expect(values.applying(permutation) == expected)
                var set: PermutableSet<Int> = PermutableSet(values)
                set.move(fromOffsets: [source, source], toOffset: destination)
                #expect(Array(set) == expected)
            }
        }
    }

    @Test func movesAfterOtherReordersShiftTheCurrentOrder() {
        var arrangement: Arrangement<Int> = Arrangement(0..<50)
        arrangement.reverse()
        var mirror: [Int] = Array(arrangement)
        for (source, destination) in [(0, 49), (49, 0), (10, 30), (30, 10), (5, 6), (6, 5), (20, 20)] {
            arrangement.move(from: source, to: destination)
            mirror = moved(mirror, from: source, to: destination)
            #expect(Array(arrangement) == mirror)
        }
    }

    @Test func nearMissesTakeTheCycleWalk() {
        let lines: [[Int]] = [
            [5, 4, 3, 1], [4, 3, 2, 0, 1], [6, 1, 2, 3, 4], [5, 2, 3, 5 - 1, 0], [6, 2, 3, 4, 5, 1],
            [3, 2, 1, 0], [3, 0, 1, 2], [9, 8, 7], [9, 7, 8], [4, 3], [8, 2, 3, 4, 5, 6, 7, 1, 0],
        ]
        let values: [Int] = Array(0..<10)
        for line in lines {
            let permutation: Permutation = Permutation(cycle: line)
            var arrangement: Arrangement<Int> = Arrangement(values)
            arrangement.apply(permutation)
            #expect(Array(arrangement) == values.applying(permutation), "line \(line)")
        }
    }
}
