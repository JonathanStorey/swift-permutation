// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSet+Reorder.swift
// dependencies: [Collections/IdentifiedSet.swift, Collections/PermutableCollection.swift, Permutation/Permutation.swift]

// ReorderDifference ships with the iOS 27 and macOS 27 SDKs, whose Swift compiler is 6.4 or later.
#if canImport(SwiftUI) && compiler(>=6.4)
import SwiftUI

@available(iOS 27, macOS 27, tvOS 27, visionOS 27, watchOS 27, *)
public extension IdentifiedSet where Element.ID: Sendable {

    /// Applies a reorder from a SwiftUI `reorderContainer` by rotating offsets, never moving an element, and returns the permutation applied, whose inverse undoes it.
    ///
    /// The moved elements keep their current relative order and land just before the destination element, or at the end. Only the difference's sources and position are read, so a move between collections must also be applied to the other one.
    @inlinable @discardableResult mutating func apply<CollectionID>(_ difference: ReorderDifference<Element.ID, CollectionID>) -> Permutation {
        switch difference.destination.position {
        case .before(let destination):
            return move(ids: difference.sources, before: destination)
        case .end:
            return move(ids: difference.sources, before: nil)
        }
    }
}
#endif
