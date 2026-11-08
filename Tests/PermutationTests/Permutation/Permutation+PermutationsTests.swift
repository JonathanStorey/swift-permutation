// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+PermutationsTests.swift
// dependencies: [Permutation/Permutation+Permutations.swift, Permutation/Permutation+Rank.swift, Permutation/Permutation+Strideable.swift]

import Testing
@testable import Permutation

@Suite struct PermutationPermutationsTests {

    @Test(arguments: 0...6) func visitsEveryPermutationInRankOrder(count: Int) {
        let all: [Permutation] = Array(Permutation.permutations(count: count))
        let factorial: Int = (1...max(count, 1)).reduce(1, *)
        #expect(all.count == factorial)
        #expect(Set(all).count == factorial)
        for (rank, permutation) in all.enumerated() {
            #expect(permutation == Permutation(rank: Permutation.Rank(rank)))
            #expect(permutation.minimumCount <= count)
        }
    }

    @Test func matchesTheStride() {
        let strided: [Permutation] = Array(stride(from: Permutation(), to: Permutation(rank: 120), by: 1))
        #expect(Array(Permutation.permutations(count: 5)) == strided)
    }

    @Test func stopsEarlyOnAHugeCount() {
        let first: [Permutation] = Array(Permutation.permutations(count: 1_000).prefix(3))
        #expect(first == [Permutation(), Permutation(rank: 1), Permutation(rank: 2)])
    }
}
