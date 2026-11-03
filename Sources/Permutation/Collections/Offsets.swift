// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Offsets.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation.swift]

/// The order and hash index of a keyed collection whose elements stay where they were stored.
///
/// As a collection, `Offsets` is the storage offset of the element at each position, so reordering it reorders its owner without moving an element. Behind it sits an open-addressing hash table of storage offsets, which a reorder never touches.
///
/// `Offsets` never stores an element or a key. Every call that reads or changes membership takes the owner's elements and a key function, which must be the same on every call.
@usableFromInline struct Offsets {

    /// Storage offsets placed by the hash of their element's key with linear probing, where -1 marks an empty bucket. Its count is zero or a power of two.
    @usableFromInline var table: [Int32]

    /// The storage offset at each position.
    @usableFromInline var sources: [Int32]

    /// Creates empty offsets.
    @inlinable init() {
        table = []
        sources = []
    }
}

// MARK: - Collection

extension Offsets: RandomAccessCollection {

    @inlinable var startIndex: Int { 0 }

    @inlinable var endIndex: Int { sources.count }

    /// The storage offset of the element at the position.
    @inlinable subscript(position: Int) -> Int {
        Int(sources[position])
    }
}

// MARK: - PermutableCollection

extension Offsets: PermutableCollection {

    /// Applies the permutation by rotating each cycle of `sources` through one carried offset, leaving the table untouched.
    @inlinable mutating func apply(_ permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        precondition(permutation.minimumCount <= count, "Every offset in the cycle must be within the collection.")
        var start: Int = -1
        var carried: Int32 = 0
        for offset in permutation.cycle {
            if offset > start {
                if start >= 0 { sources[start] = carried }
                start = offset
                carried = sources[offset]
            } else {
                let next: Int32 = sources[offset]
                sources[offset] = carried
                carried = next
            }
        }
        sources[start] = carried
    }

    /// Exchanges the storage offsets at the two positions.
    @inlinable mutating func swapAt(_ i: Int, _ j: Int) {
        sources.swapAt(i, j)
    }
}

// MARK: - Lookup

extension Offsets {

    /// The storage offset of the element with the key, or nil when there is none.
    @inlinable func offset<Element, Key: Hashable>(of key: Key, in elements: [Element], by keyOf: (Element) -> Key) -> Int? {
        bucket(of: key, in: elements, by: keyOf).map { Int(table[$0]) }
    }

    /// The position showing the storage offset, in O(n).
    @inlinable func position(ofOffset offset: Int) -> Int? {
        sources.firstIndex(of: Int32(truncatingIfNeeded: offset))
    }
}

// MARK: - Changing membership

extension Offsets {

    /// Stores the element and shows it at the position unless its key is already present, returning whether it was added.
    @inlinable mutating func insert<Element, Key: Hashable>(_ element: Element, at position: Int, into elements: inout [Element], by keyOf: (Element) -> Key) -> Bool {
        precondition(position >= startIndex && position <= endIndex, "Index out of range.")
        let key: Key = keyOf(element)
        guard bucket(of: key, in: elements, by: keyOf) == nil else { return false }
        precondition(elements.count < Int(Int32.max), "Offsets holds at most Int32.max elements.")
        elements.append(element)
        let offset: Int = elements.count - 1
        if elements.count * 4 > table.count * 3 {
            rebuild(for: elements, by: keyOf)
        } else {
            place(offset, hash: key.hashValue)
        }
        sources.insert(Int32(truncatingIfNeeded: offset), at: position)
        return true
    }

    /// Removes and returns the element at the position, moving the last stored element into its storage offset.
    @inlinable mutating func remove<Element, Key: Hashable>(at position: Int, from elements: inout [Element], by keyOf: (Element) -> Key) -> Element {
        let offset: Int = Int(sources.remove(at: position))
        let removed: Element = elements[offset]
        empty(bucket(holding: offset, hash: keyOf(removed).hashValue), in: elements, by: keyOf)
        let last: Int = elements.count - 1
        if offset != last {
            table[bucket(holding: last, hash: keyOf(elements[last]).hashValue)] = Int32(truncatingIfNeeded: offset)
            sources[self.position(ofOffset: last)!] = Int32(truncatingIfNeeded: offset)
            elements.swapAt(offset, last)
        }
        elements.removeLast()
        return removed
    }

    /// Replaces the element at the storage offset and returns the old one, re-indexing it when its key changes, which requires that no other element has the new key.
    @inlinable mutating func replace<Element, Key: Hashable>(offset: Int, with element: Element, in elements: inout [Element], by keyOf: (Element) -> Key) -> Element {
        let old: Element = elements[offset]
        let oldKey: Key = keyOf(old)
        let newKey: Key = keyOf(element)
        guard oldKey != newKey else {
            elements[offset] = element
            return old
        }
        precondition(bucket(of: newKey, in: elements, by: keyOf) == nil, "Another element already has this key.")
        empty(bucket(holding: offset, hash: oldKey.hashValue), in: elements, by: keyOf)
        elements[offset] = element
        place(offset, hash: newKey.hashValue)
        return old
    }

    /// Removes every offset and releases the table.
    @inlinable mutating func removeAll() {
        table = []
        sources = []
    }
}

// MARK: - Hash table

extension Offsets {

    /// The bitmask that wraps a hash or bucket into the table.
    @inlinable var mask: Int { table.count - 1 }

    /// The bucket holding the element with the key, or nil when there is none.
    @inlinable func bucket<Element, Key: Hashable>(of key: Key, in elements: [Element], by keyOf: (Element) -> Key) -> Int? {
        guard !table.isEmpty else { return nil }
        var bucket: Int = key.hashValue & mask
        while true {
            let offset: Int32 = table[bucket]
            if offset < 0 { return nil }
            if keyOf(elements[Int(offset)]) == key { return bucket }
            bucket = (bucket + 1) & mask
        }
    }

    /// The bucket holding the storage offset, found by probing from its element's hash.
    @inlinable func bucket(holding offset: Int, hash: Int) -> Int {
        let target: Int32 = Int32(truncatingIfNeeded: offset)
        var bucket: Int = hash & mask
        while table[bucket] != target { bucket = (bucket + 1) & mask }
        return bucket
    }

    /// Puts the storage offset in the first empty bucket probing from the hash.
    @inlinable mutating func place(_ offset: Int, hash: Int) {
        var bucket: Int = hash & mask
        while table[bucket] >= 0 { bucket = (bucket + 1) & mask }
        table[bucket] = Int32(truncatingIfNeeded: offset)
    }

    /// Empties the bucket and shifts later entries of the same probe run back, so no lookup stops early at the gap.
    @inlinable mutating func empty<Element, Key: Hashable>(_ bucket: Int, in elements: [Element], by keyOf: (Element) -> Key) {
        var hole: Int = bucket
        var next: Int = (hole + 1) & mask
        while table[next] >= 0 {
            let ideal: Int = keyOf(elements[Int(table[next])]).hashValue & mask
            if (next - ideal) & mask >= (next - hole) & mask {
                table[hole] = table[next]
                hole = next
            }
            next = (next + 1) & mask
        }
        table[hole] = -1
    }

    /// Rebuilds the table at the smallest power of two that keeps it at most three-quarters full.
    @inlinable mutating func rebuild<Element, Key: Hashable>(for elements: [Element], by keyOf: (Element) -> Key) {
        var capacity: Int = 8
        while elements.count * 4 > capacity * 3 { capacity *= 2 }
        table = Array(repeating: -1, count: capacity)
        for offset in elements.indices { place(offset, hash: keyOf(elements[offset]).hashValue) }
    }
}
