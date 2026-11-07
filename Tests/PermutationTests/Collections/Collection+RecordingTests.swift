// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Collection+RecordingTests.swift
// dependencies: [Collections/Arrangement.swift, Collections/Collection+Recording.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct CollectionRecordingTests {

    @Test func emptyInitializerIsTheIdentity() {
        let identity: Permutation = Permutation()
        #expect(identity.cycle.isEmpty)
        #expect(identity.order == 1)
        #expect([3, 1, 2].applying(identity) == [3, 1, 2])
    }

    @Test func sortedRecordsTheSortAndLeavesTheOriginal() {
        let scores: [Int] = [40, 10, 30, 10, 20]
        let names: [String] = ["ann", "bob", "cy", "dee", "eli"]
        var order: Permutation = Permutation()
        let ranked: [Int] = scores.sorted(recording: &order)
        #expect(ranked == [10, 10, 20, 30, 40])
        #expect(scores == [40, 10, 30, 10, 20])
        #expect(scores.applying(order) == ranked)
        #expect(names.applying(order) == ["bob", "dee", "eli", "cy", "ann"])
        var descending: Permutation = Permutation()
        #expect(scores.sorted(by: >, recording: &descending) == [40, 30, 20, 10, 10])
        #expect(scores.applying(descending) == [40, 30, 20, 10, 10])
    }

    @Test func shuffledAndReversedRecordWhatTheyDid() {
        var generator: SeededGenerator = SeededGenerator(state: 3)
        let letters: [Character] = Array("permutation")
        var shuffle: Permutation = Permutation()
        let mixed: [Character] = letters.shuffled(.riffle, using: &generator, recording: &shuffle)
        #expect(letters.applying(shuffle) == mixed)
        var reversal: Permutation = Permutation()
        #expect(letters.reversed(recording: &reversal) == Array(letters.reversed()))
        #expect(letters.applying(reversal) == Array(letters.reversed()))
        var random: Permutation = Permutation()
        let randomized: [Character] = letters.shuffled(recording: &random)
        #expect(letters.applying(random) == randomized)
    }

    @Test func recordingAppendsToEarlierReorders() {
        let original: [Int] = [5, 3, 9, 1]
        var history: Permutation = Permutation()
        let sorted: [Int] = original.sorted(recording: &history)
        let reversed: [Int] = sorted.reversed(recording: &history)
        #expect(reversed == [9, 5, 3, 1])
        #expect(original.applying(history) == reversed)
    }

    @Test func permutableCollectionsKeepTheirOwnType() {
        let cards: Arrangement<Int> = Arrangement([3, 1, 2])
        var order: Permutation = Permutation()
        let sorted: Arrangement<Int> = cards.sorted(recording: &order)
        #expect(Array(sorted) == [1, 2, 3])
        #expect(Array(cards) == [3, 1, 2])
        #expect(sorted.permutation == order)
        var flipped: Permutation = Permutation()
        let reversed: Arrangement<Int> = cards.reversed(recording: &flipped)
        #expect(Array(reversed) == [2, 1, 3])
        #expect(reversed.permutation == flipped)
    }
}
