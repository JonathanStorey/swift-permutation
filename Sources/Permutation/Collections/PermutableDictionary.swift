// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableDictionary.swift
// dependencies: [Collections/Arrangement.swift, Collections/Offsets.swift, Collections/PermutableCollection.swift, Permutation/Permutation.swift]

/// An ordered dictionary whose entries, and whose values alone, can be reordered without moving a key or a value in memory.
///
/// Keys and values each sit in an array that reordering never touches. `Offsets` keeps the order of the entries and a hash index from each key to where it is stored, and a second table records which stored value each key owns. That gives three ways to change the dictionary, each through its own door:
///
/// - Reordering the dictionary, or its `keys`, moves whole entries. `dictionary.sort { $0.value < $1.value }`, `dictionary.keys.sort()` and `dictionary.keys.shuffle()` all keep every key with its value.
/// - Reordering `values` hands the values around while every key stays put. `dictionary.values.shuffle(.derangement)` gives every key a value that belonged to another key, and `dictionary.values.sort()` gives the first key the smallest value.
/// - Writing through a key or through `values[position]` edits a value in place.
///
/// Lookups, insertions and removals by key are O(1). Finding the position of a key is O(n).
public struct PermutableDictionary<Key: Hashable, Value> {

    /// The keys in storage order, which reordering never changes.
    @usableFromInline var keyStorage: [Key]

    /// The values in storage order, which reordering never changes.
    @usableFromInline var valueStorage: [Value]

    /// The storage offset of the key shown at each position, with a hash index from each key to its storage offset.
    @usableFromInline var offsets: Offsets

    /// The storage offset of the value each stored key owns, indexed by the key's storage offset. Empty means every key owns the value at its own offset, which holds until the values are first reordered.
    @usableFromInline var valueSlots: [Int32]

    /// The keys, in order, as an arrangement whose reorders move whole entries.
    public typealias Keys = Arrangement<Key>

    /// An entry, used only to iterate the dictionary.
    public typealias Element = (key: Key, value: Value)

    /// Creates an empty dictionary.
    @inlinable public init() {
        keyStorage = []
        valueStorage = []
        offsets = Offsets()
        valueSlots = []
    }

    /// Creates a dictionary from pairs in order, which must not repeat a key.
    @inlinable public init(uniqueKeysWithValues keysAndValues: some Sequence<(Key, Value)>) {
        var keys: [Key] = []
        var values: [Value] = []
        keys.reserveCapacity(keysAndValues.underestimatedCount)
        values.reserveCapacity(keysAndValues.underestimatedCount)
        for (key, value) in keysAndValues {
            keys.append(key)
            values.append(value)
        }
        self.init(checkedKeys: keys, values: values)
    }

    /// Creates a dictionary pairing each key with the value at the same offset. The keys must not repeat, and there must be as many values as keys.
    @inlinable public init(uniqueKeys keys: some Sequence<Key>, values: some Sequence<Value>) {
        self.init(checkedKeys: Array(keys), values: Array(values))
    }

    /// Adopts the arrays as storage, trapping on a repeated key or a count mismatch.
    @inlinable init(checkedKeys keys: [Key], values: [Value]) {
        precondition(keys.count == values.count, "There must be exactly one value for each key.")
        keyStorage = keys
        valueStorage = values
        offsets = Offsets()
        valueSlots = []
        offsets.index(&keyStorage, by: Self.key)
        precondition(keyStorage.count == valueStorage.count, "The keys must be unique.")
    }

    /// Wraps storage that already agrees, as `mapValues` does.
    @inlinable init(keyStorage: [Key], valueStorage: [Value], offsets: Offsets, valueSlots: [Int32]) {
        self.keyStorage = keyStorage
        self.valueStorage = valueStorage
        self.offsets = offsets
        self.valueSlots = valueSlots
    }

