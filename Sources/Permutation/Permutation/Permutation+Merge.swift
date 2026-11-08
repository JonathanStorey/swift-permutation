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
        Permutation.merge(cycleArrays, theirs.cycleArrays).map(Permutation.init(cycles:))
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

extension Permutation {

    /// The side whose order a three-way merge leans toward when the two sides' reorders cannot all be kept.
    public enum MergePreference: Hashable, Sendable {

        /// Lean toward this permutation, the one `merging` is called on.
        case ours

        /// Lean toward the permutation passed as `with`.
        case theirs
    }

    /// Returns the three-way merge of this permutation and theirs, both descended from base, and never fails.
    ///
    /// When no cycle from one side shares an offset with a different cycle from the other, this is the same permutation the strict merge returns, so every swap and cycle from both sides survives. Otherwise the offsets are merged by relative order: each pair of offsets keeps the order either side changed it to since base, or base's order when neither touched it. Two sides can never disagree about a single pair, since a pair has only one way to change, so they conflict only when the kept pairs chase each other in a loop. Then the merge settles on an order that starts from the preferred side's and still keeps most of what both sides did.
    ///
    /// All three permutations must describe the same elements at the same offsets, so apply every insertion and removal from either side to all three before merging.
    public func merging(with theirs: Permutation, from base: Permutation, favoring preference: MergePreference) -> Permutation {
        if let merged: Permutation = merging(with: theirs, from: base) { return merged }
        let count: Int = Swift.max(minimumCount, theirs.minimumCount, base.minimumCount)
        let basePositions: [Int] = Permutation.positions(of: base.sources(count: count))
        let ourPositions: [Int] = Permutation.positions(of: sources(count: count))
        let theirPositions: [Int] = Permutation.positions(of: theirs.sources(count: count))
        let order: [Int] = preference == .ours ? sources(count: count) : theirs.sources(count: count)
        let merged: [Int] = Permutation.mergeSorted(order) { first, second in
            let isInBaseOrder: Bool = basePositions[first] < basePositions[second]
            let isChanged: Bool = (ourPositions[first] < ourPositions[second]) != isInBaseOrder
                || (theirPositions[first] < theirPositions[second]) != isInBaseOrder
            return isChanged != isInBaseOrder
        }
        return Permutation(sources: merged)
    }

    /// The position each offset is shown at, the inverse of the sources.
    private static func positions(of sources: [Int]) -> [Int] {
        var positions: [Int] = [Int](repeating: 0, count: sources.count)
        for (position, offset) in sources.enumerated() {
            positions[offset] = position
        }
        return positions
    }

    /// Sorts the offsets with a stable bottom-up merge sort, which always returns every offset once even when the comparison loops, and leaves offsets the comparison cannot separate in their given order.
    private static func mergeSorted(_ offsets: [Int], by isBefore: (Int, Int) -> Bool) -> [Int] {
        var current: [Int] = offsets
        var next: [Int] = offsets
        var width: Int = 1
        while width < current.count {
            var start: Int = 0
            while start < current.count {
                let middle: Int = Swift.min(start + width, current.count)
                let end: Int = Swift.min(start + 2 * width, current.count)
                var left: Int = start
                var right: Int = middle
                for slot in start..<end {
                    if left < middle && (right == end || !isBefore(current[right], current[left])) {
                        next[slot] = current[left]
                        left += 1
                    } else {
                        next[slot] = current[right]
                        right += 1
                    }
                }
                start = end
            }
            swap(&current, &next)
            width *= 2
        }
        return current
    }
}
