// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation.swift
// dependencies: []

/// A reordering stored as cycles in Foata's single-line notation, leaving offsets outside the cycles in place so it applies to any collection long enough.
public struct Permutation: Hashable, Sendable {

    /// The cycles written one after another, each starting with its largest offset, in increasing order of those starting offsets. Read it through `cycles`.
    @usableFromInline let cycle: [Int]

    /// Two permutations are equal when they move every offset to the same place, which in Foata form means the same line. Written out so that `Strideable`'s default, which goes through `distance(to:)`, never stands in.
    @inlinable public static func == (lhs: Permutation, rhs: Permutation) -> Bool {
        lhs.cycle == rhs.cycle
    }

    /// Creates the identity, which leaves every offset in place. It is the starting point for folding reorders together with `followed(by:)`.
    @inlinable public init() {
        cycle = []
    }

    /// Creates a permutation from a line already in Foata's single-line notation.
    @inlinable init(cycle: [Int]) {
        self.cycle = cycle
    }

    /// Creates a permutation from cycles in any order and any rotation, where the element at each offset moves to the next offset in its cycle and the last moves to the first. Cycles of one offset are fixed points and are dropped.
    ///
    /// The cycles must not share an offset, and no offset can be negative.
    public init(cycles: [[Int]]) {
        var seen: Set<Int> = []
        for cycle in cycles {
            for offset in cycle {
                precondition(offset >= 0, "An offset cannot be negative.")
                precondition(seen.insert(offset).inserted, "Cycles must not share an offset.")
            }
        }
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

    /// The cycles split out of the line as arrays, each starting with its largest offset.
    var cycleArrays: [[Int]] {
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