    /// Each key is its own lookup key, written as a plain function so every lookup calls it directly.
    @inlinable static func key(_ key: Key) -> Key {
        key
    }

    /// The storage offset of the value the key at this storage offset owns.
    @inlinable func valueSlot(ofKeySlot keySlot: Int) -> Int {
        valueSlots.isEmpty ? keySlot : Int(valueSlots[keySlot])
    }

    /// Whether two arrays share one buffer, which for arrays alive at once means they hold the same elements.
    @inlinable static func sharesStorage<Item>(_ first: [Item], _ second: [Item]) -> Bool {
        first.withUnsafeBufferPointer { a in second.withUnsafeBufferPointer { b in a.baseAddress == b.baseAddress } }
    }
}

// MARK: - Collection

extension PermutableDictionary: RandomAccessCollection {

    @inlinable public var startIndex: Int { 0 }

    @inlinable public var endIndex: Int { offsets.count }

    /// The entry at the position.
    @inlinable public subscript(position: Int) -> Element {
        let keySlot: Int = offsets[position]
        return (key: keyStorage[keySlot], value: valueStorage[valueSlot(ofKeySlot: keySlot)])
    }

    /// Iterates the entries in order, reading storage straight through while nothing has reordered it.
    @inlinable public func makeIterator() -> Iterator {
        Iterator(keys: keyStorage, values: valueStorage, valueSlots: valueSlots, sources: offsets.sources, isInStorageOrder: offsets.isInStorageOrder)
    }

    /// An iterator over the entries in order.
    public struct Iterator: IteratorProtocol {

        @usableFromInline let keys: [Key]

        @usableFromInline let values: [Value]

        @usableFromInline let valueSlots: [Int32]

        @usableFromInline let sources: [Int32]

        @usableFromInline let isInStorageOrder: Bool

        @usableFromInline var position: Int

        @inlinable init(keys: [Key], values: [Value], valueSlots: [Int32], sources: [Int32], isInStorageOrder: Bool) {
            self.keys = keys
            self.values = values
            self.valueSlots = valueSlots
            self.sources = sources
            self.isInStorageOrder = isInStorageOrder
            position = 0
        }

        @inlinable public mutating func next() -> Element? {
            let current: Int = position
            guard current < sources.count else { return nil }
            position = current + 1
            let keySlot: Int = isInStorageOrder ? current : Int(sources[current])
            let valueSlot: Int = valueSlots.isEmpty ? keySlot : Int(valueSlots[keySlot])
            return (key: keys[keySlot], value: values[valueSlot])
        }
    }
}

// MARK: - PermutableCollection

extension PermutableDictionary: PermutableCollection {

    /// Reorders the entries by applying the permutation to the order alone, leaving keys, values and the hash index untouched.
    @inlinable public mutating func apply(_ permutation: Permutation) {
        offsets.apply(permutation)
    }

    /// Exchanges the entries at the two positions by swapping their storage offsets.
    @inlinable public mutating func swapAt(_ i: Int, _ j: Int) {
        offsets.swapAt(i, j)
    }
}

// MARK: - Keys

public extension PermutableDictionary {

    /// The keys in order. Reordering them reorders the entries, so every key keeps its value.
    ///
    /// Assigning a whole new arrangement must rearrange exactly the keys already present, which is checked.
    @inlinable var keys: Keys {
        get {
            Arrangement(elements: keyStorage, offsets: offsets)
        }
        _modify {
            let storage: [Key] = keyStorage
            let table: [Int32] = offsets.table
            var view: Keys = Arrangement(elements: keyStorage, offsets: offsets)
            keyStorage = []
            offsets = Offsets()
            defer { adoptKeys(view, storage: storage, table: table) }
            yield &view
        }
    }

