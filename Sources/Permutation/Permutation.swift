// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation.swift
// dependencies: []

/// A reordering stored as cycles in Foata's single-line notation, leaving offsets outside the cycles in place so it applies to any collection long enough.
public struct Permutation: Hashable, Sendable {

    /// The cycles written one after another, each starting with its largest offset, in increasing order of those starting offsets.
    public let cycle: [Int]

    /// Creates a permutation from a line already in Foata's single-line notation.
    @inlinable init(cycle: [Int]) {
        self.cycle = cycle
    }

    /// The permutation that undoes this one, made by reversing each cycle after its largest offset.
    public var inverted: Permutation {
        var line: [Int] = cycle
        var blockStart: Int = 0
        var largest: Int = -1
        for position in line.indices where line[position] > largest {
            largest = line[position]
            if position > blockStart + 1 { line[(blockStart + 1)..<position].reverse() }
            blockStart = position
        }
        if line.count > blockStart + 1 { line[(blockStart + 1)...].reverse() }
        return Permutation(cycle: line)
    }

    /// The smallest collection count this permutation can be applied to, one more than its largest offset.
    public var minimumCount: Int {
        (cycle.max() ?? -1) + 1
    }

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
