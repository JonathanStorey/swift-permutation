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

    /// How a merge that never fails settles the two sides' changes.
    public enum MergeStrategy: Hashable, Sendable {

        /// Keep every pair of offsets that either side reordered since base, giving up only pairs neither side touched. A reordered pair always moves its later offset in base ahead of its earlier one, so the reordered pairs from both sides can never loop and always fit in one order. Of those orders, this is the one that keeps the most of base, the join of both sides in the weak order. Neither side is favored, so the merge gives the same result from either side.
        case relativeOrder
    }

    /// Returns the three-way merge of this permutation and theirs, both descended from base, settled by the given strategy, and never fails.
    ///
    /// All three permutations must describe the same elements at the same offsets, so apply every insertion and removal from either side to all three before merging.
    public func merging(with theirs: Permutation, from base: Permutation, by strategy: MergeStrategy) -> Permutation {
        switch strategy {
        case .relativeOrder:
            return joining(with: theirs, from: base)
        }
    }

    /// Returns the two-way merge of this permutation and theirs, treating the original order as their common base, settled by the given strategy, and never fails.
    public func merging(with theirs: Permutation, by strategy: MergeStrategy) -> Permutation {
        merging(with: theirs, from: Permutation(), by: strategy)
    }

    /// Returns the order that keeps every pair either side reordered since base, and otherwise keeps base's order wherever it can.
    ///
    /// A pair reordered since base always moves its later offset in base ahead of its earlier one, so a loop of reordered pairs would have to keep stepping backward through base and could never close. The reordered pairs from both sides together therefore always fit in one order. Placing offsets one at a time, each time taking the earliest in base that no unplaced reordered pair still holds back, gives the order that gives up the fewest base pairs. O(n²) time and O(n) space.
    func joining(with theirs: Permutation, from base: Permutation) -> Permutation {
        if self == base { return theirs }
        if theirs == base || theirs == self { return self }
        let count: Int = Swift.max(minimumCount, theirs.minimumCount, base.minimumCount)
        let baseOrder: [Int] = base.sources(count: count)
        let ourPositions: [Int] = Permutation.positions(of: sources(count: count))
        let theirPositions: [Int] = Permutation.positions(of: theirs.sources(count: count))
        let ours: [Int] = baseOrder.map { ourPositions[$0] }
        let their: [Int] = baseOrder.map { theirPositions[$0] }
        var blockers: [Int] = [Int](repeating: 0, count: count)
        for later in 0..<count {
            for earlier in 0..<later where ours[later] < ours[earlier] || their[later] < their[earlier] {
                blockers[earlier] += 1
            }
        }
        var ready: [Int] = []
        for rank in 0..<count where blockers[rank] == 0 {
            Permutation.pushReady(rank, onto: &ready)
        }
        var merged: [Int] = []
        merged.reserveCapacity(count)
        while !ready.isEmpty {
            let rank: Int = Permutation.popReady(from: &ready)
            merged.append(baseOrder[rank])
            for earlier in 0..<rank where ours[rank] < ours[earlier] || their[rank] < their[earlier] {
                blockers[earlier] -= 1
                if blockers[earlier] == 0 { Permutation.pushReady(earlier, onto: &ready) }
            }
        }
        return Permutation(sources: merged)
    }

    /// Adds a rank to a binary min-heap.
    private static func pushReady(_ rank: Int, onto heap: inout [Int]) {
        heap.append(rank)
        var child: Int = heap.count - 1
        while child > 0 {
            let parent: Int = (child - 1) / 2
            guard heap[child] < heap[parent] else { break }
            heap.swapAt(child, parent)
            child = parent
        }
    }

    /// Removes and returns the smallest rank in a binary min-heap.
    private static func popReady(from heap: inout [Int]) -> Int {
        let smallest: Int = heap[0]
        let last: Int = heap.removeLast()
        guard !heap.isEmpty else { return smallest }
        heap[0] = last
        var parent: Int = 0
        while true {
            let left: Int = 2 * parent + 1
            guard left < heap.count else { break }
            let right: Int = left + 1
            let child: Int = right < heap.count && heap[right] < heap[left] ? right : left
            guard heap[child] < heap[parent] else { break }
            heap.swapAt(child, parent)
            parent = child
        }
        return smallest
    }

    /// The position each offset is shown at, the inverse of the sources.
    private static func positions(of sources: [Int]) -> [Int] {
        var positions: [Int] = [Int](repeating: 0, count: sources.count)
        for (position, offset) in sources.enumerated() {
            positions[offset] = position
        }
        return positions
    }
}
