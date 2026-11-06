// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Stride.swift
// dependencies: [Permutation/Permutation.swift]

extension Permutation {

    /// Replaces the permutation with the one that applies it `distance` times, and returns the new permutation.
    @discardableResult public mutating func advance(by distance: Int) -> Permutation {
        self = advanced(by: distance)
        return self
    }

    /// Returns the permutation that applies this one `distance` times, so a negative distance applies the inverse.
    ///
    /// Within a cycle of length `L`, the element at position `j` lands at position `j + distance` modulo `L`, so each cycle splits into `gcd(L, distance)` cycles that step `distance` positions at a time. Each is written straight onto the new line starting at its largest offset. A cycle that does not split keeps its largest offset and its place, so the line is already in Foata form unless some cycle split, and then only the cycles are reordered by their largest offsets, never the offsets themselves.
    public func advanced(by distance: Int) -> Permutation {
        var line: [Int] = []
        line.reserveCapacity(cycle.count)
        var roots: [Int] = []
        var starts: [Int] = []
        var didSplit: Bool = false
        var blockStart: Int = 0
        var root: Int = -1
        for position in 0...cycle.count {
            guard position == cycle.count || cycle[position] > root else { continue }
            let length: Int = position - blockStart
            if length > 1 {
                let step: Int = (distance % length + length) % length
                if step != 0 {
                    var divisor: Int = length
                    var remainder: Int = step
                    while remainder != 0 {
                        (divisor, remainder) = (remainder, divisor % remainder)
                    }
                    if divisor > 1 { didSplit = true }
                    let period: Int = length / divisor
                    for start in 0..<divisor {
                        var index: Int = start
                        var largest: Int = -1
                        var largestIndex: Int = start
                        for _ in 0..<period {
                            if cycle[blockStart + index] > largest {
                                largest = cycle[blockStart + index]
                                largestIndex = index
                            }
                            index += step
                            if index >= length { index -= length }
                        }
                        roots.append(largest)
                        starts.append(line.count)
                        index = largestIndex
                        for _ in 0..<period {
                            line.append(cycle[blockStart + index])
                            index += step
                            if index >= length { index -= length }
                        }
                    }
                }
            }
            if position < cycle.count {
                root = cycle[position]
                blockStart = position
            }
        }
        guard didSplit else { return Permutation(cycle: line) }
        let order: [Int] = roots.indices.sorted { roots[$0] < roots[$1] }
        var sorted: [Int] = []
        sorted.reserveCapacity(line.count)
        for cycleIndex in order {
            let end: Int = cycleIndex + 1 < starts.count ? starts[cycleIndex + 1] : line.count
            sorted.append(contentsOf: line[starts[cycleIndex]..<end])
        }
        return Permutation(cycle: sorted)
    }
}
