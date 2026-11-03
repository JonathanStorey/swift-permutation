// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSet+Uniquing.swift
// dependencies: [Collections/IdentifiedSet.swift]

public extension IdentifiedSet {

    /// How a set built from a sequence settles elements that share an id.
    struct Uniquing {

        /// Merges the element already kept with a later one that shares its id, or nil to keep the first without merging.
        @usableFromInline let merge: ((Element, Element) -> Element)?

        @inlinable init(merge: ((Element, Element) -> Element)?) {
            self.merge = merge
        }

        /// Keeps the first element with each id and drops later ones.
        @inlinable static var keepFirst: Uniquing { Uniquing(merge: nil) }

        /// Keeps the last element with each id, at the position where that id first appeared.
        @inlinable static var keepLast: Uniquing { Uniquing(merge: { _, later in later }) }

        /// Merges each later element into the one already kept, which must keep its id.
        @inlinable static func combine(_ merge: @escaping (_ kept: Element, _ later: Element) -> Element) -> Uniquing {
            Uniquing(merge: merge)
        }
    }
}

// MARK: - Array literal

extension IdentifiedSet: ExpressibleByArrayLiteral {

    /// Creates a set from a literal, which must not repeat an id.
    @inlinable public init(arrayLiteral elements: Element...) {
        self.init(elements)
        precondition(count == elements.count, "An IdentifiedSet literal must not repeat an id.")
    }
}
