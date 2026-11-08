// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection+PermutationsTests.swift
// dependencies: [Collections/Arrangement.swift, Collections/IdentifiedSet.swift, Collections/PermutableCollection+Permutations.swift, Support/Player.swift]

import Testing
@testable import Permutation

@Suite struct PermutableCollectionPermutationsTests {

    @Test(arguments: 0...6) func visitsEveryOrderOnceAndLeavesTheCollectionAlone(count: Int) {
        var arrangement: Arrangement<Int> = Arrangement(0..<count)
        arrangement.reverse()
        let start: [Int] = Array(arrangement)
        var seen: Set<[Int]> = []
        var visits: Int = 0
        for order in arrangement.permutations {
            visits += 1
            seen.insert(Array(order))
        }
        let factorial: Int = (1...max(count, 1)).reduce(1, *)
        #expect(visits == factorial)
        #expect(seen.count == factorial)
        #expect(Array(arrangement) == start)
    }

    @Test func firstOrderIsTheCurrentOne() {
        let roster: IdentifiedSet<Player> = IdentifiedSet([Player(id: 1, name: "ann"), Player(id: 2, name: "bob"), Player(id: 3, name: "cy")])
        let orders: [[Int]] = roster.permutations.map { $0.map(\.id) }
        #expect(orders.first == [1, 2, 3])
        #expect(Set(orders).count == 6)
    }

    @Test func eachOrderIsOneSwapFromTheLast() {
        let orders: [[Int]] = Arrangement(0..<5).permutations.map(Array.init)
        for (previous, next) in zip(orders, orders.dropFirst()) {
            #expect(zip(previous, next).filter { $0 != $1 }.count == 2)
        }
    }

    @Test func breakStopsAHugeWalkAtOnce() {
        var visits: Int = 0
        for order in Arrangement(0..<100).permutations {
            visits += 1
            if order.first == 1 { break }
        }
        #expect(visits == 2)
        let found: Arrangement<Int>? = Arrangement(0..<100).permutations.first { $0.first == 2 }
        #expect(found?.first == 2)
    }
}
