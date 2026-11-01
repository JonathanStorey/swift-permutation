// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Stride.swift
// dependencies: [Permutation+Sources.swift, Permutation.swift]

extension Permutation {

    /// Replaces the permutation with the one that applies it `distance` times, and returns the new permutation.
    @discardableResult public mutating func advance(by distance: Int) -> Permutation {
        self = advanced(by: distance)
        return self
    }

    /// Returns the permutation that applies this one `distance` times, moving each offset `distance` steps along its cycle, so a negative distance applies the inverse.
    public func advanced(by distance: Int) -> Permutation {
        let count: Int = minimumCount
        let destinations: [Int] = self.destinations(count: count)
        var sources: [Int] = Array(0..<count)
        var isVisited: [Bool] = [Bool](repeating: false, count: count)
        var orbit: [Int] = []
        for start in 0..<count where !isVisited[start] {
            orbit.removeAll(keepingCapacity: true)
            var offset: Int = start
            repeat {
                isVisited[offset] = true
                orbit.append(offset)
                offset = destinations[offset]
            } while offset != start
            let shift: Int = (distance % orbit.count + orbit.count) % orbit.count
            for (position, source) in orbit.enumerated() {
                sources[orbit[(position + shift) % orbit.count]] = source
            }
        }
        return Permutation(sources: sources)
    }
}
