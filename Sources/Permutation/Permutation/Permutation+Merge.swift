// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Merge.swift
// dependencies: [Permutation/Permutation+Composition.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

extension Permutation {

    /// Returns the two-way merge of this permutation and theirs, treating the original order as their common base, or nil when a cycle from one side shares an offset with a different cycle from the other.
    ///
    /// Two cycles that share an offset are the same cycle exactly when both sides give that offset the same source, so the merge is one pass over the sources: take ours where we move an offset, theirs otherwise, and fail where both move it from different places. Offsets scattered far apart fall back to merging cycle by cycle.
    public func merging(with theirs: Permutation) -> Permutation? {
        let count: Int = Swift.max(minimumCount, theirs.minimumCount)
        guard Permutation.prefersDense(count: count, support: cycle.count + theirs.cycle.count) else { return mergingSparse(with: theirs) }
        var merged: [Int] = sources(count: count)
        let other: [Int] = theirs.sources(count: count)
        for offset in merged.indices {
            let source: Int = other[offset]
            if merged[offset] == offset {
                merged[offset] = source
            } else if source != offset && source != merged[offset] {
                return nil
            }
        }
        return Permutation(sources: merged)
    }

    /// Returns the two-way merge by matching cycles through a dictionary, for permutations whose offsets are scattered far apart.
    func mergingSparse(with theirs: Permutation) -> Permutation? {
        Permutation.merge(cycles, theirs.cycles).map(Permutation.init(cycles:))
    }

    /// Returns the three-way merge of this permutation and theirs, both descended from base, by merging each side's change since base, or nil when a cycle from one side shares an offset with a different cycle from the other.
    public func merging(with theirs: Permutation, from base: Permutation) -> Permutation? {
        let undo: Permutation = base.inverted
        guard let merged: Permutation = undo.followed(by: self).merging(with: undo.followed(by: theirs)) else { return nil }
        return base.followed(by: merged)
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
