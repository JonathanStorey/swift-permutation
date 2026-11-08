// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection.swift
// dependencies: [Permutation/Permutation+Swaps.swift, Permutation/Permutation+Moves.swift, Permutation/Permutation+Reverse.swift, Permutation/Permutation+Rotate.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

/// A collection whose every reorder passes through `apply(_:)`, so overriding that one method lets a conforming type reorder in its own cheapest way, or observe every reorder.
///
/// A conforming type implements `swapAt(_:_:)`, the smallest reorder any collection can offer. The default `apply(_:)` is built from it, so the swaps must keep every index valid. A type that can move a whole cycle at once, such as one that reorders an index rather than its elements, overrides `apply(_:)` as well.
///
/// When a conforming type is also a `MutableCollection`, a call to `sort` or `reverse` that discards its result uses the standard library's in-place implementation, which produces no permutation. A call whose result is used as a `Permutation`, as in `let permutation: Permutation = tiles.sort()`, computes the permutation and applies it through `apply(_:)` instead. The standard library's unstable `partition` remains available beside `stablePartition`.
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

    /// Exchanges the elements at the two indices and returns the permutation applied, a single swap of their offsets.
    @inlinable @discardableResult mutating func swap(_ i: Index, _ j: Index) -> Permutation {
        let first: Int = distance(from: startIndex, to: i)
        let second: Int = distance(from: startIndex, to: j)
        swapAt(i, j)
        return first == second ? Permutation(cycle: []) : Permutation(cycle: [Swift.max(first, second), Swift.min(first, second)])
    }

    /// Moves the element at the source index so it ends up at the destination index, shifting the elements between them, and returns the permutation applied.
    @inlinable @discardableResult mutating func move(from source: Index, to destination: Index) -> Permutation {
        apply(returning: Permutation(moving: distance(from: startIndex, to: source), to: distance(from: startIndex, to: destination), count: count))
    }

    /// Moves the elements at the given offsets to just before the element at the destination offset, keeping their relative order, and returns the permutation applied. A single offset, as a one-row drag in SwiftUI gives, takes the same path as `move(from:to:)`.
    @inlinable @discardableResult mutating func move(fromOffsets source: some Sequence<Int>, toOffset destination: Int) -> Permutation {
        precondition((0...count).contains(destination), "Every offset must be within the collection.")
        var remaining = source.makeIterator()
        guard let first: Int = remaining.next() else { return Permutation(cycle: []) }
        precondition((0..<count).contains(first), "Every offset must be within the collection.")
        guard let second: Int = remaining.next() else {
            return move(from: index(startIndex, offsetBy: first), to: index(startIndex, offsetBy: destination > first ? destination - 1 : destination))
        }
        var isMoved: [Bool] = [Bool](repeating: false, count: count)
        isMoved[first] = true
        var movedCount: Int = 1
        var next: Int? = second
        while let offset: Int = next {
            precondition(isMoved.indices.contains(offset), "Every offset must be within the collection.")
            if !isMoved[offset] {
                isMoved[offset] = true
                movedCount += 1
            }
            next = remaining.next()
        }
        return move(marked: isMoved, count: movedCount, toOffset: destination)
    }

    /// Moves the elements whose offsets are marked to just before the destination offset, keeping their relative order. Every offset outside the window from the first moved offset or the destination, whichever is lower, to the last moved offset or the destination, whichever is higher, stays in place, so the permutation is built over that window alone, filling one array of source offsets through three cursors: unmoved offsets before the destination, then the moved ones, then the rest.
    @inlinable internal mutating func move(marked isMoved: [Bool], count movedCount: Int, toOffset destination: Int) -> Permutation {
        guard movedCount > 0 else { return Permutation(cycle: []) }
        let lower: Int = Swift.min(isMoved.firstIndex(of: true)!, destination)
        let upper: Int = Swift.max(isMoved.lastIndex(of: true)! + 1, destination)
        var movedBefore: Int = 0
        for offset in lower..<destination where isMoved[offset] { movedBefore += 1 }
        var before: Int = 0
        var moved: Int = destination - lower - movedBefore
        var after: Int = moved + movedCount
        var sources: [Int] = [Int](repeating: 0, count: upper - lower)
        for offset in lower..<upper {
            if isMoved[offset] {
                sources[moved] = offset - lower
                moved += 1
            } else if offset < destination {
                sources[before] = offset - lower
                before += 1
            } else {
                sources[after] = offset - lower
                after += 1
            }
        }
        return apply(returning: Permutation(sources: sources, shiftedBy: lower))
    }

    /// Moves the elements that satisfy the predicate after those that do not, keeping the relative order within each group, and returns the index of the first moved element.
    @inlinable @discardableResult mutating func stablePartition(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> Index {
        let total: Int = count
        var sources: [Int] = [Int](repeating: 0, count: total)
        var low: Int = 0
        var high: Int = total
        for (offset, element) in enumerated() {
            if try belongsInSecondPartition(element) {
                high -= 1
                sources[high] = offset
            } else {
                sources[low] = offset
                low += 1
            }
        }
        sources[low...].reverse()
        apply(Permutation(sources: sources))
        return index(startIndex, offsetBy: low)
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

    /// Applies the permutation with the minimal number of `swapAt(_:_:)` calls, offsetting each index directly in O(1) and checking only each swap's larger offset against the count.
    @inlinable mutating func apply(_ permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        let count: Int = self.count
        permutation.forEachSwap { root, offset in
            precondition(root < count, "Every offset in the cycle must be within the collection.")
            swapAt(index(startIndex, offsetBy: root), index(startIndex, offsetBy: offset))
        }
    }
}
