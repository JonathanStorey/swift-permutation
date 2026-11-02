// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Composition.swift
// dependencies: [Permutation/Permutation.swift]

extension Permutation {

    /// Returns the permutation that applies this permutation and then the next, multiplying them in cycle form over only the offsets either one moves.
    public func followed(by next: Permutation) -> Permutation {
        let first: [Int: Int] = successors
        let second: [Int: Int] = next.successors
        var isVisited: Set<Int> = []
        var cycles: [[Int]] = []
        for start in Set(first.keys).union(second.keys) where !isVisited.contains(start) {
            var cycle: [Int] = []
            var offset: Int = start
            repeat {
                isVisited.insert(offset)
                cycle.append(offset)
                let middle: Int = first[offset] ?? offset
                offset = second[middle] ?? middle
            } while offset != start
            cycles.append(cycle)
        }
        return Permutation(cycles: cycles)
    }

    /// The offset each moved offset sends its element to, read straight from the cycles.
    private var successors: [Int: Int] {
        var successors: [Int: Int] = Dictionary(minimumCapacity: cycle.count)
        for cycle in cycles {
            for (position, offset) in cycle.enumerated() {
                successors[offset] = cycle[(position + 1) % cycle.count]
            }
        }
        return successors
    }
}
