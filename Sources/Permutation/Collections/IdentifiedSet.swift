// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSet.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation.swift]

/// An ordered collection of identifiable elements in which no two elements share an id, reordered only through permutations.
///
/// Elements stay in fixed storage slots and never move when the collection is reordered. The order lives in `sources`, which maps each position to a slot, so every reorder rotates integers and never hashes an id or copies an element.
public struct IdentifiedSet<Element: Identifiable> {

    /// The elements in storage order, which reordering never changes.
    @usableFromInline var slots: [Element]

    /// The storage slot of each element, keyed by its id.
    @usableFromInline var slotOfID: [Element.ID: Int]

    /// The storage slot shown at each position.
    @usableFromInline var sources: [Int]

    /// Creates an empty set.
    public init() {
        slots = []
        slotOfID = [:]
        sources = []
    }

    /// Creates a set from a sequence, keeping the first element with each id and dropping later ones.
    public init(_ elements: some Sequence<Element>) {
        self.init()
        for element in elements { append(element) }
    }
}

// MARK: - Collection

extension IdentifiedSet: RandomAccessCollection {

    @inlinable public var startIndex: Int { 0 }

    @inlinable public var endIndex: Int { sources.count }

    /// The element at the position.
    @inlinable public subscript(position: Int) -> Element {
        slots[sources[position]]
    }
}

// MARK: - PermutableCollection

extension IdentifiedSet: PermutableCollection {

    /// Applies the permutation by rotating each cycle of `sources` through one carried slot, leaving the elements and their ids untouched.
    @inlinable public mutating func apply(_ permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        precondition(permutation.minimumCount <= count, "Every offset in the cycle must be within the collection.")
        var start: Int = -1
        var carried: Int = 0
        for offset in permutation.cycle {
            if offset > start {
                if start >= 0 { sources[start] = carried }
                start = offset
                carried = sources[offset]
            } else {
                let next: Int = sources[offset]
                sources[offset] = carried
                carried = next
            }
        }
        sources[start] = carried
    }

    /// Exchanges the elements at the two positions by swapping their slots.
    @inlinable public mutating func swapAt(_ i: Int, _ j: Int) {
        sources.swapAt(i, j)
    }
}

// MARK: - Lookup

public extension IdentifiedSet {

    /// The element with the id, or nil when there is none.
    ///
    /// Setting a value replaces the element in place or appends it when the id is new, and setting nil removes it. The new value must keep the id it is stored under.
    subscript(id id: Element.ID) -> Element? {
        @inlinable get {
            slotOfID[id].map { slots[$0] }
        }
        set {
            guard let newValue else {
                remove(id: id)
                return
            }
            precondition(newValue.id == id, "An element set through subscript(id:) must keep its id.")
            update(orAppend: newValue)
        }
    }

    /// Returns whether an element has the id, in O(1).
    @inlinable func contains(id: Element.ID) -> Bool {
        slotOfID[id] != nil
    }

    /// The position of the element with the id, or nil when there is none, in O(n).
    func firstIndex(id: Element.ID) -> Int? {
        slotOfID[id].flatMap { sources.firstIndex(of: $0) }
    }
}

// MARK: - Adding

public extension IdentifiedSet {

    /// Appends the element unless its id is already present, returning whether it was added.
    @discardableResult mutating func append(_ element: Element) -> Bool {
        insert(element, at: endIndex)
    }

    /// Inserts the element at the position unless its id is already present, returning whether it was added.
    @discardableResult mutating func insert(_ element: Element, at index: Int) -> Bool {
        precondition(index >= startIndex && index <= endIndex, "Index out of range.")
        guard slotOfID[element.id] == nil else { return false }
        slotOfID[element.id] = slots.count
        sources.insert(slots.count, at: index)
        slots.append(element)
        return true
    }
}

// MARK: - Replacing

public extension IdentifiedSet {

    /// Replaces the element with the same id in place, returning the old element, or returns nil and changes nothing when the id is absent.
    @discardableResult mutating func replace(_ element: Element) -> Element? {
        guard let slot: Int = slotOfID[element.id] else { return nil }
        let old: Element = slots[slot]
        slots[slot] = element
        return old
    }

    /// Replaces the element at the position, returning the old element, and may change the id as long as no other element has the new one.
    @discardableResult mutating func replace(at index: Int, with element: Element) -> Element {
        let slot: Int = sources[index]
        let old: Element = slots[slot]
        if old.id != element.id {
            precondition(slotOfID[element.id] == nil, "Another element already has this id.")
            slotOfID[old.id] = nil
            slotOfID[element.id] = slot
        }
        slots[slot] = element
        return old
    }
}

// MARK: - Updating

public extension IdentifiedSet {

    /// Replaces the element with the same id in place, or appends it when the id is new, returning the old element when there was one.
    @discardableResult mutating func update(orAppend element: Element) -> Element? {
        update(orInsert: element, at: endIndex)
    }

    /// Replaces the element with the same id in place, or inserts it at the position when the id is new, returning the old element when there was one.
    @discardableResult mutating func update(orInsert element: Element, at index: Int) -> Element? {
        if let old: Element = replace(element) { return old }
        insert(element, at: index)
        return nil
    }
}

// MARK: - Removing

public extension IdentifiedSet {

    /// Removes the element with the id, returning it, or returns nil when there is none.
    @discardableResult mutating func remove(id: Element.ID) -> Element? {
        firstIndex(id: id).map { remove(at: $0) }
    }

    /// Removes the element at the position and returns it, filling its storage slot with the last slot's element.
    @discardableResult mutating func remove(at index: Int) -> Element {
        let slot: Int = sources.remove(at: index)
        let removed: Element = slots[slot]
        slotOfID[removed.id] = nil
        let last: Int = slots.count - 1
        if slot != last {
            let moved: Element = slots[last]
            slots[slot] = moved
            slotOfID[moved.id] = slot
            sources[sources.firstIndex(of: last)!] = slot
        }
        slots.removeLast()
        return removed
    }

    /// Removes every element.
    mutating func removeAll() {
        self = IdentifiedSet()
    }
}

// MARK: - Conformances

extension IdentifiedSet: Equatable where Element: Equatable {

    /// Two sets are equal when they hold equal elements in the same order, however their storage is laid out.
    public static func == (lhs: IdentifiedSet, rhs: IdentifiedSet) -> Bool {
        lhs.elementsEqual(rhs)
    }
}

extension IdentifiedSet: Hashable where Element: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for element in self { hasher.combine(element) }
    }
}

extension IdentifiedSet: Sendable where Element: Sendable, Element.ID: Sendable {}

extension IdentifiedSet: CustomStringConvertible {

    public var description: String {
        Array(self).description
    }
}
