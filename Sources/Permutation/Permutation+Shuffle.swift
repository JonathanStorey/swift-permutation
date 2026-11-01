// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Shuffle.swift
// dependencies: [Permutation.swift]

extension Permutation {

    /// A way of shuffling `0..<count`, from uniformly random to perfectly deterministic.
    public enum Shuffle: CaseIterable, Hashable, Sendable {

        /// Every arrangement equally likely.
        case random

        /// A single cycle through every offset, each equally likely, so no offset stays in place and following the moves visits them all.
        case cyclic

        /// Every arrangement that leaves no offset in place equally likely.
        case derangement

        /// One riffle in the Gilbert–Shannon–Reeds model, built as the inverse of sorting offsets stably by a random bit each.
        case riffle

        /// A perfect riffle that keeps the first and last offsets in place.
        case outFaro

        /// A perfect riffle that moves the first and last offsets inward.
        case inFaro
    }

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

    /// Creates a permutation of `0..<count` shuffled in the given style.
    public init(shuffles count: Int, _ style: Shuffle) {
        var generator: SystemRandomNumberGenerator = SystemRandomNumberGenerator()
        self.init(shuffles: count, style, using: &generator)
    }

    /// Creates a permutation of `0..<count` shuffled in the given style, using the given generator as a source for randomness in the random styles.
    public init<R: RandomNumberGenerator>(shuffles count: Int, _ style: Shuffle, using generator: inout R) {
        precondition(count >= 0, "The count must not be negative.")
        self = Permutation.shuffling(count, style, using: &generator)
    }

    /// Creates the perfect riffle that interleaves the first `half` offsets with the rest, sending the first packet to every other offset starting at `firstStep`.
    private init(faro count: Int, half: Int, firstStep: Int) {
        self.init(tracing: count) { offset in offset < half ? 2 * offset + firstStep : 2 * (offset - half) + 1 - firstStep }
    }

    /// Creates the permutation that sends each offset of `0..<count` to the given destination, tracing each orbit of the formula into a cycle.
    private init(tracing count: Int, destination: (Int) -> Int) {
        var isVisited: [Bool] = [Bool](repeating: false, count: count)
        var cycles: [[Int]] = []
        for start in 0..<count where !isVisited[start] {
            var cycle: [Int] = []
            var offset: Int = start
            repeat {
                isVisited[offset] = true
                cycle.append(offset)
                offset = destination(offset)
            } while offset != start
            cycles.append(cycle)
        }
        self.init(cycles: cycles)
    }

    /// Returns a permutation of `0..<count` shuffled in the given style.
    private static func shuffling<R: RandomNumberGenerator>(_ count: Int, _ style: Shuffle, using generator: inout R) -> Permutation {
        switch style {
        case .random:
            return Permutation(shuffles: count, using: &generator)
        case .cyclic:
            guard count > 1 else { return Permutation(cycle: []) }
            return Permutation(cycle: [count - 1] + Array(0..<(count - 1)).shuffled(using: &generator))
        case .derangement:
            precondition(count != 1, "A single offset cannot be deranged.")
            while true {
                let candidate: Permutation = Permutation(shuffles: count, using: &generator)
                if candidate.cycle.count == count { return candidate }
            }
        case .riffle:
            var isSecond: [Bool] = []
            isSecond.reserveCapacity(count)
            for _ in 0..<count {
                isSecond.append(Bool.random(using: &generator))
            }
            let firstCount: Int = isSecond.lazy.filter { !$0 }.count
            var ranks: [Int] = []
            ranks.reserveCapacity(count)
            var firstRank: Int = 0
            var secondRank: Int = firstCount
            for offset in 0..<count {
                if isSecond[offset] {
                    ranks.append(secondRank)
                    secondRank += 1
                } else {
                    ranks.append(firstRank)
                    firstRank += 1
                }
            }
            return Permutation(tracing: count) { ranks[$0] }.inverted
        case .outFaro:
            return Permutation(faro: count, half: (count + 1) / 2, firstStep: 0)
        case .inFaro:
            return Permutation(faro: count, half: count / 2, firstStep: 1)
        }
    }

    /// Replaces the permutation with one of `0..<minimumCount` shuffled in the given style, and returns the new permutation.
    @discardableResult public mutating func shuffle(_ style: Shuffle = .random) -> Permutation {
        self = Permutation(shuffles: minimumCount, style)
        return self
    }

    /// Replaces the permutation with one of `0..<minimumCount` shuffled in the given style, using the given generator as a source for randomness, and returns the new permutation.
    @discardableResult public mutating func shuffle<R: RandomNumberGenerator>(_ style: Shuffle = .random, using generator: inout R) -> Permutation {
        self = Permutation(shuffles: minimumCount, style, using: &generator)
        return self
    }

    /// Returns a permutation of `0..<minimumCount` shuffled in the given style.
    public func shuffled(_ style: Shuffle = .random) -> Permutation {
        Permutation(shuffles: minimumCount, style)
    }

    /// Returns a permutation of `0..<minimumCount` shuffled in the given style, using the given generator as a source for randomness.
    public func shuffled<R: RandomNumberGenerator>(_ style: Shuffle = .random, using generator: inout R) -> Permutation {
        Permutation(shuffles: minimumCount, style, using: &generator)
    }
}
