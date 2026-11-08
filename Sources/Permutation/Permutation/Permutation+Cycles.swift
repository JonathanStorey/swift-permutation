// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Cycles.swift
// dependencies: [Permutation/Permutation.swift]

// A permutation's cycles, read straight off the Foata line it stores, along with the properties that depend only on them.
//
// - Each cycle is a slice of the line, from one left-to-right maximum up to the next, so reading the cycles copies nothing.
// - Fixed points are not cycles here. A permutation that moves nothing has no cycles at all.
// - The order, parity and involution test depend only on cycle lengths, so they are read in one pass over the line.

extension Permutation {

    /// Whether a permutation is a product of an even or an odd number of swaps.
    public enum Parity: Hashable, Sendable {
        case even
        case odd
    }

    /// The cycles of a permutation, each starting with its largest offset, in increasing order of those offsets. The element at each offset moves to the next offset in its cycle, and the last moves to the first. Fixed points are left out.
    public struct Cycles: Hashable, Sendable {

        /// The Foata line the cycles are read from.
        @usableFromInline let line: [Int]

        @inlinable init(line: [Int]) {
            self.line = line
        }
    }

    /// The permutation's cycles, each starting with its largest offset. Fixed points are left out, so the identity has none.
    @inlinable public var cycles: Cycles {
        Cycles(line: cycle)
    }
}

extension Permutation.Cycles: Collection {

    /// A position among the cycles, holding the bounds of the cycle there so reading it is O(1).
    public struct Index: Comparable, Hashable, Sendable {

        @usableFromInline let start: Int

        @usableFromInline let end: Int

        @inlinable init(start: Int, end: Int) {
            self.start = start
            self.end = end
        }

        @inlinable public static func < (lhs: Index, rhs: Index) -> Bool {
            lhs.start < rhs.start
        }
    }

    /// The first cycle's position, found by reading to the end of that cycle.
    @inlinable public var startIndex: Index {
        Index(start: 0, end: end(ofCycleAt: 0))
    }

    @inlinable public var endIndex: Index {
        Index(start: line.count, end: line.count)
    }

    @inlinable public var isEmpty: Bool {
        line.isEmpty
    }

    /// The cycle at the position, as a slice of the line.
    @inlinable public subscript(position: Index) -> ArraySlice<Int> {
        line[position.start..<position.end]
    }

    /// The next cycle's position, found by reading to the end of that cycle, so walking every cycle reads the line once.
    @inlinable public func index(after position: Index) -> Index {
        Index(start: position.end, end: end(ofCycleAt: position.end))
    }

    /// The position just past the cycle that starts at `start`: the next offset larger than its first, or the end of the line.
    @inlinable func end(ofCycleAt start: Int) -> Int {
        guard start < line.count else { return start }
        var end: Int = start + 1
        while end < line.count && line[end] < line[start] { end += 1 }
        return end
    }
}

extension Permutation.Cycles {

    /// The number of offsets the permutation moves, the total length of its cycles, in O(1).
    @inlinable public var movedCount: Int {
        line.count
    }

    /// The cycle that holds the offset, or nil when the permutation leaves it in place.
    public func cycle(containing offset: Int) -> ArraySlice<Int>? {
        var start: Int = 0
        for position in line.indices {
            if line[position] > line[start] { start = position }
            if line[position] == offset { return line[start..<end(ofCycleAt: start)] }
        }
        return nil
    }

    /// The number of times the permutation must be applied before every element is back where it started, the least common multiple of the cycle lengths. The identity has order 1.
    ///
    /// The order of a permutation of `n` offsets can exceed `Int.max` once `n` reaches the thousands, and reading it then traps the same way integer overflow does.
    public var order: Int {
        var order: Int = 1
        for cycle in self {
            var divisor: Int = order
            var remainder: Int = cycle.count
            while remainder != 0 {
                (divisor, remainder) = (remainder, divisor % remainder)
            }
            order = (order / divisor) * cycle.count
        }
        return order
    }

    /// Whether the permutation takes an even or an odd number of swaps. A cycle of length `L` takes `L - 1` swaps, so the parity is that of the moved offsets minus the cycles.
    public var parity: Permutation.Parity {
        var cycles: Int = 0
        var root: Int = -1
        for offset in line where offset > root {
            root = offset
            cycles += 1
        }
        return (line.count - cycles).isMultiple(of: 2) ? .even : .odd
    }

    /// Whether applying the permutation twice restores every element, which holds exactly when every cycle swaps two offsets. The identity is an involution.
    public var isInvolution: Bool {
        guard line.count.isMultiple(of: 2) else { return false }
        for position in stride(from: 0, to: line.count, by: 2) where line[position] < line[position + 1] || (position + 2 < line.count && line[position + 2] < line[position]) {
            return false
        }
        return true
    }
}

extension Permutation.Cycles: CustomStringConvertible {

    /// The cycles in standard notation, such as `(2 0)(5 3 4)`, or `()` for the identity.
    public var description: String {
        guard !isEmpty else { return "()" }
        return map { "(" + $0.map(String.init).joined(separator: " ") + ")" }.joined()
    }
}
