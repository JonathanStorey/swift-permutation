// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Arrangement.swift
// dependencies: [Collections/Offsets.swift, Collections/PermutableCollection.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

/// A fixed collection of elements that can only be reordered, the simplest `PermutableCollection`.
///
/// An arrangement never adds, removes or edits an element. The elements stay where they were stored, and every reorder rewrites only the order shown, so sorting, shuffling or moving costs the same however large the elements are. The elements need not be hashable or even equatable.
///
/// Because the stored order never changes, an arrangement always knows how far it has moved from it: `permutation` is everything applied since it was created, folded into one permutation, and `isInOriginalOrder` says whether the reorders have cancelled out.
///
/// A `PermutableDictionary` hands out its keys as an arrangement, so sorting or shuffling `dictionary.keys` reorders the entries.
public struct Arrangement<Element> {

    /// The elements in storage order, which reordering never changes.
    @usableFromInline var elements: [Element]

    /// The storage offset shown at each position. Only a dictionary's keys carry a hash table here, which an arrangement never reads.
    @usableFromInline var offsets: Offsets

    /// Creates an empty arrangement.
    @inlinable public init() {
        elements = []
        offsets = Offsets()
    }

    /// Creates an arrangement of the elements in the order given.
    @inlinable public init(_ elements: some Sequence<Element>) {
        self.elements = Array(elements)
        offsets = Offsets(count: self.elements.count)
    }

    /// Wraps storage and offsets that already agree, as a dictionary does for its keys.
    @inlinable init(elements: [Element], offsets: Offsets) {
        self.elements = elements
        self.offsets = offsets
    }
}

// MARK: - Collection

extension Arrangement: RandomAccessCollection {

    @inlinable public var startIndex: Int { 0 }

    @inlinable public var endIndex: Int { offsets.count }

    /// The element at the position.
    @inlinable public subscript(position: Int) -> Element {
        elements[offsets[position]]
    }

    /// Iterates the elements in order, reading storage straight through while nothing has reordered it.
    @inlinable public func makeIterator() -> Iterator {
        Iterator(elements: elements, sources: offsets.sources, isInStorageOrder: offsets.isInStorageOrder)
    }

    /// Hands over the storage itself while it is in the order shown.
    @inlinable public func withContiguousStorageIfAvailable<Result>(_ body: (UnsafeBufferPointer<Element>) throws -> Result) rethrows -> Result? {
        guard offsets.isInStorageOrder else { return nil }
        return try elements.withUnsafeBufferPointer(body)
    }

    /// An iterator over the elements in order.
    public struct Iterator: IteratorProtocol {

        @usableFromInline let elements: [Element]

        @usableFromInline let sources: [Int32]

        @usableFromInline let isInStorageOrder: Bool

        @usableFromInline var position: Int

        @inlinable init(elements: [Element], sources: [Int32], isInStorageOrder: Bool) {
            self.elements = elements
            self.sources = sources
            self.isInStorageOrder = isInStorageOrder
            position = 0
        }

        @inlinable public mutating func next() -> Element? {
            let current: Int = position
            guard current < sources.count else { return nil }
            position = current + 1
            return isInStorageOrder ? elements[current] : elements[Int(sources[current])]
        }
    }
}

// MARK: - PermutableCollection

extension Arrangement: PermutableCollection {

    /// Applies the permutation to the order alone, leaving the elements where they are.
    @inlinable public mutating func apply(_ permutation: Permutation) {
        offsets.apply(permutation)
    }

    /// Exchanges the elements at the two positions by swapping their storage offsets.
    @inlinable public mutating func swapAt(_ i: Int, _ j: Int) {
        offsets.swapAt(i, j)
    }
}

// MARK: - History

public extension Arrangement {

    /// Every reorder since the arrangement was created, folded into the one permutation that takes the original order to the order shown. For a dictionary's keys, the original order is the order the keys are stored in.
    ///
    /// Setting it shows the original elements in the new permutation's order, whatever came before, so `Permutation()` restores the original order and a saved permutation restores a saved order. The permutation must fit within the count.
    @inlinable var permutation: Permutation {
        get { Permutation(sources: offsets.sources.map { Int($0) }) }
        set {
            offsets.resetToStorageOrder()
            offsets.apply(newValue)
        }
    }

    /// Whether the elements are back in the order the arrangement was created with, in O(n) at worst.
    @inlinable var isInOriginalOrder: Bool {
        if offsets.isInStorageOrder { return true }
        return offsets.sources.indices.allSatisfy { offsets.sources[$0] == Int32(truncatingIfNeeded: $0) }
    }
}

// MARK: - Conformances

extension Arrangement: Equatable where Element: Equatable {

    /// Two arrangements are equal when they show equal elements in the same order, however their storage is laid out.
    public static func == (lhs: Arrangement, rhs: Arrangement) -> Bool {
        lhs.elementsEqual(rhs)
    }
}

extension Arrangement: Hashable where Element: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for element in self { hasher.combine(element) }
    }
}

extension Arrangement: Sendable where Element: Sendable {}

extension Arrangement.Iterator: Sendable where Element: Sendable {}

extension Arrangement: ExpressibleByArrayLiteral {

    @inlinable public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension Arrangement: CustomStringConvertible {

    public var description: String {
        Array(self).description
    }
}

extension Arrangement: Encodable where Element: Encodable {

    /// Encodes the elements as a plain array in the order shown.
    public func encode(to encoder: any Encoder) throws {
        var container: any UnkeyedEncodingContainer = encoder.unkeyedContainer()
        for element in self { try container.encode(element) }
    }
}

extension Arrangement: Decodable where Element: Decodable {

    /// Decodes a plain array of elements, which becomes the original order.
    public init(from decoder: any Decoder) throws {
        var container: any UnkeyedDecodingContainer = try decoder.unkeyedContainer()
        var elements: [Element] = []
        while !container.isAtEnd { elements.append(try container.decode(Element.self)) }
        self.init(elements)
    }
}
