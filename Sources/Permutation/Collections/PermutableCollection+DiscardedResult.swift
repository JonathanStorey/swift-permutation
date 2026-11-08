// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection+DiscardedResult.swift
// dependencies: [Collections/Arrangement.swift, Collections/IdentifiedSet.swift, Collections/Offsets+Reorder.swift, Collections/PermutableCollection.swift, Collections/PermutableDictionary.swift, Collections/PermutableSet.swift]

// The package's collections reorder a table of 4-byte offsets. Each reorder on `PermutableCollection` returns the
// `Permutation` it applied, and building that permutation can cost as much as the reorder itself.
//
// - Each collection here also declares the same reorders returning nothing. Swift picks these when a call discards its
//   result, so `set.move(from: 0, to: 9)` rewrites the offsets directly and builds no permutation.
// - A call whose result is used as a `Permutation`, as in `let undo: Permutation = set.move(from: 0, to: 9).inverted`,
//   still gets the version that returns it.
// - The two always produce the same order. Shuffles draw from the generator exactly as `Array.shuffle(using:)` does.

public extension Arrangement {

    /// Moves the element at the source position to the destination position, shifting the elements between them with one block copy of their offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func move(from source: Int, to destination: Int) {
        offsets.moveOffset(from: source, to: destination)
    }

    /// Moves the elements at the given offsets to just before the element at the destination offset, keeping their relative order. Only the offsets between the moved elements and the destination are rewritten. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func move(fromOffsets source: some Sequence<Int>, toOffset destination: Int) {
        offsets.moveOffsets(from: source, to: destination)
    }

    /// Reverses the order in place by reversing the offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func reverse() {
        offsets.reverseOffsets()
    }

    /// Rotates the order so the element at the given position comes first, by reversing the offsets in two parts and then whole. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func rotate(toStartAt newStart: Int) {
        offsets.rotateOffsets(toStartAt: newStart)
    }

    /// Shuffles the order uniformly at random by shuffling the offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func shuffle() {
        var generator: SystemRandomNumberGenerator = SystemRandomNumberGenerator()
        offsets.shuffleOffsets(using: &generator)
    }

    /// Shuffles the order uniformly at random by shuffling the offsets, giving the same order as `Array.shuffle(using:)` with the same generator. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R) {
        offsets.shuffleOffsets(using: &generator)
    }

    /// Sorts the order by sorting positions into a contiguous copy of the elements in their current order, then rewriting the offsets once. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows {
        let shown: [Element] = Array(self)
        try offsets.reorderOffsets(bySources: shown.indices.sorted { try areInIncreasingOrder(shown[$0], shown[$1]) })
    }

    /// Moves the elements that satisfy the predicate after those that do not, keeping the relative order within each group, by partitioning the offsets. Returns the index of the first moved element.
    @inlinable @discardableResult mutating func stablePartition(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> Int {
        let stored: [Element] = elements
        return try stored.withUnsafeBufferPointer { stored in
            try offsets.partitionOffsets { try belongsInSecondPartition(stored[$0]) }
        }
    }
}

public extension Arrangement where Element: Comparable {

    /// Sorts the order in ascending order. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort() {
        sort(by: <)
    }
}

public extension PermutableSet {

    /// Moves the element at the source position to the destination position, shifting the elements between them with one block copy of their offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func move(from source: Int, to destination: Int) {
        offsets.moveOffset(from: source, to: destination)
    }

    /// Moves the elements at the given offsets to just before the element at the destination offset, keeping their relative order. Only the offsets between the moved elements and the destination are rewritten. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func move(fromOffsets source: some Sequence<Int>, toOffset destination: Int) {
        offsets.moveOffsets(from: source, to: destination)
    }

    /// Reverses the order in place by reversing the offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func reverse() {
        offsets.reverseOffsets()
    }

    /// Rotates the order so the element at the given position comes first, by reversing the offsets in two parts and then whole. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func rotate(toStartAt newStart: Int) {
        offsets.rotateOffsets(toStartAt: newStart)
    }

    /// Shuffles the order uniformly at random by shuffling the offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func shuffle() {
        var generator: SystemRandomNumberGenerator = SystemRandomNumberGenerator()
        offsets.shuffleOffsets(using: &generator)
    }

    /// Shuffles the order uniformly at random by shuffling the offsets, giving the same order as `Array.shuffle(using:)` with the same generator. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R) {
        offsets.shuffleOffsets(using: &generator)
    }

    /// Sorts the order by sorting positions into a contiguous copy of the elements in their current order, then rewriting the offsets once. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows {
        let shown: [Element] = Array(self)
        try offsets.reorderOffsets(bySources: shown.indices.sorted { try areInIncreasingOrder(shown[$0], shown[$1]) })
    }

    /// Moves the elements that satisfy the predicate after those that do not, keeping the relative order within each group, by partitioning the offsets. Returns the index of the first moved element.
    @inlinable @discardableResult mutating func stablePartition(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> Int {
        let stored: [Element] = elements
        return try stored.withUnsafeBufferPointer { stored in
            try offsets.partitionOffsets { try belongsInSecondPartition(stored[$0]) }
        }
    }
}

