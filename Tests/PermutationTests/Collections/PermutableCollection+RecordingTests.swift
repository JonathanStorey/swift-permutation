// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection+RecordingTests.swift
// dependencies: [Collections/Arrangement.swift, Collections/PermutableCollection+Recording.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutableCollectionRecordingTests {

    @Test func emptyInitializerIsTheIdentity() {
        let identity: Permutation = Permutation()
        #expect(identity.cycle.isEmpty)
        #expect(identity.order == 1)
        #expect([3, 1, 2].applying(identity) == [3, 1, 2])
    }

    @Test func historyReplaysEveryReorderInOrder() {
        var generator: SeededGenerator = SeededGenerator(state: 5)
        let original: [Int] = Array(0..<30)
        var cards: Arrangement<Int> = Arrangement(original)
        var history: Permutation = Permutation()
        cards.sort(by: >, recording: &history)
        cards.shuffle(.riffle, using: &generator, recording: &history)
        cards.move(from: 3, to: 20, recording: &history)
        cards.move(fromOffsets: [1, 5, 9], toOffset: 0, recording: &history)
        cards.swap(0, 29, recording: &history)
        cards.reverse(recording: &history)
        cards.rotate(toStartAt: 7, recording: &history)
        cards.shuffle(recording: &history)
        let pivot: Int = cards.stablePartition(by: { $0.isMultiple(of: 3) }, recording: &history)
        #expect(pivot == 20)
        #expect(cards.prefix(20).allSatisfy { !$0.isMultiple(of: 3) })
        #expect(original.applying(history) == Array(cards))
        #expect(history == cards.permutation)
        cards.apply(history.inverted, recording: &history)
        #expect(history.cycle.isEmpty)
        #expect(cards.isInOriginalOrder)
    }

    @Test func sortingRecordsWhatTheSortDid() {
        var letters: Arrangement<String> = ["c", "a", "b"]
        var history: Permutation = Permutation()
        letters.sort(recording: &history)
        #expect(Array(letters) == ["a", "b", "c"])
        #expect(["c", "a", "b"].applying(history) == ["a", "b", "c"])
        letters.sort(recording: &history)
        #expect(["c", "a", "b"].applying(history) == ["a", "b", "c"])
    }
}
