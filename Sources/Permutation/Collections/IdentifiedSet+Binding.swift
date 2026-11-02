// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSet+Binding.swift
// dependencies: [Collections/IdentifiedSet.swift]

#if canImport(SwiftUI)
import SwiftUI

public extension Binding {

    /// A binding to the element with the id, or nil when there is none, which follows the element by id through reorders and keeps its last value if the element is removed.
    subscript<Element: Identifiable>(id id: Element.ID) -> Binding<Element>? where Value == IdentifiedSet<Element> {
        guard let current: Element = wrappedValue[id: id] else { return nil }
        return Binding<Element>(
            get: { wrappedValue[id: id] ?? current },
            set: { newValue in
                precondition(newValue.id == id, "An element edited through a binding must keep its id.")
                wrappedValue.replace(newValue)
            }
        )
    }

    /// A binding to each element in order, for use with `ForEach`.
    func elements<Element: Identifiable>() -> [Binding<Element>] where Value == IdentifiedSet<Element> {
        wrappedValue.map { self[id: $0.id]! }
    }
}
#endif
