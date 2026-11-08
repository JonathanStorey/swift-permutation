// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Swaps.swift
// dependencies: [Permutation/Permutation.swift]

// A permutation as the fewest exchanges that produce it, read straight off the Foata line.
//
// - Each cycle of length `L` gives `L - 1` exchanges of its first offset with each later one, so the total is the moved offsets minus the cycles, the fewest any sequence of exchanges can manage.
// - `swaps` is a lazy sequence whose iterator holds the line and two integers, so walking it allocates nothing. `apply` and its relatives call the internal `forEachSwap` directly.

extension Permutation {

    /// An exchange of the elements at two offsets.
    public struct Swap: Hashable, Sendable {

        /// The larger offset, which leads its cycle.
        public let first: Int

        /// The smaller offset.
        public let second: Int

        @inlinable public init(first: Int, second: Int) {
            self.first = first
            self.second = second
        }
    }

    /// The fewest exchanges that produce this permutation when made in order, one fewer than the length of each cycle, read lazily from the stored line with no allocation.
    @inlinable public var swaps: Swaps {
        Swaps(line: cycle)
    }

    /// The exchanges that produce a permutation, from `Permutation.swaps`.
    public struct Swaps: Sequence, Sendable {

        @usableFromInline let line: [Int]

        @inlinable init(line: [Int]) {
            self.line = line
        }

        @inlinable public func makeIterator() -> Iterator {
            Iterator(line: line)
        }

        /// Reads the line once: each offset larger than every one before it starts a cycle, and each other offset is exchanged with that cycle's first.
        public struct Iterator: IteratorProtocol, Sendable {

            @usableFromInline let line: [Int]

            @usableFromInline var position: Int = 0

            @usableFromInline var root: Int = -1

            @inlinable init(line: [Int]) {
                self.line = line
            }

            @inlinable public mutating func next() -> Swap? {
                while position < line.count {
                    let offset: Int = line[position]
                    position += 1
                    if offset > root {
                        root = offset
                    } else {
                        return Swap(first: root, second: offset)
                    }
                }
                return nil
            }
        }
    }
}

extension Permutation {

    /// Calls the closure with each pair of offsets to swap, in order, deriving them in one pass with no allocation.
    @inlinable func forEachSwap(_ body: (Int, Int) throws -> Void) rethrows {
        var start: Int = -1
        for offset in cycle {
            if offset > start {
                start = offset
            } else {
                try body(start, offset)
            }
        }
    }
}
