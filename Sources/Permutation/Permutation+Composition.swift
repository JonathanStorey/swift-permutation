// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Composition.swift
// dependencies: [Permutation+Sources.swift, Permutation.swift]

extension Permutation {

    /// Returns the permutation that applies this permutation and then the next, over the larger of their minimum counts.
    public func followed(by next: Permutation) -> Permutation {
        let count: Int = Swift.max(minimumCount, next.minimumCount)
        let first: [Int] = destinations(count: count)
        let second: [Int] = next.destinations(count: count)
        var sources: [Int] = Array(0..<count)
        for offset in sources.indices {
            sources[second[first[offset]]] = offset
        }
        return Permutation(sources: sources)
    }
}
