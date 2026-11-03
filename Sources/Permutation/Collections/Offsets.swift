// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Offsets.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation.swift]

/// The order and hash index of a keyed collection whose elements stay where they were stored.
///
/// As a collection, `Offsets` is the storage offset of the element at each position, so reordering it reorders its owner without moving an element. Behind it sits an open-addressing hash table of storage offsets, which a reorder never touches.
///
/// `Offsets` never stores an element or a key. Every call that reads or changes membership takes the owner's elements and a key function, which must be the same on every call.
@usableFromInline struct Offsets {

    /// Entries placed by the hash of their element's key with linear probing, where -1 marks an empty bucket. Each entry holds a storage offset in the bits that `mask` keeps and the top bits of its key's hash above them. Its count is zero or a power of two.
    @usableFromInline var table: [Int32]

    /// The storage offset at each position.
    @usableFromInline var sources: [Int32]

    /// Creates empty offsets.
    @inlinable init() {
        table = []
        sources = []
    }
}

extension Offsets: Sendable {}

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
        guard case .found(let bucket) = probe(for: key, hash: key.hashValue, in: elements, by: keyOf) else { return nil }
        return Int(table[bucket]) & mask
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
        let hash: Int = key.hashValue
        let probed: Probe = probe(for: key, hash: hash, in: elements, by: keyOf)
        guard case .empty(let bucket) = probed else { return false }
        precondition(elements.count < Int(Int32.max), "Offsets holds at most Int32.max elements.")
        elements.append(element)
        let offset: Int = elements.count - 1
        if elements.count * 4 > table.count * 3 {
            rebuild(for: elements, by: keyOf)
        } else {
            table[bucket] = entry(offset, hash: hash)
        }
        sources.insert(Int32(truncatingIfNeeded: offset), at: position)
        return true
    }

    /// Appends each element whose key is not already present, sizing the table once for the whole sequence.
    @inlinable mutating func append<Element, Key: Hashable>(contentsOf newElements: some Sequence<Element>, into elements: inout [Element], by keyOf: (Element) -> Key) {
        reserveCapacity(count + newElements.underestimatedCount, for: elements, by: keyOf)
        for element in newElements {
            _ = insert(element, at: endIndex, into: &elements, by: keyOf)
        }
    }

    /// Indexes elements already in storage, showing them in stored order and dropping any whose key repeats an earlier one, so a whole array is adopted without copying it.
    @inlinable mutating func index<Element, Key: Hashable>(_ elements: inout [Element], by keyOf: (Element) -> Key) {
        precondition(elements.count < Int(Int32.max), "Offsets holds at most Int32.max elements.")
        var capacity: Int = 8
        while elements.count * 4 > capacity * 3 { capacity *= 2 }
        table = Array(repeating: -1, count: capacity)
        var duplicates: [Int] = []
        for offset in elements.indices {
            let key: Key = keyOf(elements[offset])
            let hash: Int = key.hashValue
            switch probe(for: key, hash: hash, in: elements, by: keyOf) {
            case .found:
                duplicates.append(offset)
            case .empty(let bucket):
                table[bucket] = entry(offset, hash: hash)
            }
        }
        if !duplicates.isEmpty {
            var kept: [Element] = []
            kept.reserveCapacity(elements.count - duplicates.count)
            var next: Int = 0
            for offset in elements.indices {
                if next < duplicates.count && duplicates[next] == offset {
                    next += 1
                } else {
                    kept.append(elements[offset])
                }
            }
            elements = kept
            rebuild(for: elements, by: keyOf)
        }
        sources = (0..<Int32(truncatingIfNeeded: elements.count)).map { $0 }
    }

    /// Removes and returns the element at the position, moving the last stored element into its storage offset.
    @inlinable mutating func remove<Element, Key: Hashable>(at position: Int, from elements: inout [Element], by keyOf: (Element) -> Key) -> Element {
        let offset: Int32 = sources[position]
        let removed: Element = elements[Int(offset)]
        empty(bucket(holding: Int(offset), hash: keyOf(removed).hashValue), in: elements, by: keyOf)
        let last: Int32 = Int32(truncatingIfNeeded: elements.count - 1)
        if offset != last {
            let lastHash: Int = keyOf(elements[Int(last)]).hashValue
            table[bucket(holding: Int(last), hash: lastHash)] = entry(Int(offset), hash: lastHash)
            for earlier in 0..<position where sources[earlier] == last {
                sources[earlier] = offset
                break
            }
            elements.swapAt(Int(offset), Int(last))
        }
        for later in position..<(sources.count - 1) {
            let source: Int32 = sources[later + 1]
            sources[later] = source == last ? offset : source
        }
        sources.removeLast()
        elements.removeLast()
        return removed
    }

    /// Removes every element that matches, then stores the rest in their shown order and rebuilds the table once.
    @inlinable mutating func removeAll<Element, Key: Hashable>(from elements: inout [Element], by keyOf: (Element) -> Key, where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        var kept: [Element] = []
        kept.reserveCapacity(count)
        for offset in sources {
            let element: Element = elements[Int(offset)]
            if try !shouldBeRemoved(element) { kept.append(element) }
        }
        guard kept.count < count else { return }
        elements = kept
        sources = (0..<Int32(truncatingIfNeeded: kept.count)).map { $0 }
        rebuild(for: elements, by: keyOf)
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
        let newHash: Int = newKey.hashValue
        guard case .empty = probe(for: newKey, hash: newHash, in: elements, by: keyOf) else {
            preconditionFailure("Another element already has this key.")
        }
        empty(bucket(holding: offset, hash: oldKey.hashValue), in: elements, by: keyOf)
        elements[offset] = element
        place(offset, hash: newHash)
        return old
    }

    /// Sizes the table to hold the count without growing.
    @inlinable mutating func reserveCapacity<Element, Key: Hashable>(_ minimumCount: Int, for elements: [Element], by keyOf: (Element) -> Key) {
        guard minimumCount * 4 > table.count * 3 else { return }
        rebuild(for: elements, by: keyOf, capacity: minimumCount)
    }

    /// Removes every offset and releases the table.
    @inlinable mutating func removeAll() {
        table = []
        sources = []
    }
}