    /// Takes the keys back after a mutation. An arrangement that still holds the same storage only changed its order. Anything else must show the same keys, and is mapped back onto the stored keys through the hash index.
    @inlinable internal mutating func adoptKeys(_ view: Keys, storage: [Key], table: [Int32]) {
        if view.offsets.count == storage.count && Self.sharesStorage(view.elements, storage) {
            keyStorage = view.elements
            offsets = view.offsets
            offsets.table = table
            return
        }
        precondition(view.count == storage.count, "New keys must rearrange the keys already present.")
        var lookup: Offsets = Offsets()
        lookup.table = table
        var isSeen: [Bool] = [Bool](repeating: false, count: storage.count)
        var sources: [Int32] = []
        sources.reserveCapacity(storage.count)
        for key in view {
            guard let keySlot: Int = lookup.offset(of: key, in: storage, by: Self.key), !isSeen[keySlot] else {
                preconditionFailure("New keys must rearrange the keys already present.")
            }
            isSeen[keySlot] = true
            sources.append(Int32(truncatingIfNeeded: keySlot))
        }
        lookup.isInStorageOrder = sources.indices.allSatisfy { sources[$0] == Int32(truncatingIfNeeded: $0) }
        lookup.sources = sources
        keyStorage = storage
        offsets = lookup
    }
}

// MARK: - Values

public extension PermutableDictionary {

    /// The values in order. Writing through a position edits that value, and reordering them hands the values around while every key stays where it is.
    ///
    /// Assigning a whole new collection of values must give exactly one value per key, which is checked.
    @inlinable var values: Values {
        get {
            Values(storage: valueStorage, slots: valueSlots, sources: offsets.sources, isInStorageOrder: offsets.isInStorageOrder)
        }
        _modify {
            var view: Values = Values(storage: valueStorage, slots: valueSlots, sources: offsets.sources, isInStorageOrder: offsets.isInStorageOrder)
            valueStorage = []
            valueSlots = []
            defer { adoptValues(view) }
            yield &view
        }
    }

    /// Takes the values back after a mutation. A view still built on this dictionary's order kept its layout. Anything else is stored afresh in its own order, one value per position.
    @inlinable internal mutating func adoptValues(_ view: Values) {
        if view.storage.count == keyStorage.count && Self.sharesStorage(view.sources, offsets.sources) {
            valueStorage = view.storage
            valueSlots = view.slots
            return
        }
        precondition(view.count == count, "New values must hold exactly one value per key.")
        valueStorage = Array(view)
        guard !offsets.isInStorageOrder else {
            valueSlots = []
            return
        }
        var slots: [Int32] = [Int32](repeating: 0, count: count)
        for (position, keySlot) in offsets.sources.enumerated() { slots[Int(keySlot)] = Int32(truncatingIfNeeded: position) }
        valueSlots = slots
    }

    /// The values of a dictionary in order, which reorder among the keys rather than with them.
    struct Values {

        /// The values in storage order, which reordering never changes.
        @usableFromInline var storage: [Value]

        /// The value storage offset each key storage offset owns, or empty while each key owns the value at its own offset.
        @usableFromInline var slots: [Int32]

        /// The dictionary's order, the key storage offset at each position, which the view never changes.
        @usableFromInline let sources: [Int32]

        /// Whether the dictionary's order is its storage order.
        @usableFromInline let isInStorageOrder: Bool

        @inlinable init(storage: [Value], slots: [Int32], sources: [Int32], isInStorageOrder: Bool) {
            self.storage = storage
            self.slots = slots
            self.sources = sources
            self.isInStorageOrder = isInStorageOrder
        }

        /// The value storage offset shown at the position.
        @inlinable func slot(at position: Int) -> Int {
            let keySlot: Int = Int(sources[position])
            return slots.isEmpty ? keySlot : Int(slots[keySlot])
        }

        /// Writes out the identity table before the first reorder, so each key can be handed another value.
        @inlinable mutating func materializeSlots() {
            guard slots.isEmpty else { return }
            slots = (0..<Int32(truncatingIfNeeded: storage.count)).map { $0 }
        }
    }
}

