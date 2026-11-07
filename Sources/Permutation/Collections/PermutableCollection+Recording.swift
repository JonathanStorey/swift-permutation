// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection+Recording.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+Composition.swift, Permutation/Permutation.swift]

// Every reorder also comes in a form that records what it did into a permutation you keep, so a running history builds up across many calls:
//
//     var history: Permutation = Permutation()
//     tiles.sort(recording: &history)
//     tiles.move(from: 2, to: 0, recording: &history)
//     tiles.apply(history.inverted)    // undoes both
//
// Each call replaces `history` with `history.followed(by:)` the permutation it applied, so applying `history` to the collection as it was before the first call gives the collection as it is now. The history describes positions, so it stays valid only while the collection is reordered. After an insertion or removal, keep it in step with `insert(at:)`, `remove(at:)` or `replaceSubrange(_:withCount:)`.

extension Permutation {

    /// Appends the next permutation to this history, so the history then applies itself and then the next.
    @inlinable mutating func record(_ next: Permutation) {
        guard !next.cycle.isEmpty else { return }
        self = cycle.isEmpty ? next : followed(by: next)
    }
}

public extension PermutableCollection {

    /// Applies the permutation and appends it to the history.
    @inlinable mutating func apply(_ permutation: Permutation, recording history: inout Permutation) {
        apply(permutation)
        history.record(permutation)
    }

    /// Exchanges the elements at the two indices and appends the swap to the history.
    @inlinable mutating func swap(_ i: Index, _ j: Index, recording history: inout Permutation) {
        history.record(swap(i, j))
    }

    /// Moves the element at the source index to the destination index and appends the move to the history.
    @inlinable mutating func move(from source: Index, to destination: Index, recording history: inout Permutation) {
        history.record(move(from: source, to: destination))
    }

    /// Moves the elements at the offsets to just before the destination offset, keeping their relative order, and appends the move to the history.
    @inlinable mutating func move(fromOffsets source: some Sequence<Int>, toOffset destination: Int, recording history: inout Permutation) {
        history.record(move(fromOffsets: source, toOffset: destination))
    }

    /// Moves the elements that satisfy the predicate after those that do not, keeping the relative order within each group, appends the partition to the history, and returns the index of the first moved element.
    @inlinable @discardableResult mutating func stablePartition(by belongsInSecondPartition: (Element) throws -> Bool, recording history: inout Permutation) rethrows -> Index {
        let total: Int = count
        var sources: [Int] = [Int](repeating: 0, count: total)
        var low: Int = 0
        var high: Int = total
        for (offset, element) in enumerated() {
            if try belongsInSecondPartition(element) {
                high -= 1
                sources[high] = offset
            } else {
                sources[low] = offset
                low += 1
            }
        }
        sources[low...].reverse()
        let partition: Permutation = Permutation(sources: sources)
        apply(partition)
        history.record(partition)
        return index(startIndex, offsetBy: low)
    }

    /// Reverses the elements in place and appends the reversal to the history.
    @inlinable mutating func reverse(recording history: inout Permutation) {
        history.record(apply(returning: Permutation(reversing: count)))
    }

    /// Rotates the elements so the element at the index becomes the first, and appends the rotation to the history.
    @inlinable mutating func rotate(toStartAt newStart: Index, recording history: inout Permutation) {
        history.record(rotate(toStartAt: newStart))
    }

    /// Shuffles the elements in the given style and appends the shuffle to the history.
    @inlinable mutating func shuffle(_ style: Permutation.Shuffle = .random, recording history: inout Permutation) {
        history.record(apply(returning: style == .random ? Permutation(shuffles: count) : Permutation(shuffles: count, style)))
    }

    /// Shuffles the elements in the given style, using the given generator as a source for randomness, and appends the shuffle to the history.
    @inlinable mutating func shuffle<R: RandomNumberGenerator>(_ style: Permutation.Shuffle = .random, using generator: inout R, recording history: inout Permutation) {
        history.record(shuffle(style, using: &generator))
    }

    /// Sorts the elements in place and appends the sort to the history.
    @inlinable mutating func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool, recording history: inout Permutation) rethrows {
        let elements: [Element] = Array(self)
        history.record(try apply(sources: elements.indices.sorted { try areInIncreasingOrder(elements[$0], elements[$1]) }))
    }
}

public extension PermutableCollection where Element: Comparable {

    /// Sorts the elements in ascending order and appends the sort to the history.
    @inlinable mutating func sort(recording history: inout Permutation) {
        sort(by: <, recording: &history)
    }
}
