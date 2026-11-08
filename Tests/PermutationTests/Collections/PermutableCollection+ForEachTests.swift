// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/PermutableCollection+ForEachTests.swift
// dependencies: [Collections/Arrangement.swift, Collections/IdentifiedSet.swift, Collections/PermutableCollection+ForEach.swift, Support/Player.swift]

import Testing
@testable import Permutation

@Suite struct PermutableCollectionForEachTests {

    @Test(arguments: 0...6) func visitsEveryOrderOnceAndRestoresTheStart(count: Int) {
        var arrangement: Arrangement<Int> = Arrangement(0..<count)
        arrangement.reverse()
        let start: [Int] = Array(arrangement)
        var seen: Set<[Int]> = []
        var visits: Int = 0
        arrangement.forEach(.permutation) { order in
            visits += 1
            seen.insert(Array(order))
        }
        let factorial: Int = (1...max(count, 1)).reduce(1, *)
        #expect(visits == factorial)
        #expect(seen.count == factorial)
        #expect(Array(arrangement) == start)
    }

    @Test func firstVisitIsTheCurrentOrder() {
        var roster: IdentifiedSet<Player> = IdentifiedSet([Player(id: 1, name: "ann"), Player(id: 2, name: "bob"), Player(id: 3, name: "cy")])
        var orders: [[Int]] = []
        roster.forEach(.permutation) { orders.append($0.map(\.id)) }
        #expect(orders.first == [1, 2, 3])
        #expect(roster.map(\.id) == [1, 2, 3])
        #expect(Set(orders).count == 6)
    }
}
