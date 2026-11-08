// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Permutations.swift
// dependencies: [Permutation/Permutation+Rank.swift, Permutation/Permutation+Strideable.swift, Permutation/Permutation.swift]

// Every permutation of `count` offsets in rank order, as a lazy sequence.
//
// - It visits the same permutations as `stride(from: Permutation(), to: Permutation(rank: count!), by: 1)`, but keeps the Foata word between steps and stops when the word outgrows the count, so no step computes a rank.
// - Each step is the `next_permutation` step `advance(by: 1)` takes, touching fewer than three entries on average, and building the permutation from the word costs O(count).

extension Permutation {

    /// Every one of the `count!` permutations of `count` offsets in rank order, starting with the identity, computed one at a time as the sequence is iterated. The k-th is `Permutation(rank: k)`.
    ///
    /// The number of permutations grows fast: 10 offsets have 3,628,800 of them, and 13 have more than six billion. Stop early with `break`, `first(where:)` or `prefix(_:)`.
    @inlinable public static func permutations(count: Int) -> Permutations {
        precondition(count >= 0, "A count cannot be negative.")
        return Permutations(count: count)
    }

    /// The permutations of a count of offsets in rank order, from `Permutation.permutations(count:)`.
    public struct Permutations: Sequence, Sendable {

        @usableFromInline let count: Int

        @inlinable init(count: Int) {
            self.count = count
        }

        @inlinable public func makeIterator() -> Iterator {
            Iterator(count: count)
        }

        /// Steps a Foata word over the offsets below the count.
        public struct Iterator: IteratorProtocol, Sendable {

            @usableFromInline let count: Int

            /// The Foata word of the permutation last returned.
            @usableFromInline var word: [Int]

            /// Whether the identity has been returned yet.
            @usableFromInline var hasStarted: Bool = false

            @inlinable init(count: Int) {
                self.count = count
                word = Array(0..<count)
            }

            /// The next permutation in rank order, or nil once all `count!` have been returned.
            @inlinable public mutating func next() -> Permutation? {
                guard hasStarted else {
                    hasStarted = true
                    return Permutation()
                }
                Permutation.stepForward(&word)
                guard word.count <= count else { return nil }
                return Permutation(foataWord: word)
            }
        }
    }
}