// MARK: - Hash table

extension Offsets {

    /// Where a probe for a key ended: the bucket holding it, or the empty bucket where it belongs.
    @usableFromInline enum Probe {
        case found(Int)
        case empty(Int)
    }

    /// The bitmask that wraps a hash or bucket into the table.
    @inlinable var mask: Int { table.count - 1 }

    /// The bucket entry for a storage offset: the offset in the low bits that the mask keeps, under as many of the hash's top bits as fit below the sign bit, so a probe can skip most other keys without reading their elements.
    @inlinable func entry(_ offset: Int, hash: Int) -> Int32 {
        let shift: Int = table.count.trailingZeroBitCount
        let tag: Int = Int(bitPattern: UInt(bitPattern: hash) >> (33 + shift))
        return Int32(truncatingIfNeeded: (tag << shift) | offset)
    }

    /// Probes from the key's hash until it finds the key or an empty bucket. An empty table reports an empty bucket at 0.
    @inlinable func probe<Element, Key: Hashable>(for key: Key, hash: Int, in elements: [Element], by keyOf: (Element) -> Key) -> Probe {
        guard !table.isEmpty else { return .empty(0) }
        let tag: Int = Int(entry(0, hash: hash))
        var bucket: Int = hash & mask
        while true {
            let stored: Int = Int(table[bucket])
            if stored < 0 { return .empty(bucket) }
            if stored & ~mask == tag && keyOf(elements[stored & mask]) == key { return .found(bucket) }
            bucket = (bucket + 1) & mask
        }
    }

    /// The bucket holding the storage offset, found by probing from its element's hash.
    @inlinable func bucket(holding offset: Int, hash: Int) -> Int {
        let target: Int32 = entry(offset, hash: hash)
        var bucket: Int = hash & mask
        while table[bucket] != target { bucket = (bucket + 1) & mask }
        return bucket
    }

    /// Puts the storage offset in the first empty bucket probing from the hash.
    @inlinable mutating func place(_ offset: Int, hash: Int) {
        var bucket: Int = hash & mask
        while table[bucket] >= 0 { bucket = (bucket + 1) & mask }
        table[bucket] = entry(offset, hash: hash)
    }

    /// Empties the bucket and shifts later entries of the same probe run back, so no lookup stops early at the gap.
    @inlinable mutating func empty<Element, Key: Hashable>(_ bucket: Int, in elements: [Element], by keyOf: (Element) -> Key) {
        var hole: Int = bucket
        var next: Int = (hole + 1) & mask
        while table[next] >= 0 {
            let ideal: Int = keyOf(elements[Int(table[next]) & mask]).hashValue & mask
            if (next - ideal) & mask >= (next - hole) & mask {
                table[hole] = table[next]
                hole = next
            }
            next = (next + 1) & mask
        }
        table[hole] = -1
    }

    /// Rebuilds the table at the smallest power of two that keeps the larger of the capacity and the element count at most three-quarters full.
    @inlinable mutating func rebuild<Element, Key: Hashable>(for elements: [Element], by keyOf: (Element) -> Key, capacity minimumCount: Int = 0) {
        let count: Int = Swift.max(elements.count, minimumCount)
        var capacity: Int = 8
        while count * 4 > capacity * 3 { capacity *= 2 }
        table = Array(repeating: -1, count: capacity)
        for offset in elements.indices { place(offset, hash: keyOf(elements[offset]).hashValue) }
    }
}
