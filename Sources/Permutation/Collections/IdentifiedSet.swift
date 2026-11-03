// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSet.swift
// dependencies: [Collections/Offsets.swift, Collections/PermutableCollection.swift, Permutation/Permutation.swift]

/// An ordered collection of identifiable elements in which no two elements share an id, reordered only through permutations.
///
/// Elements stay where they were stored and never move when the collection is reordered. The order and the id index live in `offsets`, so every reorder rotates integers and never hashes an id or copies an element.
public struct IdentifiedSet<Element: Identifiable> {

    /// The elements in storage order, which reordering never changes.
    @usableFromInline var elements: [Element]

    /// The storage offset shown at each position, with a hash index from each id to its storage offset.
    @usableFromInline var offsets: Offsets

    /// Creates an empty set.
    @inlinable public init() {
        elements = []
        offsets = Offsets()
    }

    /// Creates a set from a sequence, settling each repeated id with the uniquing rule, which by default keeps the first element.
    ///
    /// An element that repeats an id never takes a new position: the element the rule returns stays where that id first appeared. With `.keepFirst`, a whole array without repeated ids is adopted without copying it.
    @inlinable public init(_ elements: some Sequence<Element>, uniquingIDsWith uniquing: Uniquing = .keepFirst) {
        self.elements = []
        offsets = Offsets()
        guard let merge = uniquing.merge else {
            self.elements = Array(elements)
            offsets.index(&self.elements, by: Self.id)
            return
        }
        for element in elements {
            if let offset: Int = offsets.offset(of: element.id, in: self.elements, by: Self.id) {
                let merged: Element = merge(self.elements[offset], element)
                precondition(merged.id == element.id, "A uniquing rule must return an element with the same id.")
                self.elements[offset] = merged
            } else {
                _ = offsets.insert(element, at: offsets.endIndex, into: &self.elements, by: Self.id)
            }
        }
    }

    /// Reads an element's id, as a plain function so that every lookup calls it directly instead of through a key path.
    @inlinable static func id(_ element: Element) -> Element.ID {
        element.id
    }
}

// MARK: - Collection

extension IdentifiedSet: RandomAccessCollection {

    @inlinable public var startIndex: Int { 0 }

    @inlinable public var endIndex: Int { offsets.count }

    /// The element at the position.
    @inlinable public subscript(position: Int) -> Element {
        elements[offsets[position]]
    }
}

// MARK: - PermutableCollection

extension IdentifiedSet: PermutableCollection {

    /// Applies the permutation to the order alone, leaving the elements and the id index untouched.
    @inlinable public mutating func apply(_ permutation: Permutation) {
        offsets.apply(permutation)
    }

    /// Exchanges the elements at the two positions by swapping their storage offsets.
    @inlinable public mutating func swapAt(_ i: Int, _ j: Int) {
        offsets.swapAt(i, j)
    }
}

// MARK: - Lookup

public extension IdentifiedSet {

    /// The element with the id, or nil when there is none.
    ///
    /// Setting a value replaces the element in place or appends it when the id is new, and setting nil removes it. The new value must keep the id it is stored under.
    subscript(id id: Element.ID) -> Element? {
        @inlinable get {
            offsets.offset(of: id, in: elements, by: Self.id).map { elements[$0] }
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
        offsets.offset(of: id, in: elements, by: Self.id) != nil
    }

    /// The position of the element with the id, or nil when there is none, in O(n).
    @inlinable func firstIndex(id: Element.ID) -> Int? {
        offsets.offset(of: id, in: elements, by: Self.id).flatMap { offsets.position(ofOffset: $0) }
    }
}

// MARK: - Adding

public extension IdentifiedSet {

    /// Appends the element unless its id is already present, returning whether it was added.
    @inlinable @discardableResult mutating func append(_ element: Element) -> Bool {
        insert(element, at: endIndex)
    }

    /// Inserts the element at the position unless its id is already present, returning whether it was added.
    @inlinable @discardableResult mutating func insert(_ element: Element, at index: Int) -> Bool {
        offsets.insert(element, at: index, into: &elements, by: Self.id)
    }
}

// MARK: - Replacing

public extension IdentifiedSet {

    /// Replaces the element with the same id in place, returning the old element, or returns nil and changes nothing when the id is absent.
    @inlinable @discardableResult mutating func replace(_ element: Element) -> Element? {
        guard let offset: Int = offsets.offset(of: element.id, in: elements, by: Self.id) else { return nil }
        let old: Element = elements[offset]
        elements[offset] = element
        return old
    }

    /// Replaces the element at the position, returning the old element, and may change the id as long as no other element has the new one.
    @inlinable @discardableResult mutating func replace(at index: Int, with element: Element) -> Element {
        offsets.replace(offset: offsets[index], with: element, in: &elements, by: Self.id)
    }
}

// MARK: - Updating

public extension IdentifiedSet {

    /// Replaces the element with the same id in place, or appends it when the id is new, returning the old element when there was one.
    @inlinable @discardableResult mutating func update(orAppend element: Element) -> Element? {
        update(orInsert: element, at: endIndex)
    }

    /// Replaces the element with the same id in place, or inserts it at the position when the id is new, returning the old element when there was one.
    @inlinable @discardableResult mutating func update(orInsert element: Element, at index: Int) -> Element? {
        if let old: Element = replace(element) { return old }
        insert(element, at: index)
        return nil
    }
}

// MARK: - Removing

public extension IdentifiedSet {

    /// Removes the element with the id, returning it, or returns nil when there is none.
    @inlinable @discardableResult mutating func remove(id: Element.ID) -> Element? {
        firstIndex(id: id).map { remove(at: $0) }
    }

    /// Removes the element at the position and returns it, moving the last stored element into its storage offset.
    @inlinable @discardableResult mutating func remove(at index: Int) -> Element {
        offsets.remove(at: index, from: &elements, by: Self.id)
    }

    /// Removes every element that matches, in one pass that also stores the rest in their shown order.
    @inlinable mutating func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        try offsets.removeAll(from: &elements, by: Self.id, where: shouldBeRemoved)
    }

    /// Removes every element.
    @inlinable mutating func removeAll() {
        elements = []
        offsets.removeAll()
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

extension IdentifiedSet: Sendable where Element: Sendable {}

extension IdentifiedSet: CustomStringConvertible {

    public var description: String {
        Array(self).description
    }
}
