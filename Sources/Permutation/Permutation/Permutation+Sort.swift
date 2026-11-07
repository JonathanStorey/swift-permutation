// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Sort.swift
// dependencies: [Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

extension Permutation {

    /// Creates the permutation that sorts the elements by the predicate, keeping equal elements in their original order, without changing the elements. Applying it with `applying(_:)` gives the sorted elements, and applying it to a parallel collection puts that collection in the same order.
    @inlinable public init<Elements: Sequence>(sorting elements: Elements, by areInIncreasingOrder: (Elements.Element, Elements.Element) throws -> Bool) rethrows {
        let values: [Elements.Element] = Array(elements)
        self.init(sources: try values.indices.sorted { try areInIncreasingOrder(values[$0], values[$1]) })
    }

    /// Creates the permutation that sorts the elements in ascending order, keeping equal elements in their original order, without changing the elements.
    @inlinable public init<Elements: Sequence>(sorting elements: Elements) where Elements.Element: Comparable {
        self.init(sorting: elements, by: <)
    }
}
