// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+StrideTests.swift
// dependencies: [Collections/Arrangement.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Stride.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationStrideTests {

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
        #expect(Permutation().distance(to: order) == 24)
    }

    @Test func firstStepSwapsTheFirstTwoOffsets() {
        #expect(Permutation().advanced(by: 1).cycle == [1, 0])
        #expect(Permutation().advanced(by: 0) == Permutation())
        #expect(Permutation().advanced(by: 1).advanced(by: -1) == Permutation())
    }

    @Test func steppingThereAndBackReturnsAndDistanceAgrees() {
        var generator: SeededGenerator = SeededGenerator(state: 21)
        for count in [3, 12, 1_000] {
            let permutation: Permutation = Permutation(shuffles: count, using: &generator)
            for distance in [1, 7, 5_040, 1_000_003] {
                let later: Permutation = permutation.advanced(by: distance)
                #expect(later.advanced(by: -distance) == permutation)
                #expect(permutation < later)
                #expect(!(later < permutation))
                if count <= 12 {
                    #expect(permutation.distance(to: later) == distance)
                    #expect(later.distance(to: permutation) == -distance)
                }
            }
        }
    }

    @Test func rankMatchesStepCountFromTheIdentity() {
        var order: Permutation = Permutation()
        for rank in 0..<120 {
            #expect(Permutation().distance(to: order) == rank)
            #expect(Permutation().advanced(by: rank) == order)
            order.advance(by: 1)
        }
    }

    @Test func strideFromWalksAllOrders() {
        let orders: [Permutation] = Array(stride(from: Permutation(), to: Permutation().advanced(by: 6), by: 1))
        #expect(orders.count == 6)
        #expect(Set(orders.map { [0, 1, 2].applying($0) }).count == 6)
    }
}
