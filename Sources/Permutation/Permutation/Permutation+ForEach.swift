// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+ForEach.swift
// dependencies: [Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

public extension Permutation {

    /// Calls the closure with each cycle in order, each starting with its largest offset, where the element at each offset moves to the next offset and the last moves to the first.
    @inlinable func forEachCycle(_ body: ([Int]) throws -> Void) rethrows {
        var current: [Int] = []
        for offset in cycle {
            if let start: Int = current.first, offset < start {
                current.append(offset)
            } else {
                if !current.isEmpty { try body(current) }
                current = [offset]
            }
        }
        if !current.isEmpty { try body(current) }
    }

    /// Calls the closure with the fewest single-element moves that produce this permutation, each a removal at `from` followed by an insertion at `to`, valid in the order given.
    ///
    /// The elements on a longest increasing subsequence of the final order stay put and every other element moves exactly once, so the number of moves is the minimum. Each moved element lands right after the element that precedes it in the final order, which has already settled, so every element's place in the changing order is known in advance: a stayed element keeps its original offset as its key, and a run of moved elements hangs after the last settled element before it. Ranking those keys once and counting the live ones with a Fenwick tree gives each `from` and `to` in O(log n), so the whole replay is O(n log n), where n is `minimumCount`.
    @inlinable func forEachMove(_ body: (_ from: Int, _ to: Int) throws -> Void) rethrows {
        let count: Int = minimumCount
        guard count > 1 else { return }
        let finalOrder: [Int] = sources(count: count)
        var tails: [Int] = []
        var previous: [Int] = Array(repeating: -1, count: count)
        for position in 0..<count {
            var low: Int = 0
            var high: Int = tails.count
            while low < high {
                let middle: Int = (low + high) / 2
                if finalOrder[tails[middle]] < finalOrder[position] { low = middle + 1 } else { high = middle }
            }
            if low > 0 { previous[position] = tails[low - 1] }
            if low == tails.count { tails.append(position) } else { tails[low] = position }
        }
        var stays: [Bool] = Array(repeating: false, count: count)
        var position: Int = tails.last ?? -1
        while position >= 0 {
            stays[position] = true
            position = previous[position]
        }
        // Each run of moved positions hangs after an anchor: the last stayed element before it, or -1 for the front. Its keys follow the anchor's own.
        var anchors: [Int] = Array(repeating: -1, count: count)
        var ranksInRun: [Int] = Array(repeating: 0, count: count)
        var runLengths: [Int] = Array(repeating: 0, count: count + 1)
        var anchor: Int = -1
        for position in 0..<count {
            if stays[position] {
                anchor = finalOrder[position]
            } else {
                runLengths[anchor + 1] += 1
                anchors[position] = anchor
                ranksInRun[position] = runLengths[anchor + 1]
            }
        }
        // Slots in key order: the front run, then each original offset followed by the run anchored on it.
        var originalSlots: [Int] = Array(repeating: 0, count: count)
        var runStarts: [Int] = Array(repeating: 0, count: count + 1)
        var slot: Int = 0
        for base in -1..<count {
            if base >= 0 {
                originalSlots[base] = slot
                slot += 1
            }
            runStarts[base + 1] = slot
            slot += runLengths[base + 1]
        }
        var live: FenwickTree = FenwickTree(count: slot, marking: originalSlots)
        for position in 0..<count where !stays[position] {
            let original: Int = originalSlots[finalOrder[position]]
            let from: Int = live.count(before: original)
            live.add(-1, at: original)
            let landing: Int = runStarts[anchors[position] + 1] + ranksInRun[position] - 1
            let to: Int = live.count(before: landing)
            live.add(1, at: landing)
            try body(from, to)
        }
    }
}

/// Counts of live slots under prefix sums, each update and query in O(log n).
@usableFromInline struct FenwickTree {

    /// The partial sums, one-based.
    @usableFromInline var sums: [Int]

    /// Creates a tree over the slots with a one at each marked slot, built in O(n).
    @inlinable init(count: Int, marking marked: [Int]) {
        sums = Array(repeating: 0, count: count + 1)
        for slot in marked { sums[slot + 1] += 1 }
        for index in stride(from: 1, through: count, by: 1) {
            let parent: Int = index + (index & -index)
            if parent <= count { sums[parent] += sums[index] }
        }
    }

    /// Adds the amount at the slot.
    @inlinable mutating func add(_ amount: Int, at slot: Int) {
        var index: Int = slot + 1
        while index < sums.count {
            sums[index] += amount
            index += index & -index
        }
    }

    /// The total over every slot before this one.
    @inlinable func count(before slot: Int) -> Int {
        var total: Int = 0
        var index: Int = slot
        while index > 0 {
            total += sums[index]
            index -= index & -index
        }
        return total
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
