// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection+SortComparator.swift
// dependencies: [Collections/Collection+Permutation.swift, Collections/PermutableCollection.swift, Permutation/Permutation+Sort.swift, Permutation/Permutation.swift]

// Sorting with Foundation's comparators, kept in one file so the rest of the package needs no Foundation.
//
// - `SortDescriptor` and `KeyPathComparator` are both `SortComparator`s, so each overload takes either, alone or in a sequence that breaks ties in order.
// - A sequence of comparators is copied into an array once, and each comparison stops at the first comparator that is not `.orderedSame`.
// - A MutableCollection keeps Foundation's in-place `sort(using:)`, which builds no permutation, as it keeps the standard library's `sort(by:)`.

import Foundation

public extension PermutableCollection {

    /// Sorts the elements in place by the comparator, keeping equal elements in their original order, and returns the permutation applied.
    @inlinable @discardableResult mutating func sort<Comparator: SortComparator>(using comparator: Comparator) -> Permutation where Comparator.Compared == Element {
        sort { comparator.compare($0, $1) == .orderedAscending }
    }

    /// Sorts the elements in place by the comparators, each breaking the ties of the ones before it, and returns the permutation applied.
    @inlinable @discardableResult mutating func sort<Comparators: Sequence>(using comparators: Comparators) -> Permutation where Comparators.Element: SortComparator, Comparators.Element.Compared == Element {
        let comparators: [Comparators.Element] = Array(comparators)
        return sort { isOrderedAscending($0, $1, by: comparators) }
    }
}

public extension PermutableCollection where Self: MutableCollection & RandomAccessCollection {

    /// Sorts the elements in place by the comparator as Foundation does for a `MutableCollection`, building no permutation. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort<Comparator: SortComparator>(using comparator: Comparator) where Comparator.Compared == Element {
        standardSort(&self) { comparator.compare($0, $1) == .orderedAscending }
    }

    /// Sorts the elements in place by the comparators as Foundation does for a `MutableCollection`, building no permutation. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort<Comparators: Sequence>(using comparators: Comparators) where Comparators.Element: SortComparator, Comparators.Element.Compared == Element {
        let comparators: [Comparators.Element] = Array(comparators)
        standardSort(&self) { isOrderedAscending($0, $1, by: comparators) }
    }
}

public extension Permutation {

    /// Creates the permutation that sorts the elements by the comparator, keeping equal elements in their original order, without changing the elements.
    @inlinable init<Elements: Sequence, Comparator: SortComparator>(sorting elements: Elements, using comparator: Comparator) where Comparator.Compared == Elements.Element {
        self.init(sorting: elements) { comparator.compare($0, $1) == .orderedAscending }
    }

    /// Creates the permutation that sorts the elements by the comparators, each breaking the ties of the ones before it, without changing the elements.
    @inlinable init<Elements: Sequence, Comparators: Sequence>(sorting elements: Elements, using comparators: Comparators) where Comparators.Element: SortComparator, Comparators.Element.Compared == Elements.Element {
        let comparators: [Comparators.Element] = Array(comparators)
        self.init(sorting: elements) { isOrderedAscending($0, $1, by: comparators) }
    }
}

/// Whether the first comparator that tells the two elements apart puts the first one ahead.
@inlinable func isOrderedAscending<Comparator: SortComparator>(_ lhs: Comparator.Compared, _ rhs: Comparator.Compared, by comparators: [Comparator]) -> Bool {
    for comparator in comparators {
        switch comparator.compare(lhs, rhs) {
        case .orderedAscending: return true
        case .orderedDescending: return false
        case .orderedSame: continue
        }
    }
    return false
}
