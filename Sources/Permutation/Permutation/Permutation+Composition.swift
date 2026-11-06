// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Composition.swift
// dependencies: [Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

extension Permutation {

    /// Returns the permutation that applies this permutation and then the next. The element that lands at `i` came to `next`'s source of `i` from this permutation's source of that, so the product's sources are one gather, `first[second[i]]`, turned back into Foata form in one pass. Offsets scattered far apart fall back to multiplying cycles over only the offsets either one moves.
    public func followed(by next: Permutation) -> Permutation {
        let count: Int = Swift.max(minimumCount, next.minimumCount)
        guard Permutation.prefersDense(count: count, support: cycle.count + next.cycle.count) else { return followedSparse(by: next) }
        let first: [Int] = sources(count: count)
        var product: [Int] = next.sources(count: count)
        for offset in product.indices {
            product[offset] = first[product[offset]]
        }
        return Permutation(sources: product)
    }

    /// Returns the permutation that applies this permutation and then the next, multiplying them in cycle form over only the offsets either one moves.
    func followedSparse(by next: Permutation) -> Permutation {
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
