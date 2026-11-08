// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Arrangement+PermutationsTests.swift
// dependencies: [Collections/Arrangement.swift, Collections/Arrangement+Permutations.swift, Permutation/Permutation+Rank.swift]

import Testing
@testable import Permutation

@Suite struct ArrangementPermutationsTests {

    @Test(arguments: 0...6) func visitsEveryOrderOnceAndLeavesTheArrangementAlone(count: Int) {
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

    @Test func ordersFollowTheRank() {
        var arrangement: Arrangement<String> = ["a", "b", "c", "d"]
        arrangement.reverse()
        for (rank, order) in arrangement.permutations.enumerated() {
            #expect(order.permutation == Permutation(rank: Permutation.Rank(rank)))
        }
        #expect(arrangement.permutations.first { _ in true }?.isInOriginalOrder == true)
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
