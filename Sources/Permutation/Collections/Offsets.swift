// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Offsets.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation.swift]

/// The order and hash index of a keyed collection whose elements stay where they were stored.
///
/// As a collection, `Offsets` is the storage offset of the element at each position, so reordering it reorders its owner without moving an element. Behind it sits an open-addressing hash table of storage offsets, which a reorder never touches.
///
/// `Offsets` never stores an element or a key. Every call that reads or changes membership takes the owner's elements and a key function, which must be the same on every call.
///
/// Up to `linearLimit` elements, the table stays empty and lookups scan the elements, which beats hashing at that size. Past it the table always exists.
@usableFromInline struct Offsets {

    /// Storage offsets placed by the hash of their element's key with linear probing, where -1 marks an empty bucket. Its count is zero or a power of two, and it is zero only while there are at most `linearLimit` elements.
    @usableFromInline var table: [Int32]

    /// The storage offset at each position.
    @usableFromInline var sources: [Int32]

    /// Whether every position shows its own storage offset, so the owner can read its elements straight through. Anything that might break that clears it, and only rebuilding the order in storage order sets it again.
    @usableFromInline var isInStorageOrder: Bool

    /// The most elements kept without a hash table.
    @inlinable static var linearLimit: Int { 16 }

    /// Creates empty offsets.
    @inlinable init() {
        table = []
        sources = []
        isInStorageOrder = true
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

    /// Applies the permutation by rotating each cycle of `sources` through one carried offset, leaving the table untouched. The bounds check runs only at each cycle's largest offset, since in Foata form no other offset can be out of range when those are in range.
    @inlinable mutating func apply(_ permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        isInStorageOrder = false
        let count: Int = sources.count
        var start: Int = -1
        var carried: Int32 = 0
        for offset in permutation.cycle {
            if offset > start {
                precondition(offset < count, "Every offset in the cycle must be within the collection.")
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
        guard i != j else { return }
        isInStorageOrder = false
        sources.swapAt(i, j)
    }

    /// Moves the block of positions from `start` to the end so it begins at `index`, as a batch insert does after appending.
    @inlinable mutating func moveTail(from start: Int, to index: Int) {
        guard index < start else { return }
        isInStorageOrder = false
        let block: ArraySlice<Int32> = sources[start...]
        sources.removeSubrange(start...)
        sources.insert(contentsOf: block, at: index)
    }
}

// MARK: - Lookup

extension Offsets {

    /// The storage offset of the element with the key, or nil when there is none.
    @inlinable func offset<Element, Key: Hashable>(of key: Key, in elements: [Element], by keyOf: (Element) -> Key) -> Int? {
        guard !table.isEmpty else { return elements.firstIndex { keyOf($0) == key } }
        guard case .found(let bucket) = probe(for: key, hash: key.hashValue, in: elements, by: keyOf) else { return nil }
        return Int(table[bucket])
    }

    /// The position showing the storage offset, in O(n).
    @inlinable func position(ofOffset offset: Int) -> Int? {
        let target: Int32 = Int32(truncatingIfNeeded: offset)
        let found: Int = positions(of: target, and: target).first
        return found < 0 ? nil : found
    }

    /// The positions showing two storage offsets, or -1 for one that is not shown, found in one pass that compares sixteen offsets at a time.
    @inlinable func positions(of first: Int32, and second: Int32) -> Positions {
        var found: Positions = Positions(first: -1, second: -1)
        sources.withUnsafeBufferPointer { buffer in
            guard let base: UnsafePointer<Int32> = buffer.baseAddress else { return }
            let count: Int = buffer.count
            let firsts: SIMD16<Int32> = SIMD16(repeating: first)
            let seconds: SIMD16<Int32> = SIMD16(repeating: second)
            var start: Int = 0
            while start + 16 <= count {
                let lanes: SIMD16<Int32> = UnsafeRawPointer(base + start).loadUnaligned(as: SIMD16<Int32>.self)
                if any((lanes .== firsts) .| (lanes .== seconds)) {
                    for lane in 0..<16 {
                        if lanes[lane] == first && found.first < 0 { found.first = start + lane }
                        if lanes[lane] == second && found.second < 0 { found.second = start + lane }
                    }
                    if found.first >= 0 && found.second >= 0 { return }
                }
                start += 16
            }
            for position in start..<count {
                if buffer[position] == first && found.first < 0 { found.first = position }
                if buffer[position] == second && found.second < 0 { found.second = position }
            }
        }
        return found
    }

    /// Two positions found together by one search.
    @usableFromInline struct Positions {
        @usableFromInline var first: Int
        @usableFromInline var second: Int
        @inlinable init(first: Int, second: Int) {
            self.first = first
            self.second = second
        }
    }
}

// MARK: - Changing membership

extension Offsets {

    /// Stores the element and shows it at the position unless its key is already present, returning whether it was added.
    @inlinable mutating func insert<Element, Key: Hashable>(_ element: Element, at position: Int, into elements: inout [Element], by keyOf: (Element) -> Key) -> Bool {
        precondition(position >= startIndex && position <= endIndex, "Index out of range.")
        let key: Key = keyOf(element)
        if table.isEmpty && elements.count < Self.linearLimit {
            guard !elements.contains(where: { keyOf($0) == key }) else { return false }
            elements.append(element)
            if position < sources.count { isInStorageOrder = false }
            sources.insert(Int32(truncatingIfNeeded: elements.count - 1), at: position)
            return true
        }
        if table.isEmpty { rebuild(for: elements, by: keyOf) }
        let probed: Probe = probe(for: key, hash: key.hashValue, in: elements, by: keyOf)
        guard case .empty(let bucket) = probed else { return false }
        precondition(elements.count < Int(Int32.max), "Offsets holds at most Int32.max elements.")
        elements.append(element)
        let offset: Int = elements.count - 1
        if elements.count * 4 > table.count * 3 {
            rebuild(for: elements, by: keyOf)
        } else {
            table[bucket] = Int32(truncatingIfNeeded: offset)
        }
        if position < sources.count { isInStorageOrder = false }
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
        isInStorageOrder = true
        if elements.count <= Self.linearLimit {
            table = []
            var end: Int = 0
            for offset in elements.indices {
                let key: Key = keyOf(elements[offset])
                guard !elements[..<end].contains(where: { keyOf($0) == key }) else { continue }
                if end != offset { elements[end] = elements[offset] }
                end += 1
            }
            if end < elements.count { elements.removeSubrange(end...) }
            sources = (0..<Int32(truncatingIfNeeded: elements.count)).map { $0 }
            return
        }
        var capacity: Int = 8
        while elements.count * 4 > capacity * 3 { capacity *= 2 }
        table = Array(repeating: -1, count: capacity)
        var duplicates: [Int] = []
        for offset in elements.indices {
            let key: Key = keyOf(elements[offset])
            switch probe(for: key, hash: key.hashValue, in: elements, by: keyOf) {
            case .found:
                duplicates.append(offset)
            case .empty(let bucket):
                table[bucket] = Int32(truncatingIfNeeded: offset)
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
        let last: Int32 = Int32(truncatingIfNeeded: elements.count - 1)
        let lastPosition: Int = sources[position] == last ? position : positions(of: last, and: last).first
        return remove(at: position, lastAt: lastPosition, from: &elements, by: keyOf)
    }

    /// Removes and returns the element at the storage offset, finding its position and the position of the last storage offset in one vectorized search.
    @inlinable mutating func remove<Element, Key: Hashable>(offset: Int, from elements: inout [Element], by keyOf: (Element) -> Key) -> Element {
        let target: Int32 = Int32(truncatingIfNeeded: offset)
        let last: Int32 = Int32(truncatingIfNeeded: elements.count - 1)
        let found: Positions = positions(of: target, and: last)
        precondition(found.first >= 0 && found.second >= 0, "The storage offset must be shown.")
        return remove(at: found.first, lastAt: found.second, from: &elements, by: keyOf)
    }

    /// Removes the element at the position, given the position showing the last storage offset, by moving the last stored element into the freed offset and closing the gap in the order with one block move.
    @inlinable mutating func remove<Element, Key: Hashable>(at position: Int, lastAt lastPosition: Int, from elements: inout [Element], by keyOf: (Element) -> Key) -> Element {
        let offset: Int32 = sources[position]
        let removed: Element = elements[Int(offset)]
        let hashed: Bool = !table.isEmpty
        if hashed { empty(bucket(holding: Int(offset), hash: keyOf(removed).hashValue), in: elements, by: keyOf) }
        let last: Int32 = Int32(truncatingIfNeeded: elements.count - 1)
        if offset != last {
            isInStorageOrder = false
            if hashed { table[bucket(holding: Int(last), hash: keyOf(elements[Int(last)]).hashValue)] = offset }
            sources[lastPosition] = offset
            elements.swapAt(Int(offset), Int(last))
        }
        sources.remove(at: position)
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
        keep(kept, in: &elements, by: keyOf)
    }

    /// Removes the elements whose storage offsets are marked, then stores the rest in their shown order and rebuilds the table once. The marks hold one flag per stored element.
    @inlinable mutating func removeAll<Element, Key: Hashable>(marked doomed: [Bool], from elements: inout [Element], by keyOf: (Element) -> Key) {
        var kept: [Element] = []
        kept.reserveCapacity(count)
        for offset in sources where !doomed[Int(offset)] {
            kept.append(elements[Int(offset)])
        }
        keep(kept, in: &elements, by: keyOf)
    }

    /// Stores the kept elements in shown order and rebuilds the table, unless nothing was removed.
    @inlinable mutating func keep<Element, Key: Hashable>(_ kept: [Element], in elements: inout [Element], by keyOf: (Element) -> Key) {
        guard kept.count < count else { return }
        elements = kept
        sources = (0..<Int32(truncatingIfNeeded: kept.count)).map { $0 }
        isInStorageOrder = true
        if kept.count <= Self.linearLimit {
            table = []
        } else {
            rebuild(for: elements, by: keyOf)
        }
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
        guard !table.isEmpty else {
            precondition(!elements.contains(where: { keyOf($0) == newKey }), "Another element already has this key.")
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
        guard minimumCount > Self.linearLimit || !table.isEmpty else { return }
        guard minimumCount * 4 > table.count * 3 else { return }
        rebuild(for: elements, by: keyOf, capacity: minimumCount)
    }

    /// Removes every offset and releases the table.
    @inlinable mutating func removeAll() {
        table = []
        sources = []
        isInStorageOrder = true
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

    /// Probes from the key's hash until it finds the key or an empty bucket. An empty table reports an empty bucket at 0, so callers that may run without a table scan the elements instead.
    @inlinable func probe<Element, Key: Hashable>(for key: Key, hash: Int, in elements: [Element], by keyOf: (Element) -> Key) -> Probe {
        guard !table.isEmpty else { return .empty(0) }
        var bucket: Int = hash & mask
        while true {
            let offset: Int32 = table[bucket]
            if offset < 0 { return .empty(bucket) }
            if keyOf(elements[Int(offset)]) == key { return .found(bucket) }
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

    /// Rebuilds the table at the smallest power of two that keeps the larger of the capacity and the element count at most three-quarters full.
    @inlinable mutating func rebuild<Element, Key: Hashable>(for elements: [Element], by keyOf: (Element) -> Key, capacity minimumCount: Int = 0) {
        let count: Int = Swift.max(elements.count, minimumCount)
        var capacity: Int = 8
        while count * 4 > capacity * 3 { capacity *= 2 }
        table = Array(repeating: -1, count: capacity)
        for offset in elements.indices { place(offset, hash: keyOf(elements[offset]).hashValue) }
    }
}
