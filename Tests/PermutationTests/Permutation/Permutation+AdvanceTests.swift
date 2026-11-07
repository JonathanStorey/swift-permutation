// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+AdvanceTests.swift
// dependencies: [Collections/Arrangement.swift, Permutation/Permutation+Advance.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationAdvanceTests {

    @Test func steppingFromTheIdentityVisitsEveryOrderOfNBeforeMovingPastIt() {
        var hand: Arrangement<Int> = Arrangement(0..<5)
        var order: Permutation = Permutation()
        var seen: Set<[Int]> = []
        for _ in 0..<24 {
            #expect(order.minimumCount <= 4)
            hand.permutation = order
            seen.insert(Array(hand))
            order.advance(by: 1)
        }
        #expect(seen.count == 24)
        #expect(order.minimumCount == 5)
        #expect(Permutation().advanced(by: 24) == order)
    }

    @Test func firstStepSwapsTheFirstTwoOffsets() {
        #expect(Permutation().advanced(by: 1).cycle == [1, 0])
        #expect(Permutation().advanced(by: 0) == Permutation())
        #expect(Permutation().advanced(by: 1).advanced(by: -1) == Permutation())
    }

    @Test func threeElementsStepInTheDocumentedOrder() {
        var order: Permutation = Permutation()
        var words: [[Int]] = []
        for _ in 0..<6 {
            words.append(order.foataWord(count: 3))
            order.advance(by: 1)
        }
        #expect(words == [[0, 1, 2], [1, 0, 2], [0, 2, 1], [2, 0, 1], [1, 2, 0], [2, 1, 0]])
        #expect(order.foataWord(count: 4) == [0, 1, 3, 2])
    }

    @Test func steppingThereAndBackReturns() {
        var generator: SeededGenerator = SeededGenerator(state: 21)
        for count in [2, 5, 12, 300] {
            for _ in 0..<10 {
                let permutation: Permutation = Permutation(shuffles: count, using: &generator)
                #expect(Permutation(foataWord: permutation.foataWord(count: count)) == permutation)
                for distance in [1, 7, 130] {
                    let later: Permutation = permutation.advanced(by: distance)
                    #expect(later.advanced(by: -distance) == permutation)
                }
                #expect(permutation.advanced(by: 3).advanced(by: -2) == permutation.advanced(by: 1))
            }
        }
    }

    @Test func eachOrderOfFourAppearsOnceBeforeRepeating() {
        let orders: [Permutation] = (0..<24).map { Permutation().advanced(by: $0) }
        #expect(Set(orders).count == 24)
        #expect(Set(orders.map { [0, 1, 2, 3].applying($0) }).count == 24)
    }
}