extension PermutableDictionary.Values: RandomAccessCollection {

    @inlinable public var startIndex: Int { 0 }

    @inlinable public var endIndex: Int { sources.count }

    /// The value at the position, which can be edited in place.
    @inlinable public subscript(position: Int) -> Value {
        get { storage[slot(at: position)] }
        set { storage[slot(at: position)] = newValue }
    }

    /// Hands over the storage itself while the values are shown in storage order.
    @inlinable public func withContiguousStorageIfAvailable<Result>(_ body: (UnsafeBufferPointer<Value>) throws -> Result) rethrows -> Result? {
        guard isInStorageOrder && slots.isEmpty else { return nil }
        return try storage.withUnsafeBufferPointer(body)
    }
}

extension PermutableDictionary.Values: PermutableCollection {

    /// Hands the values around the cycles of the permutation by rotating which value each key owns, so no key and no value moves in memory. Only each cycle's largest offset needs a bounds check in Foata form.
    @inlinable public mutating func apply(_ permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        materializeSlots()
        let count: Int = sources.count
        var start: Int = -1
        var carried: Int32 = 0
        for offset in permutation.cycle {
            if offset > start {
                precondition(offset < count, "Every offset in the cycle must be within the collection.")
                if start >= 0 { slots[Int(sources[start])] = carried }
                start = offset
                carried = slots[Int(sources[offset])]
            } else {
                let keySlot: Int = Int(sources[offset])
                let next: Int32 = slots[keySlot]
                slots[keySlot] = carried
                carried = next
            }
        }
        slots[Int(sources[start])] = carried
    }

    /// Exchanges the values of the keys at the two positions.
    @inlinable public mutating func swapAt(_ i: Int, _ j: Int) {
        guard i != j else { return }
        materializeSlots()
        slots.swapAt(Int(sources[i]), Int(sources[j]))
    }
}

extension PermutableDictionary.Values: CustomStringConvertible {

    public var description: String {
        Array(self).description
    }
}

extension PermutableDictionary.Values: Sendable where Value: Sendable {}

// MARK: - Lookup and update

public extension PermutableDictionary {

    /// The value for the key, or nil when it is absent. Assigning a value updates it in place or appends a new entry, and assigning nil removes the entry.
    @inlinable subscript(key: Key) -> Value? {
        get {
            offsets.offset(of: key, in: keyStorage, by: Self.key).map { valueStorage[valueSlot(ofKeySlot: $0)] }
        }
        set {
            if let newValue {
                updateValue(newValue, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }

    /// The value for the key, or the default when it is absent. Mutating through it edits the value in place, appending an entry with the default first when the key is absent.
    @inlinable subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            self[key] ?? defaultValue()
        }
        _modify {
            let keySlot: Int
            if let found: Int = offsets.offset(of: key, in: keyStorage, by: Self.key) {
                keySlot = found
            } else {
                keySlot = insertNew(key, defaultValue(), at: endIndex)
            }
            yield &valueStorage[valueSlot(ofKeySlot: keySlot)]
        }
    }

    /// Returns whether the dictionary holds the key, in O(1). Prefer this to `keys.contains(_:)`, which scans.
    @inlinable func contains(key: Key) -> Bool {
        offsets.offset(of: key, in: keyStorage, by: Self.key) != nil
    }

    /// The position of the key, or nil when it is absent, in O(n).
    @inlinable func index(forKey key: Key) -> Int? {
        offsets.offset(of: key, in: keyStorage, by: Self.key).flatMap { offsets.position(ofOffset: $0) }
    }

    /// Replaces the value for the key and returns the old one, or appends a new entry and returns nil.
    @inlinable @discardableResult mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        updateValue(value, forKey: key, insertingAt: endIndex)
    }

