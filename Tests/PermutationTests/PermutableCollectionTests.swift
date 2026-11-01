// repository: https://github.com/JonathanStorey/swift-permutation
// path: PermutableCollectionTests.swift
// dependencies: [PermutableCollection.swift, Permutation+Shuffleable.swift, Permutation.swift]

import Testing
@testable import Permutation

@Suite struct PermutableCollectionTests {

    @Test func moveFromOffsetsToEndKeepsRelativeOrder() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        deck.move(fromOffsets: [3, 1], toOffset: 5)
        #expect(deck.cards == ["a", "c", "e", "b", "d"])
    }

    @Test func moveFromOffsetsToFrontKeepsRelativeOrder() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        deck.move(fromOffsets: 2...4, toOffset: 0)
        #expect(deck.cards == ["c", "d", "e", "a", "b"])
    }

    @Test func moveFromOffsetsToOwnPositionReturnsEmptyPermutation() {
        var deck: Deck = Deck(cards: ["a", "b", "c"])
        #expect(deck.move(fromOffsets: [1], toOffset: 2).cycle.isEmpty)
        #expect(deck.cards == ["a", "b", "c"])
    }

    @Test func moveLandsElementAtLaterDestination() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        deck.move(from: 1, to: 3)
        #expect(deck.cards == ["a", "c", "d", "b", "e"])
    }

    @Test func moveToEarlierIndexShiftsOthersBack() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        deck.move(from: 3, to: 0)
        #expect(deck.cards == ["d", "a", "b", "c", "e"])
    }

    @Test func moveToSameIndexReturnsEmptyPermutation() {
        var deck: Deck = Deck(cards: ["a", "b", "c"])
        #expect(deck.move(from: 1, to: 1).cycle.isEmpty)
    }

    @Test func partitionIsStableAndReturnsFirstMovedIndex() {
        var deck: Deck = Deck(cards: (0..<7).map(String.init))
        let pivot: Int = deck.partition { Int($0)! % 2 == 1 }
        #expect(deck.cards == ["0", "2", "4", "6", "1", "3", "5"])
        #expect(pivot == 4)
    }

    @Test func partitionWithNoMatchesReturnsEndIndex() {
        var deck: Deck = Deck(cards: ["a", "b", "c"])
        let pivot: Int = deck.partition { $0 == "z" }
        #expect(deck.cards == ["a", "b", "c"])
        #expect(pivot == deck.endIndex)
    }

    @Test func permuteLeavesOffsetsBeyondTheCycleInPlace() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e", "f"])
        deck.permute(using: Permutation(shuffles: 3))
        #expect(deck.cards[3...] == ["d", "e", "f"])
        #expect(deck.cards[..<3].sorted() == ["a", "b", "c"])
    }

    @Test func permuteOnRandomAccessCollectionMatchesPlainCollection() {
        let original: [String] = (0..<25).map(String.init)
        var deck: Deck = Deck(cards: original)
        var hand: Hand = Hand(cards: original)
        hand.permute(using: deck.shuffle())
        #expect(hand.cards == deck.cards)
    }

    @Test func reverseLeavesMiddleElementInPlace() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        let permutation: Permutation = deck.reverse()
        #expect(deck.cards == ["e", "d", "c", "b", "a"])
        #expect(!permutation.cycle.contains(2))
    }

    @Test func reverseOfEmptyCollectionReturnsEmptyPermutation() {
        var deck: Deck = Deck(cards: [])
        #expect(deck.reverse().cycle.isEmpty)
    }

    @Test func reverseOfEvenCountSwapsEveryPair() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d"])
        let permutation: Permutation = deck.reverse()
        #expect(deck.cards == ["d", "c", "b", "a"])
        #expect(permutation.cycle == [2, 1, 3, 0])
    }

    @Test func rotateMovesIndexToFront() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e"])
        deck.rotate(toStartAt: 2)
        #expect(deck.cards == ["c", "d", "e", "a", "b"])
    }

    @Test func rotateSharingFactorWithCountUndoesWithInverted() {
        var deck: Deck = Deck(cards: ["a", "b", "c", "d", "e", "f"])
        let permutation: Permutation = deck.rotate(toStartAt: 2)
        #expect(deck.cards == ["c", "d", "e", "f", "a", "b"])
        deck.permute(using: permutation.inverted)
        #expect(deck.cards == ["a", "b", "c", "d", "e", "f"])
    }

    @Test func rotateToStartIndexLeavesOrder() {
        var deck: Deck = Deck(cards: ["a", "b", "c"])
        #expect(deck.rotate(toStartAt: deck.startIndex).cycle.isEmpty)
        #expect(deck.cards == ["a", "b", "c"])
    }

    @Test func shuffleKeepsEveryElement() {
        var deck: Deck = Deck(cards: (0..<20).map(String.init))
        deck.shuffle()
        #expect(deck.cards.sorted() == (0..<20).map(String.init).sorted())
    }

    @Test func shuffleUsingGeneratorMatchesArray() {
        var deckGenerator: SeededGenerator = SeededGenerator(state: 99)
        var arrayGenerator: SeededGenerator = SeededGenerator(state: 99)
        var deck: Deck = Deck(cards: (0..<30).map(String.init))
        var array: [String] = (0..<30).map(String.init)
        deck.shuffle(using: &deckGenerator)
        array.shuffle(using: &arrayGenerator)
        #expect(deck.cards == array)
        #expect(deckGenerator.state == arrayGenerator.state)
    }

    @Test func shuffleUsingGeneratorOnSingleElementLeavesItInPlace() {
        var generator: SeededGenerator = SeededGenerator(state: 3)
        var deck: Deck = Deck(cards: ["a"])
        deck.shuffle(using: &generator)
        #expect(deck.cards == ["a"])
    }

    @Test func sortByOrdersDescending() {
        var deck: Deck = Deck(cards: ["b", "d", "a", "c"])
        deck.sort(by: >)
        #expect(deck.cards == ["d", "c", "b", "a"])
    }

    @Test func sortOfSortedCollectionReturnsEmptyPermutation() {
        var deck: Deck = Deck(cards: ["a", "b", "c"])
        #expect(deck.sort().cycle.isEmpty)
    }

    @Test func sortOrdersAscending() {
        var deck: Deck = Deck(cards: ["d", "b", "e", "a", "c"])
        deck.sort()
        #expect(deck.cards == ["a", "b", "c", "d", "e"])
    }
}
