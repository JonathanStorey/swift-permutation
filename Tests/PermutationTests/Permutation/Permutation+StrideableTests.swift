// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+StrideableTests.swift
// dependencies: [Collections/Arrangement.swift, Permutation/Permutation+Rank.swift, Permutation/Permutation+Strideable.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationStrideableTests {

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
                    let later: Permutation = permutation.advanced(by: Permutation.Rank(distance))
                    #expect(later.advanced(by: Permutation.Rank(-distance)) == permutation)
                }
                #expect(permutation.advanced(by: 3).advanced(by: -2) == permutation.advanced(by: 1))
            }
        }
    }

    @Test func eachOrderOfFourAppearsOnceBeforeRepeating() {
        let orders: [Permutation] = (0..<24).map { Permutation().advanced(by: Permutation.Rank($0)) }
        #expect(Set(orders).count == 24)
        #expect(Set(orders.map { [0, 1, 2, 3].applying($0) }).count == 24)
    }

    @Test func longJumpsAgreeWithSteps() {
        var generator: SeededGenerator = SeededGenerator(state: 144)
        for count in [5, 12, 400] {
            let permutation: Permutation = Permutation(shuffles: count, using: &generator)
            var stepped: Permutation = permutation
            for _ in 0..<40 { stepped.advance(by: 1) }
            #expect(permutation.advanced(by: 40) == stepped)
            #expect(permutation.advanced(by: Permutation.Rank(40)) == stepped)
            #expect(stepped.advanced(by: -40) == permutation)
            #expect(permutation.distance(to: stepped) == 40)
            #expect(stepped.distance(to: permutation) == -40)
            #expect(permutation < stepped)
        }
    }

    @Test func distancesPastIntStayExact() {
        var generator: SeededGenerator = SeededGenerator(state: 233)
        let permutation: Permutation = Permutation(shuffles: 50, using: &generator)
        let jump: Permutation.Rank = Permutation.Rank(digits: Array(1...45))
        let later: Permutation = permutation.advanced(by: jump)
        #expect(permutation.distance(to: later) == jump)
        #expect(later.advanced(by: Permutation.Rank(0) - jump) == permutation)
        #expect(Int(exactly: Permutation(reversing: 30).rank) == nil)
    }

    @Test func strideWalksEveryOrder() {
        let orders: [Permutation] = Array(stride(from: Permutation(), to: Permutation(rank: 6), by: 1))
        #expect(orders.count == 6)
        #expect(Set(orders.map { [0, 1, 2].applying($0) }).count == 6)
    }
}