    /// Replaces the value for the key in place and returns the old one, or inserts a new entry at the position and returns nil.
    @inlinable @discardableResult mutating func updateValue(_ value: Value, forKey key: Key, insertingAt index: Int) -> Value? {
        if let keySlot: Int = offsets.offset(of: key, in: keyStorage, by: Self.key) {
            var old: Value = value
            Swift.swap(&old, &valueStorage[valueSlot(ofKeySlot: keySlot)])
            return old
        }
        insertNew(key, value, at: index)
        return nil
    }

    /// Inserts an entry whose key is known to be absent and returns the key's storage offset. The new key and value are both stored last, so the key owns the value at its own offset.
    @inlinable @discardableResult internal mutating func insertNew(_ key: Key, _ value: Value, at index: Int) -> Int {
        precondition(index >= startIndex && index <= endIndex, "Index out of range.")
        _ = offsets.insert(key, at: index, into: &keyStorage, by: Self.key)
        let keySlot: Int = valueStorage.count
        valueStorage.append(value)
        if !valueSlots.isEmpty { valueSlots.append(Int32(truncatingIfNeeded: keySlot)) }
        return keySlot
    }

    /// Reserves room for the count of entries, so adding up to it neither copies storage nor rebuilds the hash index.
    @inlinable mutating func reserveCapacity(_ minimumCapacity: Int) {
        keyStorage.reserveCapacity(minimumCapacity)
        valueStorage.reserveCapacity(minimumCapacity)
        offsets.sources.reserveCapacity(minimumCapacity)
        offsets.reserveCapacity(minimumCapacity, for: keyStorage, by: Self.key)
    }
}

// MARK: - Removing

public extension PermutableDictionary {

    /// Removes the entry for the key and returns its value, or returns nil when the key is absent.
    @inlinable @discardableResult mutating func removeValue(forKey key: Key) -> Value? {
        guard let keySlot: Int = offsets.offset(of: key, in: keyStorage, by: Self.key) else { return nil }
        let value: Value = removeValue(atKeySlot: keySlot)
        _ = offsets.remove(offset: keySlot, from: &keyStorage, by: Self.key)
        return value
    }

    /// Removes and returns the value the key at this storage offset owns, matching how `Offsets` frees a key: the last stored key moves into the freed key offset, so its claim on a value moves with it. The last stored value moves into the freed value offset, and the key that owned it is found with a vectorized search.
    @inlinable internal mutating func removeValue(atKeySlot keySlot: Int) -> Value {
        let last: Int = valueStorage.count - 1
        guard !valueSlots.isEmpty else {
            if keySlot != last { valueStorage.swapAt(keySlot, last) }
            return valueStorage.removeLast()
        }
        let valueSlot: Int = Int(valueSlots[keySlot])
        if valueSlot != last {
            let owner: Int = Offsets.firstIndex(of: Int32(truncatingIfNeeded: last), in: valueSlots)
            valueSlots[owner] = Int32(truncatingIfNeeded: valueSlot)
            valueStorage.swapAt(valueSlot, last)
        }
        valueSlots[keySlot] = valueSlots[last]
        valueSlots.removeLast()
        return valueStorage.removeLast()
    }

    /// Removes the entries at the positions, such as the offsets SwiftUI's `onDelete` passes, in one pass that also stores the rest in their shown order.
    @inlinable mutating func remove(atOffsets positions: some Sequence<Int>) {
        var isDoomed: [Bool] = [Bool](repeating: false, count: keyStorage.count)
        var found: Bool = false
        for position in positions {
            isDoomed[offsets[position]] = true
            found = true
        }
        guard found else { return }
        keep { keySlot, _, _ in !isDoomed[keySlot] }
    }

