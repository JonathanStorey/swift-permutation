// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Sources.swift
// dependencies: [Permutation/Permutation.swift]

extension Permutation {

    /// Creates a permutation where `sources[i]` is the offset whose element moves into `i`, writing each cycle from the back in one walk without validating the mapping.
    @inlinable init(sources: [Int]) {
        self.init(sources: sources, shiftedBy: 0)
    }

    /// Creates a permutation from sources that describe a window starting at `shift`, adding `shift` to every offset as it is written. Adding a constant keeps every cycle's largest offset first and the cycles in order, so the line stays in Foata form.
    @inlinable init(sources: [Int], shiftedBy shift: Int) {
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
                line[end] = offset + shift
                offset = sources[offset]
            }
            end -= 1
            line[end] = start + shift
        }
        line.removeSubrange(..<end)
        self.init(cycle: line)
    }

    /// The source of every offset in `0..<count`, so `sources[i]` is the offset whose element moves into `i`, read straight off the line in one pass: inside a cycle each offset receives from the one before it, and the cycle's largest offset receives from its last.
    @inlinable func sources(count: Int) -> [Int] {
        var sources: [Int] = Array(0..<count)
        var root: Int = -1
        var previous: Int = -1
        for offset in cycle {
            if offset > root {
                if root >= 0 { sources[root] = previous }
                root = offset
            } else {
                sources[offset] = previous
            }
            previous = offset
        }
        if root >= 0 { sources[root] = previous }
        return sources
    }

    /// Whether a dense array over `0..<count` beats hashing for permutations moving `support` offsets in all. Dense wins unless the offsets are scattered far apart, such as a swap of two distant offsets.
    @inlinable static func prefersDense(count: Int, support: Int) -> Bool {
        count <= 4 * support + 64
    }
}
