// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Shuffleable.swift
// dependencies: [PermutableCollection.swift, Permutation.swift]

extension Permutation {

    /// Creates a uniformly random permutation of `0..<count` by shuffling the Foata line directly.
    @inlinable public init(shuffles count: Int) {
        var generator: SystemRandomNumberGenerator = SystemRandomNumberGenerator()
        self.init(shuffles: count, using: &generator)
    }

    /// Creates a uniformly random permutation of `0..<count` by shuffling the Foata line directly, using the given generator as a source for randomness.
    @inlinable public init<R: RandomNumberGenerator>(shuffles count: Int, using generator: inout R) {
        precondition(count >= 0, "The count must not be negative.")
        var line: [Int] = Array(0..<count)
        line.shuffle(using: &generator)
        var kept: Int = 0
        var largest: Int = -1
        for position in line.indices {
            let offset: Int = line[position]
            if offset > largest {
                largest = offset
                if position == line.count - 1 || line[position + 1] > offset { continue }
            }
            line[kept] = offset
            kept += 1
        }
        line.removeLast(line.count - kept)
        self.init(cycle: line)
    }
}

/// A value that can rearrange itself into a uniformly random order, with the same shuffling API as `MutableCollection`.
public protocol Shuffleable {

    /// Rearranges the value into a uniformly random order, using the given generator as a source for randomness.
    mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R)
}

public extension Shuffleable {

    /// Rearranges the value into a uniformly random order.
    @inlinable mutating func shuffle() {
        var generator: SystemRandomNumberGenerator = SystemRandomNumberGenerator()
        shuffle(using: &generator)
    }

    /// Returns a copy of the value in a uniformly random order.
    @inlinable func shuffled() -> Self {
        var generator: SystemRandomNumberGenerator = SystemRandomNumberGenerator()
        return shuffled(using: &generator)
    }

    /// Returns a copy of the value in a uniformly random order, using the given generator as a source for randomness.
    @inlinable func shuffled<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        var copy: Self = self
        copy.shuffle(using: &generator)
        return copy
    }
}

extension Permutation: Shuffleable {

    /// Replaces the permutation with a uniformly random permutation of `0..<minimumCount`, using the given generator as a source for randomness.
    @inlinable public mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R) {
        self = Permutation(shuffles: minimumCount, using: &generator)
    }
}

public extension PermutableCollection {

    /// Shuffles the elements in place through a permutation shuffled directly in cycle form, and returns the permutation applied.
    @inlinable @discardableResult mutating func shuffle() -> Permutation {
        permute(returning: Permutation(shuffles: count))
    }

    /// Shuffles the elements in place, giving the same order as `Array.shuffle(using:)` with the same generator state, and returns the permutation applied.
    @inlinable @discardableResult mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R) -> Permutation {
        var sources: [Int] = Array(0..<count)
        sources.shuffle(using: &generator)
        return permute(sources: sources)
    }
}
