// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableSet.swift
// dependencies: [Collections/Offsets.swift, Collections/PermutableCollection.swift, Collections/UpsertableCollection.swift]

/// An ordered collection of unique hashable elements whose order changes without moving them.
///
/// The elements sit in an array that reordering never touches, and `Offsets` keeps both the order shown and a hash index into that array. Sorting, shuffling or moving rewrites only the order, while membership checks and removals stay O(1).
///
/// `PermutableSet` offers the set operations whose result has a clear order, and does not conform to `SetAlgebra`, whose laws assume equality ignores order. In every operation the elements kept from the receiver stay in its order, and the new ones follow in the order of the argument.
public struct PermutableSet<Element: Hashable> {

    /// The elements in storage order, which reordering never changes.
    @usableFromInline var elements: [Element]

    /// The storage offset shown at each position, with a hash index from each element to its storage offset.
    @usableFromInline var offsets: Offsets

    /// Creates an empty set.
    @inlinable public init() {
        elements = []
        offsets = Offsets()
    }

    /// Creates a set from a sequence, keeping the first of any repeated elements where it first appeared. An array without repeats is adopted without copying it.
    @inlinable public init(_ elements: some Sequence<Element>) {
        self.elements = Array(elements)
        offsets = Offsets()
        offsets.index(&self.elements, by: Self.key)
    }

    /// Each element is its own key, written as a plain function so every lookup calls it directly.
    @inlinable static func key(_ element: Element) -> Element {
        element
    }
}

// MARK: - Collection

extension PermutableSet: RandomAccessCollection {

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
            precondition(count <= (isInStorageOrder ? elements.count : sources.count), "The count must fit the storage it reads.")
        }

        @inlinable public mutating func next() -> Element? {
            let current: Int = position
            guard current < count else { return nil }
            position = current + 1
            // The initializer checked that `count` fits the array each branch reads, so neither read needs a second bounds check.
            if isInStorageOrder { return elements.withUnsafeBufferPointer { $0[current] } }
            return elements[Int(sources.withUnsafeBufferPointer { $0[current] })]
        }
    }

    /// Answers `contains(_:)` from the hash index in O(1).
    @inlinable public func _customContainsEquatableElement(_ element: Element) -> Bool? {
        contains(element)
    }

    /// Answers `firstIndex(of:)` from the hash index, then finds the position of that storage offset.
    @inlinable public func _customIndexOfEquatableElement(_ element: Element) -> Int?? {
        Optional(offsets.offset(of: element, in: elements, by: Self.key).flatMap { offsets.position(ofOffset: $0) })
    }

    /// Answers `lastIndex(of:)` the same way, since an element appears at most once.
    @inlinable public func _customLastIndexOfEquatableElement(_ element: Element) -> Int?? {
        _customIndexOfEquatableElement(element)
    }
}

// MARK: - PermutableCollection

extension PermutableSet: PermutableCollection {

    /// Applies the permutation to the order alone, leaving the elements and the hash index untouched.
    @inlinable public mutating func apply(_ permutation: Permutation) {
        offsets.apply(permutation)
    }

    /// Exchanges the elements at the two positions by swapping their storage offsets.
    @inlinable public mutating func swapAt(_ i: Int, _ j: Int) {
        offsets.swapAt(i, j)
    }
}

// MARK: - Membership

public extension PermutableSet {

    /// Returns whether the set holds the element, in O(1).
    @inlinable func contains(_ element: Element) -> Bool {
        offsets.offset(of: element, in: elements, by: Self.key) != nil
    }

    /// Removes the element and returns the stored copy, or returns nil when it is absent.
    @inlinable @discardableResult mutating func remove(_ element: Element) -> Element? {
        guard let offset: Int = offsets.offset(of: element, in: elements, by: Self.key) else { return nil }
        return offsets.remove(offset: offset, from: &elements, by: Self.key)
    }
}

// MARK: - Adding

public extension PermutableSet {

