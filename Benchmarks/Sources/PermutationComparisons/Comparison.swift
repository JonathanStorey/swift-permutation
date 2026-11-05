// repository: https://github.com/JonathanStorey/swift-permutation
// path: Comparison.swift
// dependencies: [Collections/PermutableCollection.swift]

import Permutation

/// One reordering written three ways: through `PermutableCollection`, through `MutableCollection`, and through `RangeReplaceableCollection`.
struct Comparison {

    let operation: String
    let permutable: (inout Cards) -> Void
    let mutable: ((inout [Int]) -> Void)?
    let rangeReplaceable: ((inout [Int]) -> Void)?
    let mutableMatches: Bool

    init(_ operation: String, mutableMatches: Bool = true, permutable: @escaping (inout Cards) -> Void, mutable: ((inout [Int]) -> Void)?, rangeReplaceable: ((inout [Int]) -> Void)?) {
        self.operation = operation
        self.permutable = permutable
        self.mutable = mutable
        self.rangeReplaceable = rangeReplaceable
        self.mutableMatches = mutableMatches
    }

    static var all: [Comparison] {
        [
            Comparison("move(from:to:)", permutable: { cards in
                let last: Int = cards.index(before: cards.endIndex)
                cards.move(from: cards.startIndex, to: last)
            }, mutable: { array in
                for offset in 0..<(array.count - 1) {
                    array.swapAt(offset, offset + 1)
                }
            }, rangeReplaceable: { array in
                let element: Int = array.remove(at: 0)
                array.insert(element, at: array.count)
            }),
            Comparison("move(fromOffsets:toOffset:)", permutable: { cards in
                let destination: Int = cards.count / 2
                cards.move(fromOffsets: stride(from: 0, to: cards.count, by: 10), toOffset: destination)
            }, mutable: nil, rangeReplaceable: { array in
                let destination: Int = array.count / 2
                let moved: [Int] = stride(from: 0, to: array.count, by: 10).map { array[$0] }
                var offset: Int = 0
                array.removeAll { _ in
                    defer { offset += 1 }
                    return offset.isMultiple(of: 10)
                }
                array.insert(contentsOf: moved, at: destination - (destination + 9) / 10)
            }),
            Comparison("stablePartition(by:)", mutableMatches: false, permutable: { cards in
                cards.stablePartition { element in element.isMultiple(of: 2) }
            }, mutable: { array in
                _ = array.partition { element in element.isMultiple(of: 2) }
            }, rangeReplaceable: { array in
                let second: [Int] = array.filter { element in element.isMultiple(of: 2) }
                array.removeAll { element in element.isMultiple(of: 2) }
                array.append(contentsOf: second)
            }),
            Comparison("reverse()", permutable: { cards in
                cards.reverse()
            }, mutable: { array in
                array.reverse()
            }, rangeReplaceable: { array in
                let reversed: [Int] = array.reversed()
                array.replaceSubrange(array.startIndex..<array.endIndex, with: reversed)
            }),
            Comparison("rotate(toStartAt:)", permutable: { cards in
                let newStart: Int = cards.count / 3
                cards.rotate(toStartAt: newStart)
            }, mutable: { array in
                let pivot: Int = array.count / 3
                array[..<pivot].reverse()
                array[pivot...].reverse()
                array.reverse()
            }, rangeReplaceable: { array in
                let pivot: Int = array.count / 3
                let head: [Int] = Array(array[..<pivot])
                array.removeSubrange(..<pivot)
                array.append(contentsOf: head)
            }),
            Comparison("shuffle(using:)", permutable: { cards in
                var generator: SeededGenerator = SeededGenerator(state: 7)
                cards.shuffle(using: &generator)
            }, mutable: { array in
                var generator: SeededGenerator = SeededGenerator(state: 7)
                array.shuffle(using: &generator)
            }, rangeReplaceable: nil),
            Comparison("sort()", permutable: { cards in
                cards.sort()
            }, mutable: { array in
                array.sort()
            }, rangeReplaceable: nil),
        ]
    }
}
