// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Sources.swift
// dependencies: [Permutation.swift]

extension Permutation {

    /// Creates a permutation where `sources[i]` is the offset whose element moves into `i`, writing each cycle from the back in one walk without validating the mapping.
    @inlinable init(sources: [Int]) {
        var isVisited: [Bool] = [Bool](repeating: false, count: sources.count)
        var line: [Int] = [Int](repeating: 0, count: sources.count)
        var end: Int = sources.count
        for start in sources.indices.reversed() where !isVisited[start] {
            isVisited[start] = true
            var offset: Int = sources[start]
            guard offset != start else { continue }
            while offset != start {
                isVisited[offset] = true
                end -= 1
                line[end] = offset
                offset = sources[offset]
            }
            end -= 1
            line[end] = start
        }
        line.removeSubrange(..<end)
        self.init(cycle: line)
    }

    /// Returns the offset each element of `0..<count` moves to, walking the cycles once.
    func destinations(count: Int) -> [Int] {
        var destinations: [Int] = Array(0..<count)
        var start: Int = -1
        var previous: Int = -1
        for offset in cycle {
            if offset > start {
                if start >= 0 { destinations[previous] = start }
                start = offset
            } else {
                destinations[previous] = offset
            }
            previous = offset
        }
        if start >= 0 { destinations[previous] = start }
        return destinations
    }
}
