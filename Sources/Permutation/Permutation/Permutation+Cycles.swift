// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Cycles.swift
// dependencies: [Permutation/Permutation.swift]

// A permutation's cycles, read straight off the Foata line it stores, along with the properties that depend only on them.
//
// - Each cycle runs from one left-to-right maximum of the line up to the next. Iterating finds each cycle's end as it goes, so walking every cycle reads the line once, and only handing a cycle out as an `[Int]` copies it.
// - `Cycles` is a sequence, not a collection: a cycle is read in order, never by position. To ask where one offset goes, use the permutation's `subscript(destinationOf:)`.
// - Code inside the package reads `slices` instead, which copies nothing.
// - Fixed points are not cycles here. A permutation that moves nothing has no cycles at all.
// - The order, parity and involution test depend only on cycle lengths, so they are read in one pass over the line.

extension Permutation {

    /// Whether a permutation is a product of an even or an odd number of swaps.
    public enum Parity: Hashable, Sendable {
        case even
        case odd
    }

    /// The cycles of a permutation, each starting with its largest offset, in increasing order of those offsets. The element at each offset moves to the next offset in its cycle, and the last moves to the first. Fixed points are left out.
    ///
    /// Each cycle is an `[Int]` indexed from zero, copied out of the stored line as iteration reaches it.
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

extension Permutation.Cycles: Sequence {

    /// Reads the cycles off the line one at a time, finding where each ends as it goes, so walking every cycle reads the line once.
    public struct Iterator: IteratorProtocol {

        @usableFromInline var bounds: Bounds

        @inlinable init(line: [Int]) {
            bounds = Bounds(line: line)
        }

        /// The next cycle, copied out of the line, or nil after the last.
        @inlinable public mutating func next() -> [Int]? {
            bounds.next().map { Array(bounds.line[$0]) }
        }
    }

    /// The range of positions in the line that each cycle fills, in order.
    @usableFromInline struct Bounds: Sequence, IteratorProtocol {

        @usableFromInline let line: [Int]

        @usableFromInline var start: Int = 0

        @inlinable init(line: [Int]) {
            self.line = line
        }

        /// The positions of the next cycle: from its largest offset up to the next offset larger than it, or the end of the line.
        @inlinable mutating func next() -> Range<Int>? {
            guard start < line.count else { return nil }
            var end: Int = start + 1
            while end < line.count && line[end] < line[start] { end += 1 }
            defer { start = end }
            return start..<end
        }
    }

    @inlinable public func makeIterator() -> Iterator {
        Iterator(line: line)
    }

    /// Whether the permutation moves nothing, in O(1).
    @inlinable public var isEmpty: Bool {
        line.isEmpty
    }

    /// The number of cycles, counted in one pass over the line.
    public var count: Int {
        var cycles: Int = 0
        var root: Int = -1
        for offset in line where offset > root {
            root = offset
            cycles += 1
        }
        return cycles
    }

    @inlinable public var underestimatedCount: Int {
        line.isEmpty ? 0 : 1
    }

    /// The positions each cycle fills in the line, which copies nothing.
    @usableFromInline var bounds: Bounds {
        Bounds(line: line)
    }

    /// Each cycle as a slice of the line, which copies nothing. A slice keeps the line's indices.
    @usableFromInline var slices: LazyMapSequence<Bounds, ArraySlice<Int>> {
        bounds.lazy.map { line[$0] }
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
    public func cycle(containing offset: Int) -> [Int]? {
        var start: Int = 0
        for position in line.indices {
            if line[position] > line[start] { start = position }
            if line[position] == offset { return Array(line[start..<end(ofCycleAt: start)]) }
        }
        return nil
    }

    /// The number of times the permutation must be applied before every element is back where it started, the least common multiple of the cycle lengths. The identity has order 1.
    ///
    /// The order of a permutation of `n` offsets can exceed `Int.max` once `n` reaches the thousands, and reading it then traps the same way integer overflow does.
    public var order: Int {
        var order: Int = 1
        for range in bounds {
            let length: Int = range.count
            var divisor: Int = order
            var remainder: Int = length
            while remainder != 0 {
                (divisor, remainder) = (remainder, divisor % remainder)
            }
            order = (order / divisor) * length
        }
        return order
    }

    /// Whether the permutation takes an even or an odd number of swaps. A cycle of length `L` takes `L - 1` swaps, so the parity is that of the moved offsets minus the cycles.
    public var parity: Permutation.Parity {
        (line.count - count).isMultiple(of: 2) ? .even : .odd
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
        return slices.map { "(" + $0.map(String.init).joined(separator: " ") + ")" }.joined()
    }
}

extension Permutation: CustomStringConvertible, CustomDebugStringConvertible {

    /// The permutation in standard cycle notation, such as `(2 0)(5 3 4)`, or `()` for the identity.
    public var description: String {
        cycles.description
    }

    /// The cycle notation wrapped in the type's name, such as `Permutation((2 0)(5 3 4))`.
    public var debugDescription: String {
        "Permutation(\(cycles.description))"
    }
}
