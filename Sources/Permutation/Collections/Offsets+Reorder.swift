// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Offsets+Reorder.swift
// dependencies: [Collections/Offsets.swift]

// Reorders that rewrite the table of storage offsets directly, for the calls that discard the permutation.
//
// - A collection's `move`, `reverse`, `rotate`, `shuffle` and `sort` return the `Permutation` they applied, which costs building it.
// - When the caller ignores that result, the collection calls these instead: each rewrites the 4-byte offsets in place and builds no permutation.

extension Offsets {

    /// Moves the offset at `source` so it ends up at `destination`, shifting the offsets between them with one block copy.
    @inlinable mutating func moveOffset(from source: Int, to destination: Int) {
        precondition((0..<count).contains(source) && (0..<count).contains(destination), "Both offsets must be within the collection.")
        guard source != destination else { return }
        materialize()
        storedSources.withUnsafeMutableBufferPointer { buffer in
            let base: UnsafeMutablePointer<Int32> = buffer.baseAddress!
            let moved: Int32 = base[source]
            if source < destination {
                (base + source).update(from: base + source + 1, count: destination - source)
            } else {
                (base + destination + 1).update(from: base + destination, count: source - destination)
            }
            base[destination] = moved
        }
    }

    /// Reverses the order of the offsets.
    @inlinable mutating func reverseOffsets() {
        guard count > 1 else { return }
        materialize()
        storedSources.reverse()
    }

    /// Rotates the offsets so the one at `newStart` comes first, by reversing both parts and then the whole.
    @inlinable mutating func rotateOffsets(toStartAt newStart: Int) {
        precondition((0...count).contains(newStart), "The new start must be within the collection.")
        guard newStart != 0 && newStart != count else { return }
        materialize()
        storedSources[..<newStart].reverse()
        storedSources[newStart...].reverse()
        storedSources.reverse()
    }

    /// Shuffles the offsets, drawing from the generator exactly as `Array.shuffle(using:)` does, so the order matches an array shuffled with the same generator.
    @inlinable mutating func shuffleOffsets<R: RandomNumberGenerator>(using generator: inout R) {
        guard count > 1 else { return }
        materialize()
        storedSources.shuffle(using: &generator)
    }

    /// Sorts the offsets by comparing the storage offsets they show, keeping the current order of equal elements.
    @inlinable mutating func sortOffsets(by areInIncreasingOrder: (Int, Int) throws -> Bool) rethrows {
        guard count > 1 else { return }
        materialize()
        try storedSources.sort { try areInIncreasingOrder(Int($0), Int($1)) }
    }
}
