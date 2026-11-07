// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation.swift
// dependencies: []

/// A reordering stored as cycles in Foata's single-line notation, leaving offsets outside the cycles in place so it applies to any collection long enough.
public struct Permutation: Hashable, Sendable {

    /// The cycles written one after another, each starting with its largest offset, in increasing order of those starting offsets.
    public let cycle: [Int]

    /// Creates the identity, which leaves every offset in place. It is the starting point for folding reorders together with `followed(by:)`.
    @inlinable public init() {
        cycle = []
    }

    /// Creates a permutation from a line already in Foata's single-line notation.
    @inlinable init(cycle: [Int]) {
        self.cycle = cycle
    }

    /// Creates a permutation from cycles in any order and any rotation, rooting each at its largest offset, dropping fixed points, and ordering them by that offset.
    init(cycles: [[Int]]) {
        var rooted: [[Int]] = []
        for cycle in cycles where cycle.count > 1 {
            let root: Int = cycle.indices.max { cycle[$0] < cycle[$1] }!
            rooted.append(Array(cycle[root...] + cycle[..<root]))
        }
        rooted.sort { $0[0] < $1[0] }
        self.init(cycle: rooted.flatMap { $0 })
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

    /// The cycles split out of the line, each starting with its largest offset.
    var cycles: [[Int]] {
        var cycles: [[Int]] = []
        for offset in cycle {
            if let start: Int = cycles.last?.first, offset < start {
                cycles[cycles.count - 1].append(offset)
            } else {
                cycles.append([offset])
            }
        }
        return cycles
    }
}
