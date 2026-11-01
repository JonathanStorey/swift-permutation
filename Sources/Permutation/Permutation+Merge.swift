// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Merge.swift
// dependencies: [Permutation+Composition.swift, Permutation.swift]

extension Permutation {

    /// Returns the two-way merge of this permutation and theirs, treating the original order as their common base, or nil when a cycle from one side shares an offset with a different cycle from the other.
    public func merge(with theirs: Permutation) -> Permutation? {
        Permutation.merge(cycles, theirs.cycles).map(Permutation.init(cycles:))
    }

    /// Returns the three-way merge of this permutation and theirs, both descended from base, by merging each side's change cycle by cycle, or nil when a cycle from one side shares an offset with a different cycle from the other.
    public func merge(with theirs: Permutation, from base: Permutation) -> Permutation? {
        let undo: Permutation = base.inverted
        guard let merged: [[Int]] = Permutation.merge(undo.followed(by: self).cycles, undo.followed(by: theirs).cycles) else { return nil }
        return base.followed(by: Permutation(cycles: merged))
    }

    /// Returns every cycle from either side once, or nil when a cycle from one side shares an offset with a different cycle from the other.
    private static func merge(_ ourCycles: [[Int]], _ theirCycles: [[Int]]) -> [[Int]]? {
        var theirCycleIndex: [Int: Int] = [:]
        for (index, cycle) in theirCycles.enumerated() {
            for offset in cycle {
                theirCycleIndex[offset] = index
            }
        }
        var isShared: [Bool] = [Bool](repeating: false, count: theirCycles.count)
        var merged: [[Int]] = []
        for cycle in ourCycles {
            guard let index: Int = theirCycleIndex[cycle[0]] else {
                guard cycle.allSatisfy({ theirCycleIndex[$0] == nil }) else { return nil }
                merged.append(cycle)
                continue
            }
            guard theirCycles[index] == cycle else { return nil }
            isShared[index] = true
            merged.append(cycle)
        }
        for (index, cycle) in theirCycles.enumerated() where !isShared[index] {
            merged.append(cycle)
        }
        return merged
    }
}
