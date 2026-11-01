// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Shuffleable.swift
// dependencies: [Permutation.swift]

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

/// The shuffling API that `Permutation` and every `PermutableCollection` share, kept internal so it only checks that their signatures match.
protocol Shuffleable {

    /// Rearranges the value into a uniformly random order, and returns the permutation applied.
    @discardableResult mutating func shuffle() -> Permutation

    /// Rearranges the value into a uniformly random order, using the given generator as a source for randomness, and returns the permutation applied.
    @discardableResult mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R) -> Permutation

    /// Returns a copy of the value in a uniformly random order.
    func shuffled() -> Self

    /// Returns a copy of the value in a uniformly random order, using the given generator as a source for randomness.
    func shuffled<R: RandomNumberGenerator>(using generator: inout R) -> Self
}

extension Permutation: Shuffleable {

    /// Replaces the permutation with a uniformly random permutation of `0..<minimumCount`, and returns the new permutation.
    @inlinable @discardableResult public mutating func shuffle() -> Permutation {
        self = Permutation(shuffles: minimumCount)
        return self
    }

    /// Replaces the permutation with a uniformly random permutation of `0..<minimumCount`, using the given generator as a source for randomness, and returns the new permutation.
    @inlinable @discardableResult public mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R) -> Permutation {
        self = Permutation(shuffles: minimumCount, using: &generator)
        return self
    }

    /// Returns a uniformly random permutation of `0..<minimumCount`.
    @inlinable public func shuffled() -> Permutation {
        Permutation(shuffles: minimumCount)
    }

    /// Returns a uniformly random permutation of `0..<minimumCount`, using the given generator as a source for randomness.
    @inlinable public func shuffled<R: RandomNumberGenerator>(using generator: inout R) -> Permutation {
        Permutation(shuffles: minimumCount, using: &generator)
    }
}
