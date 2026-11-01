// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Shuffle.swift
// dependencies: [Permutation+Sources.swift, Permutation.swift]

extension Permutation {

    /// A way of shuffling `0..<count`, from uniformly random to perfectly deterministic.
    public enum Shuffle: CaseIterable, Hashable, Sendable {

        /// Every arrangement equally likely.
        case random

        /// A single cycle through every offset, each equally likely, so no offset stays in place and following the moves visits them all.
        case cyclic

        /// Every arrangement that leaves no offset in place equally likely.
        case derangement

        /// One riffle in the Gilbert–Shannon–Reeds model: cut at a binomial point and interleave, dropping from each packet in proportion to its size.
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
        switch style {
        case .random:
            self = Permutation(shuffles: count, using: &generator)
        case .cyclic:
            self = count < 2 ? Permutation(cycle: []) : Permutation(cycle: [count - 1] + Array(0..<(count - 1)).shuffled(using: &generator))
        case .derangement:
            precondition(count != 1, "A single offset cannot be deranged.")
            var candidate: Permutation
            repeat {
                candidate = Permutation(shuffles: count, using: &generator)
            } while candidate.cycle.count != count
            self = candidate
        case .riffle:
            let isSecond: [Bool] = (0..<count).map { _ in Bool.random(using: &generator) }
            let sources: [Int] = (0..<count).filter { !isSecond[$0] } + (0..<count).filter { isSecond[$0] }
            self = Permutation(sources: sources).inverted
        case .outFaro:
            self = Permutation(faro: count, half: (count + 1) / 2, firstStep: 0)
        case .inFaro:
            self = Permutation(faro: count, half: count / 2, firstStep: 1)
        }
    }

    /// Creates the perfect riffle that interleaves the first `half` offsets with the rest, sending the first packet to every other offset starting at `firstStep`, built by tracing each orbit of the interleaving.
    private init(faro count: Int, half: Int, firstStep: Int) {
        let secondStep: Int = 1 - firstStep
        let destination: (Int) -> Int = { offset in offset < half ? 2 * offset + firstStep : 2 * (offset - half) + secondStep }
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
