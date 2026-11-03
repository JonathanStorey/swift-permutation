// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/UpsertableCollection.swift
// dependencies: [Collections/PermutableCollection.swift]

/// An ordered collection that holds each element at most once, with one vocabulary for creating, reading, updating and deleting them.
///
/// A conforming type decides what makes two elements the same, such as a shared id, and supplies three operations: `insert(_:at:)`, which refuses a duplicate; `replace(_:)`, which swaps in a new version of an element already present; and `remove(at:)`. Every other operation has a default built from those three, which a type may override with a faster version that keeps the same meaning:
///
/// - `append` and `insert` add only what is new and report whether they did. The batch forms are atomic: they add every element, or none when any is already present or repeats within the batch.
/// - `replace` changes only what is already present, in place.
/// - `update` replaces what is present and adds what is new. A batch applies its elements in order, so when one repeats, the later element wins.
/// - `remove` deletes by position.
public protocol UpsertableCollection: PermutableCollection, RandomAccessCollection where Index == Int {

    /// Inserts the element at the position unless it is already present, returning whether it was added.
    @discardableResult mutating func insert(_ element: Element, at index: Int) -> Bool

    /// Replaces the element already present that matches this one, in place, returning the old element, or returns nil and changes nothing when none matches.
    @discardableResult mutating func replace(_ element: Element) -> Element?

    /// Removes the element at the position and returns it.
    @discardableResult mutating func remove(at index: Int) -> Element

    /// Appends the element unless it is already present, returning whether it was added.
    @discardableResult mutating func append(_ element: Element) -> Bool

    /// Appends every element, or none of them when any is already present or repeats within the batch, returning whether they were added.
    @discardableResult mutating func append(contentsOf newElements: some Sequence<Element>) -> Bool

    /// Inserts every element as one block at the position, or none of them when any is already present or repeats within the batch, returning whether they were added.
    @discardableResult mutating func insert(contentsOf newElements: some Sequence<Element>, at index: Int) -> Bool

    /// Replaces the matching element in place, or appends the element when none matches, returning the old element when there was one.
    @discardableResult mutating func update(orAppend element: Element) -> Element?

    /// Replaces the matching element in place, or inserts the element at the position when none matches, returning the old element when there was one.
    @discardableResult mutating func update(orInsert element: Element, at index: Int) -> Element?

    /// Replaces each matching element in place and appends the rest in order. When an element repeats within the batch, the later one wins.
    mutating func update(orAppend newElements: some Sequence<Element>)

    /// Replaces each matching element in place and inserts the rest in order as one block at the position. When an element repeats within the batch, the later one wins.
    mutating func update(orInsert newElements: some Sequence<Element>, at index: Int)

    /// Removes the elements at the positions.
    mutating func remove(atOffsets positions: some Sequence<Int>)

    /// Removes every element that matches.
    mutating func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows
}

public extension UpsertableCollection {

    @inlinable @discardableResult mutating func append(_ element: Element) -> Bool {
        insert(element, at: endIndex)
    }

    @inlinable @discardableResult mutating func append(contentsOf newElements: some Sequence<Element>) -> Bool {
        insert(contentsOf: newElements, at: endIndex)
    }

    /// Inserts one element at a time and, on the first refusal, removes the ones it added, so the collection is left as it was.
    @inlinable @discardableResult mutating func insert(contentsOf newElements: some Sequence<Element>, at index: Int) -> Bool {
        precondition(index >= startIndex && index <= endIndex, "Index out of range.")
        var next: Int = index
        for element in newElements {
            guard insert(element, at: next) else {
                for added in (index..<next).reversed() { remove(at: added) }
                return false
            }
            next += 1
        }
        return true
    }

    @inlinable @discardableResult mutating func update(orAppend element: Element) -> Element? {
        update(orInsert: element, at: endIndex)
    }

    @inlinable @discardableResult mutating func update(orInsert element: Element, at index: Int) -> Element? {
        if let old: Element = replace(element) { return old }
        insert(element, at: index)
        return nil
    }

    @inlinable mutating func update(orAppend newElements: some Sequence<Element>) {
        update(orInsert: newElements, at: endIndex)
    }

    /// Applies the batch one element at a time, so a repeat of an element added earlier in the batch replaces it in place.
    @inlinable mutating func update(orInsert newElements: some Sequence<Element>, at index: Int) {
        precondition(index >= startIndex && index <= endIndex, "Index out of range.")
        var next: Int = index
        for element in newElements where replace(element) == nil {
            insert(element, at: next)
            next += 1
        }
    }

    @inlinable mutating func remove(atOffsets positions: some Sequence<Int>) {
        for position in Set(positions).sorted(by: >) { remove(at: position) }
    }

    @inlinable mutating func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        for position in indices.reversed() where try shouldBeRemoved(self[position]) { remove(at: position) }
    }
}