    /// Appends the element unless it is already present, returning whether it was added.
    @inlinable @discardableResult mutating func append(_ element: Element) -> Bool {
        insert(element, at: endIndex)
    }

    /// Inserts the element at the position unless it is already present, returning whether it was added.
    @inlinable @discardableResult mutating func insert(_ element: Element, at index: Int) -> Bool {
        offsets.insert(element, at: index, into: &elements, by: Self.key)
    }

    /// Appends every element, or none of them when any is already present or repeats within the batch, returning whether they were added.
    @inlinable @discardableResult mutating func append(contentsOf newElements: some Sequence<Element>) -> Bool {
        insert(contentsOf: newElements, at: endIndex)
    }

    /// Inserts every element as one block at the position, or none of them when any is already present or repeats within the batch, returning whether they were added.
    @inlinable @discardableResult mutating func insert(contentsOf newElements: some Sequence<Element>, at index: Int) -> Bool {
        precondition(index >= startIndex && index <= endIndex, "Index out of range.")
        let batch: [Element] = Array(newElements)
        var seen: Set<Element> = Set(minimumCapacity: batch.count)
        for element in batch {
            guard !contains(element), seen.insert(element).inserted else { return false }
        }
        insertBlock(batch, at: index)
        return true
    }

    /// Inserts elements that are all new and distinct as one block at the position, appending them first and then moving the block in a single shift.
    @inlinable internal mutating func insertBlock(_ batch: [Element], at index: Int) {
        guard !batch.isEmpty else { return }
        let start: Int = endIndex
        offsets.reserveCapacity(count + batch.count, for: elements, by: Self.key)
        for element in batch { offsets.insert(element, at: offsets.endIndex, into: &elements, by: Self.key) }
        offsets.moveTail(from: start, to: index)
    }

    /// Reserves room for the count of elements, so adding up to it neither copies storage nor rebuilds the hash index.
    @inlinable mutating func reserveCapacity(_ minimumCapacity: Int) {
        elements.reserveCapacity(minimumCapacity)
        offsets.reserveSourcesCapacity(minimumCapacity)
        offsets.reserveCapacity(minimumCapacity, for: elements, by: Self.key)
    }
}

// MARK: - Replacing and updating

public extension PermutableSet {

    /// Replaces the stored element equal to this one, returning the old copy, or returns nil and changes nothing when none is equal. This matters only when equal elements can still be told apart, such as instances of a class.
    @inlinable @discardableResult mutating func replace(_ element: Element) -> Element? {
        guard let offset: Int = offsets.offset(of: element, in: elements, by: Self.key) else { return nil }
        let old: Element = elements[offset]
        elements[offset] = element
        return old
    }

    /// Replaces the element at the position, returning the old element, as long as no other position holds the new one.
    @inlinable @discardableResult mutating func replace(at index: Int, with element: Element) -> Element {
        offsets.replace(offset: offsets[index], with: element, in: &elements, by: Self.key)
    }

    /// Replaces the equal element in place, or appends the element when none is equal, returning the old copy when there was one.
    @inlinable @discardableResult mutating func update(orAppend element: Element) -> Element? {
        update(orInsert: element, at: endIndex)
    }

    /// Replaces the equal element in place, or inserts the element at the position when none is equal, returning the old copy when there was one.
    @inlinable @discardableResult mutating func update(orInsert element: Element, at index: Int) -> Element? {
        if let old: Element = replace(element) { return old }
        insert(element, at: index)
        return nil
    }

    /// Replaces each element already present in place and appends the rest in order. When an element repeats within the batch, the later one wins.
    @inlinable mutating func update(orAppend newElements: some Sequence<Element>) {
        update(orInsert: newElements, at: endIndex)
    }

    /// Replaces each element already present in place and inserts the rest in order as one block at the position. When an element repeats within the batch, the later one wins.
    @inlinable mutating func update(orInsert newElements: some Sequence<Element>, at index: Int) {
        precondition(index >= startIndex && index <= endIndex, "Index out of range.")
        var added: [Element] = []
        var addedPositions: [Element: Int] = [:]
        for element in newElements {
            if replace(element) != nil { continue }
            if let position: Int = addedPositions[element] {
                added[position] = element
            } else {
                addedPositions[element] = added.count
                added.append(element)
            }
        }
        insertBlock(added, at: index)
    }
}

