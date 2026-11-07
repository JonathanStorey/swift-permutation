// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSet.swift
// dependencies: [Collections/Offsets.swift, Collections/PermutableCollection.swift, Collections/UpsertableCollection.swift, Permutation/Permutation.swift]

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

    /// Iterates the elements in order, reading storage straight through while nothing has reordered it.
    @inlinable public func makeIterator() -> Iterator {
        Iterator(elements: elements, sources: offsets.storedSources, count: offsets.count, isInStorageOrder: offsets.isInStorageOrder)
    }

    /// Hands over the storage itself while it is in the order shown, so copying the set into an array or scanning it runs at array speed.
    @inlinable public func withContiguousStorageIfAvailable<Result>(_ body: (UnsafeBufferPointer<Element>) throws -> Result) rethrows -> Result? {
        guard offsets.isInStorageOrder else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// An iterator over the elements in order.
    public struct Iterator: IteratorProtocol {

        @usableFromInline let elements: [Element]

        @usableFromInline let sources: [Int32]

        @usableFromInline let count: Int

        @usableFromInline let isInStorageOrder: Bool

        @usableFromInline var position: Int

        @inlinable init(elements: [Element], sources: [Int32], count: Int, isInStorageOrder: Bool) {
            self.elements = elements
            self.sources = sources
            self.count = count
            self.isInStorageOrder = isInStorageOrder
            position = 0
        }

        @inlinable public mutating func next() -> Element? {
            let current: Int = position
            guard current < count else { return nil }
            position = current + 1
            return isInStorageOrder ? elements[current] : elements[Int(sources[current])]
        }
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

    /// Appends every element, or none of them when any id is already present or repeats within the batch, returning whether they were added.
    @inlinable @discardableResult mutating func append(contentsOf newElements: some Sequence<Element>) -> Bool {
        insert(contentsOf: newElements, at: endIndex)
    }

    /// Inserts every element as one block at the position, or none of them when any id is already present or repeats within the batch, returning whether they were added.
    @inlinable @discardableResult mutating func insert(contentsOf newElements: some Sequence<Element>, at index: Int) -> Bool {
        precondition(index >= startIndex && index <= endIndex, "Index out of range.")
        let batch: [Element] = Array(newElements)
        var batchIDs: Set<Element.ID> = Set(minimumCapacity: batch.count)
        for element in batch {
            guard !contains(id: element.id), batchIDs.insert(element.id).inserted else { return false }
        }
        insertBlock(batch, at: index)
        return true
    }

    /// Inserts elements whose ids are all new and distinct as one block at the position, appending them first and then moving the block in a single shift.
    @inlinable internal mutating func insertBlock(_ batch: [Element], at index: Int) {
        guard !batch.isEmpty else { return }
        let start: Int = endIndex
        offsets.reserveCapacity(count + batch.count, for: elements, by: Self.id)
        for element in batch { offsets.insert(element, at: offsets.endIndex, into: &elements, by: Self.id) }
        offsets.moveTail(from: start, to: index)
    }

    /// Reserves room for the count of elements, so adding up to it neither copies storage nor rebuilds the id index.
    @inlinable mutating func reserveCapacity(_ minimumCapacity: Int) {
        elements.reserveCapacity(minimumCapacity)
        offsets.reserveSourcesCapacity(minimumCapacity)
        offsets.reserveCapacity(minimumCapacity, for: elements, by: Self.id)
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

    /// Replaces each element with an id already present in place, and appends the rest in order. When an id repeats within the batch, the later element wins.
    @inlinable mutating func update(orAppend newElements: some Sequence<Element>) {
        update(orInsert: newElements, at: endIndex)
    }

    /// Replaces each element with an id already present in place, and inserts the rest in order as one block at the position. When an id repeats within the batch, the later element wins.
    @inlinable mutating func update(orInsert newElements: some Sequence<Element>, at index: Int) {
        precondition(index >= startIndex && index <= endIndex, "Index out of range.")
        var added: [Element] = []
        var addedPositions: [Element.ID: Int] = [:]
        for element in newElements {
            if replace(element) != nil { continue }
            if let position: Int = addedPositions[element.id] {
                added[position] = element
            } else {
                addedPositions[element.id] = added.count
                added.append(element)
            }
        }
        insertBlock(added, at: index)
    }
}

// MARK: - Removing

public extension IdentifiedSet {

    /// Removes the element with the id, returning it, or returns nil when there is none.
    @inlinable @discardableResult mutating func remove(id: Element.ID) -> Element? {
        guard let offset: Int = offsets.offset(of: id, in: elements, by: Self.id) else { return nil }
        return offsets.remove(offset: offset, from: &elements, by: Self.id)
    }

    /// Removes the elements with the ids, in one pass that also stores the rest in their shown order. Ids with no element are ignored.
    @inlinable mutating func remove(ids: some Sequence<Element.ID>) {
        var doomed: [Bool] = Array(repeating: false, count: elements.count)
        var found: Bool = false
        for id in ids {
            guard let offset: Int = offsets.offset(of: id, in: elements, by: Self.id) else { continue }
            doomed[offset] = true
            found = true
        }
        guard found else { return }
        offsets.removeAll(marked: doomed, from: &elements, by: Self.id)
    }

    /// Removes the element at the position and returns it, moving the last stored element into its storage offset.
    @inlinable @discardableResult mutating func remove(at index: Int) -> Element {
        offsets.remove(at: index, from: &elements, by: Self.id)
    }

    /// Removes every element that matches, in one pass that also stores the rest in their shown order.
    @inlinable mutating func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        try offsets.removeAll(from: &elements, by: Self.id, where: shouldBeRemoved)
    }

    /// Removes the elements at the positions, such as the offsets SwiftUI's `onDelete` passes, in one pass that also stores the rest in their shown order.
    @inlinable mutating func remove(atOffsets positions: some Sequence<Int>) {
        var doomed: [Bool] = Array(repeating: false, count: elements.count)
        var found: Bool = false
        for position in positions {
            doomed[offsets[position]] = true
            found = true
        }
        guard found else { return }
        offsets.removeAll(marked: doomed, from: &elements, by: Self.id)
    }

    /// Removes every element.
    @inlinable mutating func removeAll() {
        elements = []
        offsets.removeAll()
    }
}

// MARK: - Moving by id

extension IdentifiedSet {

    /// Moves the elements with the ids, keeping their current relative order, to just before the element with the destination id, or to the end when it is nil or absent, and returns the permutation applied. Ids with no element are ignored, and a destination among the moved ids stands for its current position.
    @inlinable @discardableResult mutating func move(ids: some Sequence<Element.ID>, before destination: Element.ID?) -> Permutation {
        var isMovedOffset: [Bool] = [Bool](repeating: false, count: elements.count)
        for id in ids {
            if let offset: Int = offsets.offset(of: id, in: elements, by: Self.id) { isMovedOffset[offset] = true }
        }
        let destinationOffset: Int? = destination.flatMap { offsets.offset(of: $0, in: elements, by: Self.id) }
        var isMoved: [Bool] = [Bool](repeating: false, count: elements.count)
        var movedCount: Int = 0
        var target: Int = endIndex
        for (position, offset) in offsets.enumerated() {
            if isMovedOffset[offset] {
                isMoved[position] = true
                movedCount += 1
            }
            if offset == destinationOffset { target = position }
        }
        return move(marked: isMoved, count: movedCount, toOffset: target)
    }
}

// MARK: - Views

public extension IdentifiedSet {

    /// The ids in order, read through the elements without copying them.
    @inlinable var ids: some RandomAccessCollection<Element.ID> {
        lazy.map(\.id)
    }

    /// The elements that match, in order, as a set with its own id index.
    @inlinable func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> IdentifiedSet {
        var kept: IdentifiedSet = self
        try kept.removeAll { try !isIncluded($0) }
        return kept
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

extension IdentifiedSet: UpsertableCollection {}

extension IdentifiedSet: Sendable where Element: Sendable {}

extension IdentifiedSet.Iterator: Sendable where Element: Sendable {}

extension IdentifiedSet: CustomStringConvertible {

    public var description: String {
        Array(self).description
    }
}
