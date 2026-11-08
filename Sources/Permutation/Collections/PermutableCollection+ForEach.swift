// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection+ForEach.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+ForEach.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

public extension PermutableCollection {

    /// Calls the closure once with each of the `count!` orders of the elements, starting with the current one, then puts the elements back in the order they started in.
    ///
    /// The walk follows Heap's algorithm, so each order differs from the one before it by a single `swapAt(_:_:)`, and the whole walk makes `count! - 1` swaps plus one permutation to restore the start. The number of orders grows fast: 10 elements have 3,628,800 of them, and 13 have more than six billion.
    ///
    /// Each call receives the collection itself. Keeping it past the call copies the storage at the next swap, so record what you need from each order instead.
    @inlinable mutating func forEach(_ operation: Permutation.Operation<Self>, _ body: (Self) throws -> Void) rethrows {
        let positions: [Index] = Array(indices)
        let count: Int = positions.count
        var sources: [Int] = Array(0..<count)
        var counters: [Int] = [Int](repeating: 0, count: count)
        try body(self)
        var level: Int = 1
        while level < count {
            if counters[level] < level {
                let other: Int = level.isMultiple(of: 2) ? 0 : counters[level]
                swapAt(positions[other], positions[level])
                sources.swapAt(other, level)
                try body(self)
                counters[level] += 1
                level = 1
            } else {
                counters[level] = 0
                level += 1
            }
        }
        apply(Permutation(sources: sources).inverted)
    }
}
