// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Sources.swift
// dependencies: [Permutation/Permutation.swift]

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
}
