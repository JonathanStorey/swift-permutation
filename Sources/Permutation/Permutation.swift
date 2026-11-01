// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation.swift
// dependencies: []

/// A reordering stored as cycles in Foata's single-line notation, leaving offsets outside the cycles in place so it applies to any collection long enough.
public struct Permutation: Hashable, Sendable {

    /// The cycles written one after another, each starting with its largest offset, in increasing order of those starting offsets.
    public let cycle: [Int]

    /// Creates the permutation that reverses `0..<count`, writing each swapped pair directly with its larger offset first.
    @inlinable @usableFromInline init(reversing count: Int) {
        var line: [Int] = []
        line.reserveCapacity(count)
        for offset in (0..<(count / 2)).reversed() {
            line.append(count - 1 - offset)
            line.append(offset)
        }
        cycle = line
    }

    /// Creates the permutation that moves the element at offset `shift` to the front of `0..<count`, writing one cycle per residue class modulo the greatest common divisor.
    @inlinable @usableFromInline init(rotating count: Int, by shift: Int) {
        guard count > 0, shift % count != 0 else {
            cycle = []
            return
        }
        let step: Int = (shift % count + count) % count
        var divisor: Int = count
        var remainder: Int = step
        while remainder != 0 {
            (divisor, remainder) = (remainder, divisor % remainder)
        }
        var line: [Int] = []
        line.reserveCapacity(count)
        for start in (count - divisor)..<count {
            var offset: Int = start
            repeat {
                line.append(offset)
                offset = offset >= step ? offset - step : offset + count - step
            } while offset != start
        }
        cycle = line
    }

    /// Creates a permutation where `sources[i]` is the offset whose element moves into `i`, writing each cycle from the back in one walk without validating the mapping.
    @inlinable @usableFromInline init(sources: [Int]) {
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
        cycle = line
    }

    /// Creates a permutation from a line already in Foata's single-line notation.
    @inlinable @usableFromInline init(cycle: [Int]) {
        self.cycle = cycle
    }

    /// The permutation that undoes this one, made by reversing each cycle after its largest offset.
    public var inverted: Permutation {
        var line: [Int] = cycle
        var blockStart: Int = 0
        var largest: Int = -1
        for position in line.indices where line[position] > largest {
            largest = line[position]
            if position > blockStart + 1 { line[(blockStart + 1)..<position].reverse() }
            blockStart = position
        }
        if line.count > blockStart + 1 { line[(blockStart + 1)...].reverse() }
        return Permutation(cycle: line)
    }

    /// The smallest collection count this permutation can be applied to, one more than its largest offset.
    public var minimumCount: Int {
        (cycle.max() ?? -1) + 1
    }

    /// Calls the closure with each pair of offsets to swap, in order, deriving them in one pass with no allocation.
    @inlinable @usableFromInline func forEachSwap(_ body: (Int, Int) throws -> Void) rethrows {
        var start: Int = -1
        for offset in cycle {
            if offset > start {
                start = offset
            } else {
                try body(start, offset)
            }
        }
    }
}

extension Permutation {

    /// Returns the permutation that applies this permutation and then the next, over the larger of their minimum counts.
    public func squashed(with next: Permutation) -> Permutation {
        let count: Int = Swift.max(minimumCount, next.minimumCount)
        let first: [Int] = destinations(count: count)
        let second: [Int] = next.destinations(count: count)
        var sources: [Int] = Array(0..<count)
        for offset in sources.indices {
            sources[second[first[offset]]] = offset
        }
        return Permutation(sources: sources)
    }

    /// Returns the offset each element of `0..<count` moves to, walking the cycles once.
    private func destinations(count: Int) -> [Int] {
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
