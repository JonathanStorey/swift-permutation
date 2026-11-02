// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSet+BindingTests.swift
// dependencies: [Collections/IdentifiedSet+Binding.swift, Collections/IdentifiedSet.swift, Collections/PermutableCollection.swift, Support/Player.swift]

#if canImport(SwiftUI)
import SwiftUI
import Testing
@testable import Permutation

@Suite struct IdentifiedSetBindingTests {

    /// Holds the set the way a view's state would, so a binding can read and write it.
    final class Store: @unchecked Sendable {

        var players: IdentifiedSet<Player> = IdentifiedSet([
            Player(id: 1, name: "Ann"),
            Player(id: 2, name: "Bob"),
            Player(id: 3, name: "Cy"),
        ])

        var binding: Binding<IdentifiedSet<Player>> {
            Binding(get: { self.players }, set: { self.players = $0 })
        }
    }

    @Test func bindingByIDEditsTheElement() {
        let store: Store = Store()
        store.binding[id: 2]?.wrappedValue.name = "Robert"
        #expect(store.players.map(\.name) == ["Ann", "Robert", "Cy"])
    }

    @Test func bindingByIDIsNilForAnAbsentID() {
        #expect(Store().binding[id: 9] == nil)
    }

    @Test func bindingFollowsTheElementThroughAReorder() {
        let store: Store = Store()
        let bob: Binding<Player> = store.binding[id: 2]!
        store.players.reverse()
        bob.wrappedValue.name = "Robert"
        #expect(store.players.map(\.name) == ["Cy", "Robert", "Ann"])
    }

    @Test func bindingKeepsItsLastValueAfterRemoval() {
        let store: Store = Store()
        let bob: Binding<Player> = store.binding[id: 2]!
        store.players.remove(id: 2)
        #expect(bob.wrappedValue.name == "Bob")
    }

    @Test func elementsGivesOneBindingPerElementInOrder() {
        let store: Store = Store()
        let bindings: [Binding<Player>] = store.binding.elements()
        #expect(bindings.map(\.id) == [1, 2, 3])
        bindings[0].wrappedValue.name = "Anna"
        #expect(store.players[0].name == "Anna")
    }
}
#endif
