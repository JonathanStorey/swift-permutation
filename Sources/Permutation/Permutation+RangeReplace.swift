// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+RangeReplace.swift
// dependencies: [Permutation+Sources.swift, Permutation.swift]

extension Permutation {

    /// Inserts one fixed offset at the given offset, shifting every offset at or after it up by one.
    public mutating func insert(at offset: Int) {
        replaceSubrange(offset..<offset, withCount: 1)
    }

    /// Inserts the given number of fixed offsets at the given offset, shifting every offset at or after it up by that number.
    public mutating func insert(count newCount: Int, at offset: Int) {
        replaceSubrange(offset..<offset, withCount: newCount)
    }

    /// Removes the offset from its cycle and shifts every later offset down by one.
    public mutating func remove(at offset: Int) {
        replaceSubrange(offset..<(offset + 1), withCount: 0)
    }

    /// Removes the offsets in the range from their cycles and shifts every later offset down by the range's count.
    public mutating func removeSubrange(_ range: Range<Int>) {
        replaceSubrange(range, withCount: 0)
    }

    /// Splices each offset in the range out of its cycle, shifts every later offset by the change in count, and leaves the new offsets in place.
    public mutating func replaceSubrange(_ range: Range<Int>, withCount newCount: Int) {
        precondition(range.lowerBound >= 0, "The range must not contain negative offsets.")
        precondition(newCount >= 0, "The new count must not be negative.")
        let count: Int = Swift.max(minimumCount, range.upperBound)
        var destinations: [Int] = self.destinations(count: count)
        var sources: [Int] = Array(0..<count)
        for offset in sources.indices {
            sources[destinations[offset]] = offset
        }
        for offset in range where destinations[offset] != offset {
            let previous: Int = sources[offset]
            let next: Int = destinations[offset]
            destinations[previous] = next
            sources[next] = previous
        }
        let shift: Int = newCount - range.count
        let shifted: (Int) -> Int = { offset in offset < range.lowerBound ? offset : offset + shift }
        var replaced: [Int] = Array(0..<(count + shift))
        for offset in 0..<count where !range.contains(offset) {
            replaced[shifted(destinations[offset])] = shifted(offset)
        }
        self = Permutation(sources: replaced)
    }
}
