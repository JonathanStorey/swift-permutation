// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Arrangement+Permutations.swift
// dependencies: [Collections/Arrangement.swift, Permutation/Permutation+Rank.swift, Permutation/Permutation+Strideable.swift, Permutation/Permutation.swift]

// Every order of an arrangement's elements, in rank order, as a lazy sequence that a loop can leave with `break`.
//
// - An arrangement remembers its original order, so its orders have a natural starting point and a natural sequence: the k-th order shown has `permutation == Permutation(rank: k)`, the order `Permutation`'s `Strideable` conformance steps through.
// - The iterator steps a Foata word with the same `next_permutation` step `advance(by: 1)` takes, then shows the arrangement's elements in that permutation, O(m) per order. Only an arrangement gets this, because other permutable collections have no original order to count from.
// - It is a `Sequence` and not a `Collection` on purpose: there are `count!` orders, which outgrows `Int` past 20 elements, so a `count` or an index would be meaningless.

public extension Arrangement {

    /// Every one of the `count!` orders of the elements in rank order, starting with the original order, computed one at a time as the sequence is iterated. The k-th has `permutation == Permutation(rank: k)`.
    ///
    /// The number of orders grows fast: 10 elements have 3,628,800 of them, and 13 have more than six billion. Stop early with `break`, `first(where:)` or `prefix(_:)`. Anything that reads the whole sequence at once, such as `Array(_:)`, `map(_:)` or `sorted()`, will not finish for more than a dozen or so elements. Use `lazy` to transform the orders without reading them all.
    ///
    /// The arrangement itself is left as it is.
    @inlinable var permutations: Permutations {
        Permutations(base: self)
    }

    /// The orders of an arrangement's elements in rank order, from `Arrangement.permutations`.
    struct Permutations: Sequence {

        /// The arrangement whose elements are shown in each order.
        @usableFromInline let base: Arrangement

        @inlinable init(base: Arrangement) {
            self.base = base
        }

        @inlinable public func makeIterator() -> Iterator {
            Iterator(base: base)
        }

        /// Steps a Foata word through every order of the elements and shows the elements in each one.
        public struct Iterator: IteratorProtocol {

            /// The arrangement in the order last returned.
            @usableFromInline var current: Arrangement

            /// The Foata word of the order last returned, over every offset below the count.
            @usableFromInline var word: [Int]

            /// Whether the original order has been returned yet.
            @usableFromInline var hasStarted: Bool = false

            @inlinable init(base: Arrangement) {
                current = base
                word = Array(0..<base.count)
            }

            /// The next order in rank order, or nil once all `count!` have been returned.
            @inlinable public mutating func next() -> Arrangement? {
                guard hasStarted else {
                    hasStarted = true
                    current.permutation = Permutation()
                    return current
                }
                Permutation.stepForward(&word)
                guard word.count <= current.count else { return nil }
                current.permutation = Permutation(foataWord: word)
                return current
            }
        }
    }
}

extension Arrangement.Permutations: Sendable where Element: Sendable {}

extension Arrangement.Permutations.Iterator: Sendable where Element: Sendable {}
