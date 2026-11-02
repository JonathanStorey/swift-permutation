// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSet+Binding.swift
// dependencies: [Collections/IdentifiedSet.swift]

#if canImport(SwiftUI)
import SwiftUI

public extension Binding {

    /// A binding to the element with the id, or nil when there is none, which follows the element by id through reorders and keeps its last value if the element is removed.
    subscript<Element: Identifiable>(id id: Element.ID) -> Binding<Element>? where Value == IdentifiedSet<Element> {
        guard let current: Element = wrappedValue[id: id] else { return nil }
        return self[dynamicMember: \.[binding: id, fallback: BindingFallback(value: current)]]
    }

    /// A binding to each element in order, for use with `ForEach`.
    func elements<Element: Identifiable>() -> [Binding<Element>] where Value == IdentifiedSet<Element> {
        wrappedValue.map { self[id: $0.id]! }
    }
}

extension IdentifiedSet {

    /// The element with the id, or the fallback once it is gone, written back by id, which lets a binding reach it through a key path instead of capturing closures.
    subscript(binding id: Element.ID, fallback fallback: BindingFallback<Element>) -> Element {
        get {
            self[id: id] ?? fallback.value
        }
        set {
            precondition(newValue.id == id, "An element edited through a binding must keep its id.")
            replace(newValue)
        }
    }
}

/// A value carried in a key path for reading only, so it never affects the key path's equality or hash.
struct BindingFallback<Value>: Hashable {

    let value: Value

    static func == (lhs: BindingFallback, rhs: BindingFallback) -> Bool {
        true
    }

    func hash(into hasher: inout Hasher) {}
}
#endif
