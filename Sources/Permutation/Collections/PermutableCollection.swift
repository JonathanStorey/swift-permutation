// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection.swift
// dependencies: [Permutation/Permutation+ForEach.swift, Permutation/Permutation+Move.swift, Permutation/Permutation+Reverse.swift, Permutation/Permutation+Rotate.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

/// A collection whose every reorder passes through `apply(_:)`, so overriding that one method lets a conforming type reorder in its own cheapest way, or observe every reorder.
///
/// A conforming type implements `swapAt(_:_:)`, the smallest reorder any collection can offer. The default `apply(_:)` is built from it, so the swaps must keep every index valid. A type that can move a whole cycle at once, such as one that reorders an index rather than its elements, overrides `apply(_:)` as well.
///
/// A type that is also a `MutableCollection` keeps the standard library's in-place `partition`, `sort` and `reverse`, and gets the permutation they applied only by asking for one, as in `let permutation: Permutation = tiles.sort()`.
public protocol PermutableCollection: Collection {

    /// Moves the element at each offset in each cycle to the next offset in that cycle, wrapping from the last offset to the first. Every other reorder calls this method.
    mutating func apply(_ permutation: Permutation)

    /// Exchanges the elements at the two indices, keeping every index valid.
    mutating func swapAt(_ i: Index, _ j: Index)
}

public extension PermutableCollection {

    /// Applies the permutation with the minimal number of `swapAt(_:_:)` calls, walking the indices once so each swap is O(1), which requires `swapAt(_:_:)` to keep indices valid.
    @inlinable mutating func apply(_ permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        precondition(permutation.minimumCount <= count, "Every offset in the cycle must be within the collection.")
        let positions: [Index] = Array(indices.prefix(permutation.minimumCount))
        permutation.forEachSwap { swapAt(positions[$0], positions[$1]) }
    }

    /// Returns a copy of the collection with the permutation applied to its elements.
    @inlinable func applying(_ permutation: Permutation) -> Self {
        var copy: Self = self
        copy.apply(permutation)
        return copy
    }

    /// Moves the element at the source index so it ends up at the destination index, shifting the elements between them, and returns the permutation applied.
    @inlinable @discardableResult mutating func move(from source: Index, to destination: Index) -> Permutation {
        apply(returning: Permutation(moving: distance(from: startIndex, to: source), to: distance(from: startIndex, to: destination), count: count))
    }

    /// Moves the elements at the given offsets to just before the element at the destination offset, keeping their relative order, and returns the permutation applied.
    @inlinable @discardableResult mutating func move(fromOffsets source: some Sequence<Int>, toOffset destination: Int) -> Permutation {
        let moved: [Int] = Set(source).sorted()
        precondition(moved.allSatisfy { (0..<count).contains($0) } && (0...count).contains(destination), "Every offset must be within the collection.")
        var isMoved: [Bool] = [Bool](repeating: false, count: count)
        for offset in moved {
            isMoved[offset] = true
        }
        var before: [Int] = []
        var after: [Int] = []
        for offset in 0..<count where !isMoved[offset] {
            if offset < destination {
                before.append(offset)
            } else {
                after.append(offset)
            }
        }
        return apply(sources: before + moved + after)
    }

    /// Moves the elements that satisfy the predicate after those that do not, keeping the relative order within each group, and returns the index of the first moved element.
    @inlinable @discardableResult mutating func partition(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> Index {
        var first: [Int] = []
        var second: [Int] = []
        for (offset, element) in enumerated() {
            if try belongsInSecondPartition(element) {
                second.append(offset)
            } else {
                first.append(offset)
            }
        }
        apply(Permutation(sources: first + second))
        return index(startIndex, offsetBy: first.count)
    }

    /// Reverses the elements in place and returns the permutation applied.
    @inlinable @discardableResult mutating func reverse() -> Permutation {
        apply(returning: Permutation(reversing: count))
    }

    /// Rotates the elements so the element at the given index becomes the first, and returns the permutation applied.
    @inlinable @discardableResult mutating func rotate(toStartAt newStart: Index) -> Permutation {
        apply(returning: Permutation(rotating: count, by: distance(from: startIndex, to: newStart)))
    }

    /// Shuffles the elements in place in the given style, and returns the permutation applied.
    @inlinable @discardableResult mutating func shuffle(_ style: Permutation.Shuffle = .random) -> Permutation {
        style == .random ? apply(returning: Permutation(shuffles: count)) : apply(returning: Permutation(shuffles: count, style))
    }

    /// Shuffles the elements in place in the given style, using the given generator as a source for randomness, and returns the permutation applied, giving the same order as `Array.shuffle(using:)` for the random style.
    @inlinable @discardableResult mutating func shuffle<R: RandomNumberGenerator>(_ style: Permutation.Shuffle = .random, using generator: inout R) -> Permutation {
        guard style == .random else { return apply(returning: Permutation(shuffles: count, style, using: &generator)) }
        var sources: [Int] = Array(0..<count)
        sources.shuffle(using: &generator)
        return apply(sources: sources)
    }

    /// Sorts the elements in place through a single permutation applied with one swap per element that moves within a cycle, and returns the permutation applied.
    @inlinable @discardableResult mutating func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Permutation {
        let elements: [Element] = Array(self)
        return try apply(sources: elements.indices.sorted { try areInIncreasingOrder(elements[$0], elements[$1]) })
    }

    /// Applies the permutation and returns it.
    @inlinable internal mutating func apply(returning permutation: Permutation) -> Permutation {
        apply(permutation)
        return permutation
    }

    /// Applies the permutation built from source offsets and returns it.
    @inlinable internal mutating func apply(sources: [Int]) -> Permutation {
        apply(returning: Permutation(sources: sources))
    }
}

public extension PermutableCollection where Element: Comparable {

    /// Sorts the elements in ascending order through a single permutation, and returns the permutation applied.
    @inlinable @discardableResult mutating func sort() -> Permutation {
        sort(by: <)
    }
}

public extension PermutableCollection where Self: RandomAccessCollection {

    /// Applies the permutation with the minimal number of `swapAt(_:_:)` calls, offsetting each index directly in O(1).
    @inlinable mutating func apply(_ permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        precondition(permutation.minimumCount <= count, "Every offset in the cycle must be within the collection.")
        permutation.forEachSwap { swapAt(index(startIndex, offsetBy: $0), index(startIndex, offsetBy: $1)) }
    }
}