// MARK: - Removing

public extension PermutableSet {

    /// Removes the element at the position and returns it, moving the last stored element into its storage offset.
    @inlinable @discardableResult mutating func remove(at index: Int) -> Element {
        offsets.remove(at: index, from: &elements, by: Self.key)
    }

    /// Removes every element that matches, in one pass that also stores the rest in their shown order.
    @inlinable mutating func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        try offsets.removeAll(from: &elements, by: Self.key, where: shouldBeRemoved)
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
        offsets.removeAll(marked: doomed, from: &elements, by: Self.key)
    }

    /// Removes every element.
    @inlinable mutating func removeAll() {
        elements = []
        offsets.removeAll()
    }

    /// The elements that match, in order, as a set with its own hash index.
    @inlinable func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> PermutableSet {
        var kept: PermutableSet = self
        try kept.removeAll { try !isIncluded($0) }
        return kept
    }
}

// MARK: - Set operations

public extension PermutableSet {

    /// Marks the storage offset of every element of the sequence that the set holds, and counts the distinct ones marked.
    @inlinable internal func marks(of other: some Sequence<Element>) -> Marks {
        if let other: PermutableSet = other as? PermutableSet { return marks(of: other.elements) }
        var marks: Marks = Marks(isMarked: [Bool](repeating: false, count: elements.count), count: 0, hasOthers: false)
        for element in other {
            if let offset: Int = offsets.offset(of: element, in: elements, by: Self.key) {
                if !marks.isMarked[offset] {
                    marks.isMarked[offset] = true
                    marks.count += 1
                }
            } else {
                marks.hasOthers = true
            }
        }
        return marks
    }

    /// Adds each element of the sequence that is new, after the existing elements, in the order of the sequence.
    @inlinable mutating func formUnion(_ other: some Sequence<Element>) {
        offsets.append(contentsOf: other, into: &elements, by: Self.key)
    }

    /// The existing elements in order, followed by the new elements of the sequence in its order.
    @inlinable func union(_ other: some Sequence<Element>) -> PermutableSet {
        var result: PermutableSet = self
        result.formUnion(other)
        return result
    }

    /// Keeps only the elements that also appear in the sequence, in their current order.
    @inlinable mutating func formIntersection(_ other: some Sequence<Element>) {
        let marks: Marks = marks(of: other)
        guard marks.count < count else { return }
        offsets.removeAll(marked: marks.isMarked.map { !$0 }, from: &elements, by: Self.key)
    }

    /// The elements that also appear in the sequence, in their current order.
    @inlinable func intersection(_ other: some Sequence<Element>) -> PermutableSet {
        var result: PermutableSet = self
        result.formIntersection(other)
        return result
    }

    /// Removes the elements that appear in the sequence, keeping the rest in their current order.
    @inlinable mutating func subtract(_ other: some Sequence<Element>) {
        let marks: Marks = marks(of: other)
        guard marks.count > 0 else { return }
        offsets.removeAll(marked: marks.isMarked, from: &elements, by: Self.key)
    }

    /// The elements that do not appear in the sequence, in their current order.
    @inlinable func subtracting(_ other: some Sequence<Element>) -> PermutableSet {
        var result: PermutableSet = self
        result.subtract(other)
        return result
    }

    /// Removes the elements that appear in the sequence and adds the ones that are new, after the rest, in the order of the sequence.
    @inlinable mutating func formSymmetricDifference(_ other: some Sequence<Element>) {
        var isShared: [Bool] = [Bool](repeating: false, count: elements.count)
        var hasShared: Bool = false
        var added: [Element] = []
        for element in other {
            if let offset: Int = offsets.offset(of: element, in: elements, by: Self.key) {
                isShared[offset] = true
                hasShared = true
            } else {
                added.append(element)
            }
        }
        if hasShared { offsets.removeAll(marked: isShared, from: &elements, by: Self.key) }
        offsets.append(contentsOf: added, into: &elements, by: Self.key)
    }

