// repository: https://github.com/JonathanStorey/swift-permutation
// path: PermutableCollection.swift
// dependencies: [Permutation+Reverse.swift, Permutation+Rotate.swift, Permutation+Shuffle.swift, Permutation+Sources.swift, Permutation.swift]

/// A collection that reorders its elements only by swapping them, so every reorder passes through `swapAt(_:_:)`.
public protocol PermutableCollection: Collection {

    /// Moves the element at each offset in each cycle to the next offset in that cycle, wrapping from the last offset to the first.
    mutating func permute(using permutation: Permutation)

    /// Exchanges the elements at the two indices.
    mutating func swapAt(_ i: Index, _ j: Index)
}

public extension PermutableCollection {

    /// Applies the permutation to the elements in place, the same as `permute(using:)`.
    @inlinable mutating func apply(_ permutation: Permutation) {
        permute(using: permutation)
    }

    /// Returns a copy of the collection with the permutation applied to its elements.
    @inlinable func applying(_ permutation: Permutation) -> Self {
        var copy: Self = self
        copy.permute(using: permutation)
        return copy
    }

    /// Moves the element at the source index so it ends up at the destination index, shifting the elements between them, and returns the permutation applied.
    @inlinable @discardableResult mutating func move(from source: Index, to destination: Index) -> Permutation {
        var sources: [Int] = Array(0..<count)
        let offset: Int = sources.remove(at: distance(from: startIndex, to: source))
        sources.insert(offset, at: distance(from: startIndex, to: destination))
        return permute(sources: sources)
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
        return permute(sources: before + moved + after)
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
        permute(using: Permutation(sources: first + second))
        return index(startIndex, offsetBy: first.count)
    }

    /// Applies the permutation with the minimal number of `swapAt(_:_:)` calls, walking the indices once so each swap is O(1), which requires `swapAt(_:_:)` to keep indices valid.
    @inlinable mutating func permute(using permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        precondition(permutation.minimumCount <= count, "Every offset in the cycle must be within the collection.")
        let positions: [Index] = Array(indices.prefix(permutation.minimumCount))
        permutation.forEachSwap { swapAt(positions[$0], positions[$1]) }
    }

    /// Reverses the elements in place and returns the permutation applied.
    @inlinable @discardableResult mutating func reverse() -> Permutation {
        permute(returning: Permutation(reversing: count))
    }

    /// Rotates the elements so the element at the given index becomes the first, and returns the permutation applied.
    @inlinable @discardableResult mutating func rotate(toStartAt newStart: Index) -> Permutation {
        permute(returning: Permutation(rotating: count, by: distance(from: startIndex, to: newStart)))
    }

    /// Shuffles the elements in place through a permutation shuffled directly in cycle form, and returns the permutation applied.
    @inlinable @discardableResult mutating func shuffle() -> Permutation {
        permute(returning: Permutation(shuffles: count))
    }

    /// Shuffles the elements in place, giving the same order as `Array.shuffle(using:)` with the same generator state, and returns the permutation applied.
    @inlinable @discardableResult mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R) -> Permutation {
        var sources: [Int] = Array(0..<count)
        sources.shuffle(using: &generator)
        return permute(sources: sources)
    }

    /// Sorts the elements in place through a single permutation applied with one swap per element that moves within a cycle, and returns the permutation applied.
    @inlinable @discardableResult mutating func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Permutation {
        let elements: [Element] = Array(self)
        return try permute(sources: elements.indices.sorted { try areInIncreasingOrder(elements[$0], elements[$1]) })
    }

    /// Applies the permutation and returns it.
    @inlinable internal mutating func permute(returning permutation: Permutation) -> Permutation {
        permute(using: permutation)
        return permutation
    }

    /// Applies the permutation built from source offsets and returns it.
    @inlinable internal mutating func permute(sources: [Int]) -> Permutation {
        permute(returning: Permutation(sources: sources))
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
    @inlinable mutating func permute(using permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        precondition(permutation.minimumCount <= count, "Every offset in the cycle must be within the collection.")
        permutation.forEachSwap { swapAt(index(startIndex, offsetBy: $0), index(startIndex, offsetBy: $1)) }
    }
}
