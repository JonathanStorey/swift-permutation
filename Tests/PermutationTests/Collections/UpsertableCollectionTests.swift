// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/UpsertableCollectionTests.swift
// dependencies: [Collections/IdentifiedSet.swift, Collections/UpsertableCollection.swift, Support/Player.swift, Support/Roster.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct UpsertableCollectionTests {

    let ann: Player = Player(id: 1, name: "Ann")
    let bob: Player = Player(id: 2, name: "Bob")
    let cy: Player = Player(id: 3, name: "Cy")
    let dee: Player = Player(id: 4, name: "Dee")

    @Test func appendAddsOnlyWhatIsNew() {
        var roster: Roster = Roster(players: [ann])
        let first: Bool = roster.append(bob)
        let second: Bool = roster.append(Player(id: 1, name: "Again"))
        #expect(first && !second)
        #expect(roster.players == [ann, bob])
    }

    @Test func batchInsertRollsBackOnARepeat() {
        var roster: Roster = Roster(players: [ann, bob])
        let added: Bool = roster.insert(contentsOf: [cy, dee, Player(id: 3, name: "Again")], at: 1)
        #expect(!added)
        #expect(roster.players == [ann, bob])
    }

    @Test func batchInsertRollsBackOnAnIDAlreadyPresent() {
        var roster: Roster = Roster(players: [ann, bob])
        let added: Bool = roster.append(contentsOf: [cy, Player(id: 2, name: "Rob")])
        #expect(!added)
        #expect(roster.players == [ann, bob])
    }

    @Test func batchInsertPlacesTheBlock() {
        var roster: Roster = Roster(players: [ann, bob])
        let added: Bool = roster.insert(contentsOf: [cy, dee], at: 1)
        #expect(added)
        #expect(roster.players == [ann, cy, dee, bob])
    }

    @Test func updateReplacesInPlaceOrAdds() {
        var roster: Roster = Roster(players: [ann, bob])
        let annie: Player = Player(id: 1, name: "Annie")
        let old: Player? = roster.update(orAppend: annie)
        let none: Player? = roster.update(orInsert: cy, at: 0)
        #expect(old == ann && none == nil)
        #expect(roster.players == [cy, annie, bob])
    }

    @Test func batchUpdateLetsTheLaterElementWin() {
        var roster: Roster = Roster(players: [ann, bob])
        let rob: Player = Player(id: 2, name: "Rob")
        let deeLater: Player = Player(id: 4, name: "Dee Later")
        roster.update(orInsert: [rob, dee, cy, deeLater], at: 1)
        #expect(roster.players == [ann, deeLater, cy, rob])
    }

    @Test func removalsByPositionAndPredicate() {
        var roster: Roster = Roster(players: [ann, bob, cy, dee])
        roster.remove(atOffsets: [3, 1, 3])
        #expect(roster.players == [ann, cy])
        roster.removeAll { $0.id == 1 }
        #expect(roster.players == [cy])
    }

    /// IdentifiedSet overrides most defaults with faster versions, so random edits must leave it matching the default-only Roster.
    @Test func identifiedSetMatchesTheDefaults() {
        var generator: SeededGenerator = SeededGenerator(state: 42)
        var set: IdentifiedSet<Player> = []
        var roster: Roster = Roster(players: [])
        func player() -> Player {
            let id: Int = Int.random(in: 0..<30, using: &generator)
            return Player(id: id, name: "P\(id)-\(Int.random(in: 0..<5, using: &generator))")
        }
        for _ in 0..<1_500 {
            let index: Int = Int.random(in: 0...set.count, using: &generator)
            let batch: [Player] = (0..<Int.random(in: 0..<4, using: &generator)).map { _ in player() }
            switch Int.random(in: 0..<9, using: &generator) {
            case 0:
                let element: Player = player()
                let fromSet: Bool = set.insert(element, at: index)
                let fromRoster: Bool = roster.insert(element, at: index)
                #expect(fromSet == fromRoster)
            case 1:
                let element: Player = player()
                let fromSet: Player? = set.replace(element)
                let fromRoster: Player? = roster.replace(element)
                #expect(fromSet == fromRoster)
            case 2:
                let element: Player = player()
                let fromSet: Player? = set.update(orInsert: element, at: index)
                let fromRoster: Player? = roster.update(orInsert: element, at: index)
                #expect(fromSet == fromRoster)
            case 3:
                let fromSet: Bool = set.insert(contentsOf: batch, at: index)
                let fromRoster: Bool = roster.insert(contentsOf: batch, at: index)
                #expect(fromSet == fromRoster)
            case 4:
                set.update(orInsert: batch, at: index)
                roster.update(orInsert: batch, at: index)
            case 5:
                set.update(orAppend: batch)
                roster.update(orAppend: batch)
            case 6 where !set.isEmpty:
                let position: Int = Int.random(in: 0..<set.count, using: &generator)
                let fromSet: Player = set.remove(at: position)
                let fromRoster: Player = roster.remove(at: position)
                #expect(fromSet == fromRoster)
            case 7 where !set.isEmpty:
                let positions: [Int] = (0..<2).map { _ in Int.random(in: 0..<set.count, using: &generator) }
                set.remove(atOffsets: positions)
                roster.remove(atOffsets: positions)
            default:
                let cut: Int = Int.random(in: 0..<30, using: &generator)
                set.removeAll { $0.id > cut && $0.id % 3 == 0 }
                roster.removeAll { $0.id > cut && $0.id % 3 == 0 }
            }
            #expect(Array(set) == roster.players)
        }
    }
}
