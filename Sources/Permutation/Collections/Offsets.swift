// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Offsets.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation.swift]

/// The order and hash index of a keyed collection whose elements stay where they were stored.
///
/// As a collection, `Offsets` is the storage offset of the element at each position, so reordering it reorders its owner without moving an element. Behind it sits an open-addressing hash table of storage offsets, which a reorder never touches. Each bucket also keeps 32 bits of its key's hash, so a probe loads an element only when those bits match, and deletion and growth never rehash.
///
/// `Offsets` never stores an element or a key. Every call that reads or changes membership takes the owner's elements and a key function, which must be the same on every call.
@usableFromInline struct Offsets {

    /// Buckets placed by the hash of their element's key with linear probing. Each packs the low 32 bits of the hash above the storage offset, and `Offsets.vacant` marks an empty bucket. Its count is zero or a power of two.
    @usableFromInline var table: [UInt64]

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
        return Offsets.offset(in: table[bucket])
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
        guard case .empty(let bucket) = probe(for: key, hash: hash, in: elements, by: keyOf) else { return false }
        precondition(elements.count < Int(Int32.max), "Offsets holds at most Int32.max elements.")
        let offset: Int = elements.count
        elements.append(element)
        if elements.count * 4 > table.count * 3 {
            grow(toHold: elements.count)
            place(Offsets.bucket(hash: hash, offset: offset))
        } else {
            table[bucket] = Offsets.bucket(hash: hash, offset: offset)
        }
        sources.insert(Int32(truncatingIfNeeded: offset), at: position)
        return true
    }

    /// Appends each element whose key is not already present, sizing the table once for the whole sequence.
    @inlinable mutating func append<Element, Key: Hashable>(contentsOf newElements: some Sequence<Element>, into elements: inout [Element], by keyOf: (Element) -> Key) {
        reserveCapacity(count + newElements.underestimatedCount)
        for element in newElements {
            _ = insert(element, at: endIndex, into: &elements, by: keyOf)
        }
    }

    /// Removes and returns the element at the position, moving the last stored element into its storage offset.
    @inlinable mutating func remove<Element, Key: Hashable>(at position: Int, from elements: inout [Element], by keyOf: (Element) -> Key) -> Element {
        let offset: Int32 = sources[position]
        let removed: Element = elements[Int(offset)]
        empty(bucket(holding: Int(offset), hash: keyOf(removed).hashValue))
        let last: Int32 = Int32(truncatingIfNeeded: elements.count - 1)
        if offset != last {
            let lastHash: Int = keyOf(elements[Int(last)]).hashValue
            table[bucket(holding: Int(last), hash: lastHash)] = Offsets.bucket(hash: lastHash, offset: Int(offset))
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
        sources = Array(0..<Int32(truncatingIfNeeded: kept.count))
        table = []
        grow(toHold: elements.count)
        for offset in elements.indices { place(Offsets.bucket(hash: keyOf(elements[offset]).hashValue, offset: offset)) }
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
        empty(bucket(holding: offset, hash: oldKey.hashValue))
        elements[offset] = element
        place(Offsets.bucket(hash: newHash, offset: offset))
        return old
    }

    /// Sizes the table to hold the count without growing.
    @inlinable mutating func reserveCapacity(_ minimumCount: Int) {
        grow(toHold: minimumCount)
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

    /// The value of an empty bucket, which no real bucket can equal because offsets stay below `Int32.max`.
    @inlinable static var vacant: UInt64 { .max }

    /// A bucket packing the low 32 bits of the hash above the storage offset.
    @inlinable static func bucket(hash: Int, offset: Int) -> UInt64 {
        UInt64(UInt32(truncatingIfNeeded: hash)) << 32 | UInt64(UInt32(truncatingIfNeeded: offset))
    }

    /// The storage offset kept in a bucket.
    @inlinable static func offset(in bucket: UInt64) -> Int {
        Int(UInt32(truncatingIfNeeded: bucket))
    }

    /// The hash bits kept in a bucket, which also decide its home.
    @inlinable static func fragment(in bucket: UInt64) -> Int {
        Int(bucket >> 32)
    }

    /// The bitmask that wraps a hash or bucket into the table.
    @inlinable var mask: Int { table.count - 1 }

    /// Probes from the key's home until it finds the key or an empty bucket, loading an element only when the stored hash bits match. An empty table reports an empty bucket at 0.
    @inlinable func probe<Element, Key: Hashable>(for key: Key, hash: Int, in elements: [Element], by keyOf: (Element) -> Key) -> Probe {
        guard !table.isEmpty else { return .empty(0) }
        let fragment: Int = Int(UInt32(truncatingIfNeeded: hash))
        var index: Int = fragment & mask
        while true {
            let bucket: UInt64 = table[index]
            if bucket == Offsets.vacant { return .empty(index) }
            if Offsets.fragment(in: bucket) == fragment, keyOf(elements[Offsets.offset(in: bucket)]) == key { return .found(index) }
            index = (index + 1) & mask
        }
    }

    /// The index of the bucket holding the storage offset, found by probing from its element's hash.
    @inlinable func bucket(holding offset: Int, hash: Int) -> Int {
        let target: UInt64 = Offsets.bucket(hash: hash, offset: offset)
        var index: Int = Offsets.fragment(in: target) & mask
        while table[index] != target { index = (index + 1) & mask }
        return index
    }

    /// Puts the bucket in the first empty slot probing from its home.
    @inlinable mutating func place(_ bucket: UInt64) {
        var index: Int = Offsets.fragment(in: bucket) & mask
        while table[index] != Offsets.vacant { index = (index + 1) & mask }
        table[index] = bucket
    }

    /// Empties the slot and shifts later buckets of the same probe run back, so no lookup stops early at the gap. Each bucket's home comes from its stored hash bits, so nothing is rehashed.
    @inlinable mutating func empty(_ index: Int) {
        var hole: Int = index
        var next: Int = (hole + 1) & mask
        while table[next] != Offsets.vacant {
            let home: Int = Offsets.fragment(in: table[next]) & mask
            if (next - home) & mask >= (next - hole) & mask {
                table[hole] = table[next]
                hole = next
            }
            next = (next + 1) & mask
        }
        table[hole] = Offsets.vacant
    }

    /// Grows the table to the smallest power of two that keeps the count at most three-quarters full, re-placing buckets from their stored hash bits.
    @inlinable mutating func grow(toHold count: Int) {
        var capacity: Int = 8
        while count * 4 > capacity * 3 { capacity *= 2 }
        guard capacity > table.count else { return }
        let old: [UInt64] = table
        table = Array(repeating: Offsets.vacant, count: capacity)
        for bucket in old where bucket != Offsets.vacant { place(bucket) }
    }
}
