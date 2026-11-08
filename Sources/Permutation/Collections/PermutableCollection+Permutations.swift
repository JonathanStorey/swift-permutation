// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection+Permutations.swift
// dependencies: [Collections/PermutableCollection.swift]

// Every order of a collection's elements, as a lazy sequence that a loop can leave with `break`.
//
// - The iterator walks Heap's algorithm on its own copy of the collection, so each order differs from the one before it by a single `swapAt(_:_:)` and the original is never touched.
// - Nothing is computed until iteration starts, so holding the sequence costs one copy of the collection however many orders it has.
// - It is a `Sequence` and not a `Collection` on purpose: there are `count!` orders, which outgrows `Int` past 20 elements, so a `count` or an index would be meaningless.

public extension PermutableCollection {

    /// Every one of the `count!` orders of the elements, starting with the current one, computed one swap at a time as the sequence is iterated.
    ///
    /// The number of orders grows fast: 10 elements have 3,628,800 of them, and 13 have more than six billion. Stop early with `break`, `first(where:)` or `prefix(_:)`. Anything that reads the whole sequence at once, such as `Array(_:)`, `map(_:)` or `sorted()`, will not finish for more than a dozen or so elements. Use `lazy` to transform the orders without reading them all.
    ///
    /// The collection itself is left as it is.
    @inlinable var permutations: Permutations<Self> {
        Permutations(base: self)
    }
}

/// The orders of a collection's elements, each one swap from the one before, from `PermutableCollection.permutations`.
public struct Permutations<Base: PermutableCollection>: Sequence {

    /// The collection in the order the walk starts from.
    @usableFromInline let base: Base

    @inlinable init(base: Base) {
        self.base = base
    }

    @inlinable public func makeIterator() -> Iterator {
        Iterator(base: base)
    }

    /// Steps through the orders with Heap's algorithm on its own copy of the collection.
    public struct Iterator: IteratorProtocol {

        /// The collection in the order last returned.
        @usableFromInline var current: Base

        /// The collection's indices, so each swap names positions by offset.
        @usableFromInline let positions: [Base.Index]

        /// Heap's counters, one per level.
        @usableFromInline var counters: [Int]

        /// The level the walk resumes at.
        @usableFromInline var level: Int = 1

        /// Whether the starting order has been returned yet.
        @usableFromInline var hasStarted: Bool = false

        @inlinable init(base: Base) {
            current = base
            positions = Array(base.indices)
            counters = [Int](repeating: 0, count: positions.count)
        }

        /// The next order, one swap from the last, or nil once all `count!` have been returned.
        ///
        /// A value returned earlier still shares storage with the iterator, so keeping it copies the storage at the next swap. Read what you need from each order instead.
        @inlinable public mutating func next() -> Base? {
            guard hasStarted else {
                hasStarted = true
                return current
            }
            while level < positions.count {
                if counters[level] < level {
                    let other: Int = level.isMultiple(of: 2) ? 0 : counters[level]
                    current.swapAt(positions[other], positions[level])
                    counters[level] += 1
                    level = 1
                    return current
                }
                counters[level] = 0
                level += 1
            }
            return nil
        }
    }
}

extension Permutations: Sendable where Base: Sendable {}

extension Permutations.Iterator: Sendable where Base: Sendable, Base.Index: Sendable {}