    /// The elements that appear in exactly one of the set and the sequence: the set's in their current order, then the sequence's in its order.
    @inlinable func symmetricDifference(_ other: some Sequence<Element>) -> PermutableSet {
        var result: PermutableSet = self
        result.formSymmetricDifference(other)
        return result
    }

    /// Returns whether every element of the set appears in the sequence.
    @inlinable func isSubset(of other: some Sequence<Element>) -> Bool {
        if let other: PermutableSet = other as? PermutableSet {
            return count <= other.count && elements.allSatisfy { other.contains($0) }
        }
        return marks(of: other).count == count
    }

    /// Returns whether every element of the set appears in the sequence, and the sequence has an element the set lacks.
    @inlinable func isStrictSubset(of other: some Sequence<Element>) -> Bool {
        let marks: Marks = marks(of: other)
        return marks.count == count && marks.hasOthers
    }

    /// Returns whether every element of the sequence is in the set.
    @inlinable func isSuperset(of other: some Sequence<Element>) -> Bool {
        if let other: PermutableSet = other as? PermutableSet {
            return other.count <= count && other.elements.allSatisfy { self.contains($0) }
        }
        return other.allSatisfy { self.contains($0) }
    }

    /// Returns whether every element of the sequence is in the set, and the set has an element the sequence lacks.
    @inlinable func isStrictSuperset(of other: some Sequence<Element>) -> Bool {
        let marks: Marks = marks(of: other)
        return !marks.hasOthers && marks.count < count
    }

    /// Returns whether no element of the sequence is in the set.
    @inlinable func isDisjoint(with other: some Sequence<Element>) -> Bool {
        if let other: PermutableSet = other as? PermutableSet {
            if count <= other.count { return !elements.contains { other.contains($0) } }
            return !other.elements.contains { self.contains($0) }
        }
        return !other.contains { self.contains($0) }
    }
}

extension PermutableSet {

    /// Which storage offsets a sequence hit, how many distinct ones, and whether it held anything the set lacks.
    @usableFromInline struct Marks {
        @usableFromInline var isMarked: [Bool]
        @usableFromInline var count: Int
        @usableFromInline var hasOthers: Bool

        @inlinable init(isMarked: [Bool], count: Int, hasOthers: Bool) {
            self.isMarked = isMarked
            self.count = count
            self.hasOthers = hasOthers
        }
    }
}

// MARK: - Conformances

extension PermutableSet: Equatable {

    /// Two sets are equal when they hold equal elements in the same order, however their storage is laid out.
    public static func == (lhs: PermutableSet, rhs: PermutableSet) -> Bool {
        lhs.elementsEqual(rhs)
    }
}

extension PermutableSet: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for element in self { hasher.combine(element) }
    }
}

extension PermutableSet: UpsertableCollection {}

extension PermutableSet: Sendable where Element: Sendable {}

extension PermutableSet.Iterator: Sendable where Element: Sendable {}

extension PermutableSet: ExpressibleByArrayLiteral {

    @inlinable public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension PermutableSet: CustomStringConvertible {

    public var description: String {
        Array(self).description
    }
}

extension PermutableSet: Encodable where Element: Encodable {

    /// Encodes the elements as a plain array in order.
    public func encode(to encoder: any Encoder) throws {
        var container: any UnkeyedEncodingContainer = encoder.unkeyedContainer()
        for element in self { try container.encode(element) }
    }
}

extension PermutableSet: Decodable where Element: Decodable {

    /// Decodes a plain array of elements, throwing when one repeats.
    public init(from decoder: any Decoder) throws {
        var container: any UnkeyedDecodingContainer = try decoder.unkeyedContainer()
        self.init()
        while !container.isAtEnd {
            let element: Element = try container.decode(Element.self)
            guard append(element) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Duplicate element \(element) in PermutableSet.")
            }
        }
    }
}