public extension PermutableSet where Element: Comparable {

    /// Sorts the order in ascending order. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort() {
        sort(by: <)
    }
}

public extension IdentifiedSet {

    /// Moves the element at the source position to the destination position, shifting the elements between them with one block copy of their offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func move(from source: Int, to destination: Int) {
        offsets.moveOffset(from: source, to: destination)
    }

    /// Moves the elements at the given offsets to just before the element at the destination offset, keeping their relative order. Only the offsets between the moved elements and the destination are rewritten. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func move(fromOffsets source: some Sequence<Int>, toOffset destination: Int) {
        offsets.moveOffsets(from: source, to: destination)
    }

    /// Reverses the order in place by reversing the offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func reverse() {
        offsets.reverseOffsets()
    }

    /// Rotates the order so the element at the given position comes first, by reversing the offsets in two parts and then whole. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func rotate(toStartAt newStart: Int) {
        offsets.rotateOffsets(toStartAt: newStart)
    }

    /// Shuffles the order uniformly at random by shuffling the offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func shuffle() {
        var generator: SystemRandomNumberGenerator = SystemRandomNumberGenerator()
        offsets.shuffleOffsets(using: &generator)
    }

    /// Shuffles the order uniformly at random by shuffling the offsets, giving the same order as `Array.shuffle(using:)` with the same generator. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R) {
        offsets.shuffleOffsets(using: &generator)
    }

    /// Sorts the order by sorting positions into a contiguous copy of the elements in their current order, then rewriting the offsets once. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows {
        let shown: [Element] = Array(self)
        try offsets.reorderOffsets(bySources: shown.indices.sorted { try areInIncreasingOrder(shown[$0], shown[$1]) })
    }

    /// Moves the elements that satisfy the predicate after those that do not, keeping the relative order within each group, by partitioning the offsets. Returns the index of the first moved element.
    @inlinable @discardableResult mutating func stablePartition(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> Int {
        let stored: [Element] = elements
        return try stored.withUnsafeBufferPointer { stored in
            try offsets.partitionOffsets { try belongsInSecondPartition(stored[$0]) }
        }
    }
}

public extension IdentifiedSet where Element: Comparable {

    /// Sorts the order in ascending order. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort() {
        sort(by: <)
    }
}

public extension PermutableDictionary {

    /// Moves the element at the source position to the destination position, shifting the elements between them with one block copy of their offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func move(from source: Int, to destination: Int) {
        offsets.moveOffset(from: source, to: destination)
    }

    /// Moves the elements at the given offsets to just before the element at the destination offset, keeping their relative order. Only the offsets between the moved elements and the destination are rewritten. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func move(fromOffsets source: some Sequence<Int>, toOffset destination: Int) {
        offsets.moveOffsets(from: source, to: destination)
    }

    /// Reverses the order in place by reversing the offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func reverse() {
        offsets.reverseOffsets()
    }

    /// Rotates the order so the element at the given position comes first, by reversing the offsets in two parts and then whole. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func rotate(toStartAt newStart: Int) {
        offsets.rotateOffsets(toStartAt: newStart)
    }

    /// Shuffles the order uniformly at random by shuffling the offsets. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func shuffle() {
        var generator: SystemRandomNumberGenerator = SystemRandomNumberGenerator()
        offsets.shuffleOffsets(using: &generator)
    }

    /// Shuffles the order uniformly at random by shuffling the offsets, giving the same order as `Array.shuffle(using:)` with the same generator. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func shuffle<R: RandomNumberGenerator>(using generator: inout R) {
        offsets.shuffleOffsets(using: &generator)
    }

    /// Sorts the order by sorting the offsets, comparing the stored entries they show without copying any. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows {
        let keys: [Key] = keyStorage
        let values: [Value] = valueStorage
        let slots: [Int32] = valueSlots
        try offsets.sortOffsets { first, second in
            let firstValue: Int = slots.isEmpty ? first : Int(slots[first])
            let secondValue: Int = slots.isEmpty ? second : Int(slots[second])
            return try areInIncreasingOrder((key: keys[first], value: values[firstValue]), (key: keys[second], value: values[secondValue]))
        }
    }

    /// Moves the entries that satisfy the predicate after those that do not, keeping the relative order within each group, by partitioning the offsets. Returns the index of the first moved entry.
    @inlinable @discardableResult mutating func stablePartition(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> Int {
        let keys: [Key] = keyStorage
        let values: [Value] = valueStorage
        let slots: [Int32] = valueSlots
        return try offsets.partitionOffsets { slot in
            try belongsInSecondPartition((key: keys[slot], value: values[slots.isEmpty ? slot : Int(slots[slot])]))
        }
    }
}
