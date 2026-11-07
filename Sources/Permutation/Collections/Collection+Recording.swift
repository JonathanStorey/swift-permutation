// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Collection+Recording.swift
// dependencies: [Collections/Collection+Permutation.swift, Collections/PermutableCollection.swift, Permutation/Permutation+Composition.swift, Permutation/Permutation+Reverse.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

// The standard library's `sorted()`, `shuffled()` and `reversed()` return a new collection and forget how they built it. These overloads also record that reorder into a permutation you pass in, leaving the original collection untouched:
//
//     var order: Permutation = Permutation()
//     let ranked: [Int] = scores.sorted(by: >, recording: &order)
//     names.apply(order)    // puts a parallel array in the same order
//
// Each call replaces the permutation with itself followed by the reorder, so starting from `Permutation()` gives exactly the reorder that turns the original into the result, and a permutation that already holds earlier reorders keeps them. Any collection gets an array back. A `PermutableCollection` gets back its own type.

extension Permutation {

    /// Appends the next permutation, so this one then applies itself and then the next.
    @inlinable mutating func record(_ next: Permutation) {
        guard !next.cycle.isEmpty else { return }
        self = cycle.isEmpty ? next : followed(by: next)
    }
}

// MARK: - Any collection

public extension Collection {

    /// Returns the elements sorted by the predicate, keeping equal elements in their original order, and records the sort into the permutation.
    @inlinable func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool, recording permutation: inout Permutation) rethrows -> [Element] {
        let elements: [Element] = Array(self)
        let sources: [Int] = try elements.indices.sorted { try areInIncreasingOrder(elements[$0], elements[$1]) }
        permutation.record(Permutation(sources: sources))
        return sources.map { elements[$0] }
    }

    /// Returns the elements shuffled in the given style, and records the shuffle into the permutation.
    @inlinable func shuffled(_ style: Permutation.Shuffle = .random, recording permutation: inout Permutation) -> [Element] {
        let shuffle: Permutation = style == .random ? Permutation(shuffles: count) : Permutation(shuffles: count, style)
        permutation.record(shuffle)
        return applying(shuffle)
    }

    /// Returns the elements shuffled in the given style, using the given generator as a source for randomness, and records the shuffle into the permutation.
    @inlinable func shuffled<R: RandomNumberGenerator>(_ style: Permutation.Shuffle = .random, using generator: inout R, recording permutation: inout Permutation) -> [Element] {
        let shuffle: Permutation = Permutation(shuffles: count, style, using: &generator)
        permutation.record(shuffle)
        return applying(shuffle)
    }

    /// Returns the elements in reverse order, and records the reversal into the permutation.
    @inlinable func reversed(recording permutation: inout Permutation) -> [Element] {
        let reversal: Permutation = Permutation(reversing: count)
        permutation.record(reversal)
        return applying(reversal)
    }
}

public extension Collection where Element: Comparable {

    /// Returns the elements in ascending order, keeping equal elements in their original order, and records the sort into the permutation.
    @inlinable func sorted(recording permutation: inout Permutation) -> [Element] {
        sorted(by: <, recording: &permutation)
    }
}

// MARK: - PermutableCollection

public extension PermutableCollection {

    /// Returns a copy sorted by the predicate, keeping equal elements in their original order, and records the sort into the permutation.
    @inlinable func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool, recording permutation: inout Permutation) rethrows -> Self {
        var copy: Self = self
        let elements: [Element] = Array(self)
        let sort: Permutation = Permutation(sources: try elements.indices.sorted { try areInIncreasingOrder(elements[$0], elements[$1]) })
        copy.apply(sort)
        permutation.record(sort)
        return copy
    }

    /// Returns a copy shuffled in the given style, and records the shuffle into the permutation.
    @inlinable func shuffled(_ style: Permutation.Shuffle = .random, recording permutation: inout Permutation) -> Self {
        let shuffle: Permutation = style == .random ? Permutation(shuffles: count) : Permutation(shuffles: count, style)
        permutation.record(shuffle)
        return applying(shuffle)
    }

    /// Returns a copy shuffled in the given style, using the given generator as a source for randomness, and records the shuffle into the permutation.
    @inlinable func shuffled<R: RandomNumberGenerator>(_ style: Permutation.Shuffle = .random, using generator: inout R, recording permutation: inout Permutation) -> Self {
        let shuffle: Permutation = Permutation(shuffles: count, style, using: &generator)
        permutation.record(shuffle)
        return applying(shuffle)
    }

    /// Returns a copy in reverse order, and records the reversal into the permutation.
    @inlinable func reversed(recording permutation: inout Permutation) -> Self {
        let reversal: Permutation = Permutation(reversing: count)
        permutation.record(reversal)
        return applying(reversal)
    }
}

public extension PermutableCollection where Element: Comparable {

    /// Returns a copy in ascending order, keeping equal elements in their original order, and records the sort into the permutation.
    @inlinable func sorted(recording permutation: inout Permutation) -> Self {
        sorted(by: <, recording: &permutation)
    }
}
