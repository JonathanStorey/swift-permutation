// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+ForEach.swift
// dependencies: [Permutation/Permutation.swift]

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
    /// The elements on a longest increasing subsequence of the final order stay put and every other element moves exactly once, so the number of moves is the minimum. Finding the subsequence is O(n log n) and replaying the moves is O(n) per move, where n is `minimumCount`.
    @inlinable func forEachMove(_ body: (_ from: Int, _ to: Int) throws -> Void) rethrows {
        let count: Int = minimumCount
        guard count > 1 else { return }
        var sources: [Int] = Array(0..<count)
        forEachCycle { cycle in
            for position in cycle.indices {
                sources[cycle[(position + 1) % cycle.count]] = cycle[position]
            }
        }
        var tails: [Int] = []
        var previous: [Int] = Array(repeating: -1, count: count)
        for position in 0..<count {
            var low: Int = 0
            var high: Int = tails.count
            while low < high {
                let middle: Int = (low + high) / 2
                if sources[tails[middle]] < sources[position] { low = middle + 1 } else { high = middle }
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
        var current: [Int] = Array(0..<count)
        for position in 0..<count where !stays[position] {
            let element: Int = sources[position]
            let from: Int = current.firstIndex(of: element)!
            current.remove(at: from)
            let to: Int = position == 0 ? 0 : current.firstIndex(of: sources[position - 1])! + 1
            current.insert(element, at: to)
            try body(from, to)
        }
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
