// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/IdentifiedSetTests.swift
// dependencies: [Collections/IdentifiedSet+Codable.swift, Collections/IdentifiedSet+Uniquing.swift, Collections/IdentifiedSet.swift, Collections/Offsets.swift, Collections/PermutableCollection.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation.swift, Support/Deck.swift, Support/Player.swift, Support/SeededGenerator.swift]

import Foundation
import Testing
@testable import Permutation

@Suite struct IdentifiedSetTests {

    let ann: Player = Player(id: 1, name: "Ann")
    let bob: Player = Player(id: 2, name: "Bob")
    let cy: Player = Player(id: 3, name: "Cy")

    /// Checks that every id finds its element and its position, so the three stores agree.
    func expectConsistent(_ set: IdentifiedSet<Player>) {
        #expect(set.elements.count == set.count)
        #expect(set.offsets.count == set.count)
        #expect(set.offsets.sorted() == Array(set.elements.indices))
        #expect(set.offsets.table.count { $0 >= 0 } == set.count)
        for (position, player) in set.enumerated() {
            #expect(set[id: player.id] == player)
            #expect(set.firstIndex(id: player.id) == position)
        }
    }

    // MARK: Adding

    @Test func appendRejectsADuplicateID() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann, bob])
        let added: Bool = set.append(Player(id: 1, name: "Other"))
        #expect(!added)
        #expect(Array(set) == [ann, bob])
    }

    @Test func insertPlacesTheElementAtThePosition() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann, cy])
        let added: Bool = set.insert(bob, at: 1)
        #expect(added)
        #expect(Array(set) == [ann, bob, cy])
        expectConsistent(set)
    }

    @Test func initKeepsTheFirstElementWithEachID() {
        let set: IdentifiedSet<Player> = IdentifiedSet([ann, bob, Player(id: 1, name: "Later")])
        #expect(Array(set) == [ann, bob])
    }

    @Test func initCanKeepTheLastElementAtTheFirstPosition() {
        let later: Player = Player(id: 1, name: "Later")
        let set: IdentifiedSet<Player> = IdentifiedSet([ann, bob, later, cy], uniquingIDsWith: .keepLast)
        #expect(Array(set) == [later, bob, cy])
        expectConsistent(set)
    }

    @Test func initCombinesElementsThatShareAnID() {
        let players: [Player] = [ann, bob, Player(id: 1, name: "Annie"), Player(id: 2, name: "Rob"), Player(id: 1, name: "Anna")]
        let set: IdentifiedSet<Player> = IdentifiedSet(players, uniquingIDsWith: .combine { kept, later in
            Player(id: kept.id, name: kept.name + "+" + later.name)
        })
        #expect(set.map(\.name) == ["Ann+Annie+Anna", "Bob+Rob"])
        expectConsistent(set)
    }

    @Test func initKeepingFirstExplicitlyMatchesTheDefault() {
        let players: [Player] = [cy, ann, Player(id: 3, name: "Later"), bob]
        #expect(IdentifiedSet(players, uniquingIDsWith: .keepFirst) == IdentifiedSet(players))
    }

    @Test func arrayLiteralBuildsASet() {
        let set: IdentifiedSet<Player> = [cy, ann, bob]
        #expect(Array(set) == [cy, ann, bob])
        expectConsistent(set)
    }

    @Test func appendContentsOfAddsTheWholeBatch() {
        var set: IdentifiedSet<Player> = [ann]
        #expect(set.append(contentsOf: [bob, cy]))
        #expect(Array(set) == [ann, bob, cy])
        expectConsistent(set)
    }

    @Test func appendContentsOfAddsNothingWhenAnIDIsPresent() {
        var set: IdentifiedSet<Player> = [ann, bob]
        #expect(!set.append(contentsOf: [cy, Player(id: 2, name: "Rob")]))
        #expect(Array(set) == [ann, bob])
        expectConsistent(set)
    }

    @Test func appendContentsOfAddsNothingWhenTheBatchRepeatsAnID() {
        var set: IdentifiedSet<Player> = [ann]
        #expect(!set.append(contentsOf: [bob, cy, Player(id: 3, name: "Again")]))
        #expect(Array(set) == [ann])
        expectConsistent(set)
    }

    @Test func insertContentsOfPlacesTheBlockAtThePosition() {
        var set: IdentifiedSet<Player> = [ann, bob]
        let dee: Player = Player(id: 4, name: "Dee")
        #expect(set.insert(contentsOf: [cy, dee], at: 1))
        #expect(Array(set) == [ann, cy, dee, bob])
        expectConsistent(set)
        #expect(set.insert(contentsOf: [Player](), at: 0))
        #expect(Array(set) == [ann, cy, dee, bob])
    }

    // MARK: Replacing

    @Test func replaceKeepsThePosition() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann, bob, cy])
        let renamed: Player = Player(id: 2, name: "Robert")
        let old: Player? = set.replace(renamed)
        #expect(old == bob)
        #expect(Array(set) == [ann, renamed, cy])
    }

    @Test func replaceOfAnAbsentIDChangesNothing() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann])
        let old: Player? = set.replace(bob)
        #expect(old == nil)
        #expect(Array(set) == [ann])
    }

    @Test func replaceAtPositionCanChangeTheID() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann, bob])
        let old: Player = set.replace(at: 1, with: cy)
        #expect(old == bob)
        #expect(Array(set) == [ann, cy])
        #expect(!set.contains(id: 2))
        expectConsistent(set)
    }

    // MARK: Updating

    @Test func updateOrAppendReplacesOrAppends() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann, bob])
        let renamed: Player = Player(id: 1, name: "Anna")
        let replaced: Player? = set.update(orAppend: renamed)
        #expect(replaced == ann)
        let appended: Player? = set.update(orAppend: cy)
        #expect(appended == nil)
        #expect(Array(set) == [renamed, bob, cy])
    }

    @Test func updateOrInsertKeepsAnExistingElementsPosition() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann, bob])
        let renamed: Player = Player(id: 2, name: "Robert")
        let replaced: Player? = set.update(orInsert: renamed, at: 0)
        #expect(replaced == bob)
        let inserted: Player? = set.update(orInsert: cy, at: 0)
        #expect(inserted == nil)
        #expect(Array(set) == [cy, ann, renamed])
    }

    @Test func subscriptByIDSetsAndRemoves() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann])
        set[id: 2] = bob
        set[id: 1]?.name = "Anna"
        #expect(Array(set) == [Player(id: 1, name: "Anna"), bob])
        set[id: 1] = nil
        #expect(Array(set) == [bob])
        expectConsistent(set)
    }

    @Test func batchUpdateReplacesInPlaceAndAppendsTheRest() {
        var set: IdentifiedSet<Player> = [ann, bob]
        let rob: Player = Player(id: 2, name: "Rob")
        let dee: Player = Player(id: 4, name: "Dee")
        let deeLater: Player = Player(id: 4, name: "Dee Later")
        set.update(orAppend: [rob, dee, cy, deeLater])
        #expect(Array(set) == [ann, rob, deeLater, cy])
        expectConsistent(set)
    }

    @Test func batchUpdateInsertsNewElementsAsABlock() {
        var set: IdentifiedSet<Player> = [ann, bob]
        let annie: Player = Player(id: 1, name: "Annie")
        let dee: Player = Player(id: 4, name: "Dee")
        set.update(orInsert: [dee, annie, cy], at: 1)
        #expect(Array(set) == [annie, dee, cy, bob])
        expectConsistent(set)
    }

    // MARK: Removing

    @Test func removeFillsTheGapAndKeepsLookupsConsistent() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann, bob, cy])
        set.reverse()
        let removed: Player? = set.remove(id: 3)
        #expect(removed == cy)
        let missing: Player? = set.remove(id: 3)
        #expect(missing == nil)
        #expect(Array(set) == [bob, ann])
        expectConsistent(set)
        let first: Player = set.remove(at: 0)
        #expect(first == bob)
        #expect(Array(set) == [ann])
        expectConsistent(set)
    }

    @Test func removeAllWhereKeepsTheRestInOrder() {
        var set: IdentifiedSet<Player> = IdentifiedSet((0..<10).map { Player(id: $0, name: String($0)) })
        set.reverse()
        set.removeAll { $0.id.isMultiple(of: 2) }
        #expect(set.map(\.id) == [9, 7, 5, 3, 1])
        expectConsistent(set)
    }

    @Test func removeAtOffsetsRemovesThosePositions() {
        var set: IdentifiedSet<Player> = [ann, bob, cy, Player(id: 4, name: "Dee")]
        set.remove(atOffsets: [3, 1])
        #expect(Array(set) == [ann, cy])
        expectConsistent(set)
        set.remove(atOffsets: [Int]())
        #expect(Array(set) == [ann, cy])
    }

    @Test func filterKeepsAnIdentifiedSet() {
        let set: IdentifiedSet<Player> = [ann, bob, cy]
        let kept: IdentifiedSet<Player> = set.filter { $0.id != 2 }
        #expect(Array(kept) == [ann, cy])
        #expect(kept.contains(id: 3) && !kept.contains(id: 2))
        expectConsistent(kept)
        #expect(Array(set) == [ann, bob, cy])
    }

    @Test func idsFollowTheOrder() {
        var set: IdentifiedSet<Player> = [ann, bob, cy]
        set.reverse()
        #expect(Array(set.ids) == [3, 2, 1])
    }

    @Test func reserveCapacityKeepsContentsAndIndex() {
        var set: IdentifiedSet<Player> = [ann, bob]
        set.reserveCapacity(1_000)
        #expect(set.offsets.table.count >= 1_334)
        let table: Int = set.offsets.table.count
        for id in 10..<900 { set.append(Player(id: id, name: "P\(id)")) }
        #expect(set.offsets.table.count == table)
        #expect(set.count == 892)
        expectConsistent(set)
    }

    // MARK: Reordering

    @Test func applyMatchesTheSwapBasedDefault() {
        var generator: SeededGenerator = SeededGenerator(state: 3)
        for count in 0..<40 {
            let players: [Player] = (0..<count).map { Player(id: $0, name: String($0)) }
            let permutation: Permutation = Permutation(shuffles: count, using: &generator)
            var set: IdentifiedSet<Player> = IdentifiedSet(players)
            set.apply(permutation)
            var deck: Deck = Deck(cards: players.map(\.name))
            deck.apply(permutation)
            #expect(set.map(\.name) == deck.cards)
            expectConsistent(set)
        }
    }

    @Test func reordersLeaveStorageInPlace() {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann, bob, cy])
        let storage: [Player] = set.elements
        let table: [Int32] = set.offsets.table
        set.sort { $0.name > $1.name }
        #expect(Array(set) == [cy, bob, ann])
        #expect(set.elements == storage)
        #expect(set.offsets.table == table)
    }

    @Test func reorderingAndUndoingRestoresTheOrder() {
        var set: IdentifiedSet<Player> = IdentifiedSet((0..<20).map { Player(id: $0, name: String($0)) })
        let original: [Player] = Array(set)
        let change: Permutation = set.shuffle()
        set.apply(change.inverted)
        #expect(Array(set) == original)
    }

    // MARK: Randomized

    @Test func randomEditsMatchAPlainArray() {
        var generator: SeededGenerator = SeededGenerator(state: 42)
        var set: IdentifiedSet<Player> = IdentifiedSet()
        var model: [Player] = []
        for step in 0..<2_000 {
            let id: Int = Int.random(in: 0..<30, using: &generator)
            let player: Player = Player(id: id, name: "\(id)-\(step)")
            let position: Int = Int.random(in: 0...model.count, using: &generator)
            switch Int.random(in: 0..<6, using: &generator) {
            case 0:
                let added: Bool = set.insert(player, at: position)
                #expect(added == !model.contains { $0.id == id })
                if added { model.insert(player, at: position) }
            case 1:
                let old: Player? = set.update(orAppend: player)
                if let index: Int = model.firstIndex(where: { $0.id == id }) {
                    #expect(old == model[index])
                    model[index] = player
                } else {
                    #expect(old == nil)
                    model.append(player)
                }
            case 2:
                let removed: Player? = set.remove(id: id)
                #expect(removed == model.first { $0.id == id })
                model.removeAll { $0.id == id }
            case 3:
                guard !model.isEmpty else { continue }
                let index: Int = Int.random(in: 0..<model.count, using: &generator)
                let removed: Player = set.remove(at: index)
                #expect(removed == model.remove(at: index))
            case 4:
                let permutation: Permutation = set.shuffle(using: &generator)
                var deck: Deck = Deck(cards: model.map(\.name))
                deck.apply(permutation)
                model = deck.cards.map { name in model.first { $0.name == name }! }
            default:
                guard !model.isEmpty else { continue }
                let from: Int = Int.random(in: 0..<model.count, using: &generator)
                let to: Int = Int.random(in: 0..<model.count, using: &generator)
                set.move(from: from, to: to)
                model.insert(model.remove(at: from), at: to)
            }
            #expect(Array(set) == model)
        }
        expectConsistent(set)
    }

    // MARK: Conformances

    @Test func equalityIgnoresStorageLayout() {
        var shuffled: IdentifiedSet<Player> = IdentifiedSet([cy, bob, ann])
        shuffled.reverse()
        #expect(shuffled == IdentifiedSet([ann, bob, cy]))
        #expect(shuffled != IdentifiedSet([cy, bob, ann]))
        #expect(shuffled.hashValue == IdentifiedSet([ann, bob, cy]).hashValue)
    }

    @Test func codableRoundTripsAsAPlainArray() throws {
        var set: IdentifiedSet<Player> = IdentifiedSet([ann, bob, cy])
        set.rotate(toStartAt: 1)
        let data: Data = try JSONEncoder().encode(set)
        #expect(try JSONDecoder().decode([Player].self, from: data) == [bob, cy, ann])
        #expect(try JSONDecoder().decode(IdentifiedSet<Player>.self, from: data) == set)
    }

    @Test func decodingADuplicateIDThrows() throws {
        let data: Data = try JSONEncoder().encode([ann, Player(id: 1, name: "Again")])
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(IdentifiedSet<Player>.self, from: data)
        }
    }
}