    /// Removes every entry that matches, in one pass that also stores the rest in their shown order.
    @inlinable mutating func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        try keep { _, key, value in try !shouldBeRemoved((key: key, value: value)) }
    }

    /// Keeps the entries the predicate accepts, given each key's storage offset, key and value, and stores the survivors in their shown order with every key owning the value at its own offset.
    @inlinable internal mutating func keep(where isKept: (Int, Key, Value) throws -> Bool) rethrows {
        var keptKeys: [Key] = []
        var keptValues: [Value] = []
        keptKeys.reserveCapacity(count)
        keptValues.reserveCapacity(count)
        for source in offsets.sources {
            let keySlot: Int = Int(source)
            let key: Key = keyStorage[keySlot]
            let value: Value = valueStorage[valueSlot(ofKeySlot: keySlot)]
            if try isKept(keySlot, key, value) {
                keptKeys.append(key)
                keptValues.append(value)
            }
        }
        guard keptKeys.count < count else { return }
        valueStorage = keptValues
        valueSlots = []
        offsets.keep(keptKeys, in: &keyStorage, by: Self.key)
    }

    /// Removes every entry.
    @inlinable mutating func removeAll() {
        keyStorage = []
        valueStorage = []
        valueSlots = []
        offsets.removeAll()
    }

    /// The entries that match, in order, as a dictionary with its own hash index.
    @inlinable func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> PermutableDictionary {
        var kept: PermutableDictionary = self
        try kept.removeAll { try !isIncluded($0) }
        return kept
    }

    /// The same keys in the same order with each value transformed, sharing the keys and the hash index. The transform runs in storage order, not the order shown.
    @inlinable func mapValues<NewValue>(_ transform: (Value) throws -> NewValue) rethrows -> PermutableDictionary<Key, NewValue> {
        PermutableDictionary<Key, NewValue>(keyStorage: keyStorage, valueStorage: try valueStorage.map(transform), offsets: offsets, valueSlots: valueSlots)
    }
}

// MARK: - Conformances

extension PermutableDictionary: Equatable where Value: Equatable {

    /// Two dictionaries are equal when they hold equal entries in the same order, however their storage is laid out.
    public static func == (lhs: PermutableDictionary, rhs: PermutableDictionary) -> Bool {
        lhs.count == rhs.count && lhs.elementsEqual(rhs) { $0.key == $1.key && $0.value == $1.value }
    }
}

extension PermutableDictionary: Hashable where Value: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for entry in self {
            hasher.combine(entry.key)
            hasher.combine(entry.value)
        }
    }
}

extension PermutableDictionary: Sendable where Key: Sendable, Value: Sendable {}

extension PermutableDictionary.Iterator: Sendable where Key: Sendable, Value: Sendable {}

extension PermutableDictionary: ExpressibleByDictionaryLiteral {

    @inlinable public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
}

extension PermutableDictionary: CustomStringConvertible {

    public var description: String {
        guard !isEmpty else { return "[:]" }
        return "[" + map { "\(String(reflecting: $0.key)): \(String(reflecting: $0.value))" }.joined(separator: ", ") + "]"
    }
}

extension PermutableDictionary: Encodable where Key: Encodable, Value: Encodable {

    /// Encodes the entries as one flat array that alternates each key with its value, in order.
    public func encode(to encoder: any Encoder) throws {
        var container: any UnkeyedEncodingContainer = encoder.unkeyedContainer()
        for entry in self {
            try container.encode(entry.key)
            try container.encode(entry.value)
        }
    }
}

extension PermutableDictionary: Decodable where Key: Decodable, Value: Decodable {

    /// Decodes a flat array that alternates keys and values, throwing when a key repeats or a value is missing.
    public init(from decoder: any Decoder) throws {
        var container: any UnkeyedDecodingContainer = try decoder.unkeyedContainer()
        self.init()
        while !container.isAtEnd {
            let key: Key = try container.decode(Key.self)
            guard !container.isAtEnd else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Key \(key) has no value in PermutableDictionary.")
            }
            let value: Value = try container.decode(Value.self)
            guard !contains(key: key) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Duplicate key \(key) in PermutableDictionary.")
            }
            insertNew(key, value, at: endIndex)
        }
    }
}
