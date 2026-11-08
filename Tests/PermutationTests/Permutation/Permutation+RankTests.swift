// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+RankTests.swift
// dependencies: [Permutation/Permutation+Rank.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Strideable.swift, Support/SeededGenerator.swift]

import Foundation
import Testing
@testable import Permutation

@Suite struct PermutationRankTests {

    @Test func digitsCountInTheFactorialNumberSystem() {
        #expect(Permutation.Rank(0).digits.isEmpty)
        #expect(Permutation.Rank(1).digits == [1])
        #expect(Permutation.Rank(5).digits == [1, 2])
        #expect(Permutation.Rank(6).digits == [0, 0, 1])
        #expect(Permutation.Rank(23).digits == [1, 2, 3])
        #expect(Permutation.Rank(-7).isNegative)
        #expect(Int(exactly: Permutation.Rank(-7)) == -7)
        #expect(Int(exactly: Permutation.Rank(Int.max)) == Int.max)
    }

    @Test func arithmeticMatchesIntegers() {
        var generator: SeededGenerator = SeededGenerator(state: 55)
        for _ in 0..<500 {
            let a: Int = Int.random(in: -1_000_000...1_000_000, using: &generator)
            let b: Int = Int.random(in: -1_000_000...1_000_000, using: &generator)
            let x: Permutation.Rank = Permutation.Rank(a)
            let y: Permutation.Rank = Permutation.Rank(b)
            #expect(Int(exactly: x + y) == a + b)
            #expect(Int(exactly: x - y) == a - b)
            #expect(Int(exactly: x * y) == a * b)
            #expect((x < y) == (a < b))
            #expect((x == y) == (a == b))
            #expect(Int(exactly: x.magnitude) == Int(a.magnitude))
        }
    }

    @Test func codesPastIntStillAddAndSubtract() {
        let huge: Permutation.Rank = Permutation.Rank(digits: Array(1...40))
        #expect(Int(exactly: huge) == nil)
        let sum: Permutation.Rank = huge + huge
        #expect(sum - huge == huge)
        #expect(sum > huge)
        #expect((huge * 3) - huge - huge == huge)
        #expect(huge - huge == 0)
    }

    @Test func codableRoundTrips() throws {
        for code in [Permutation.Rank(0), Permutation.Rank(-123), Permutation.Rank(digits: Array(1...30))] {
            let data: Data = try JSONEncoder().encode(code)
            #expect(try JSONDecoder().decode(Permutation.Rank.self, from: data) == code)
        }
        let bad: Data = Data(#"{"digits":[2]}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Permutation.Rank.self, from: bad) }
    }

    @Test func stridesLikeAnInteger() {
        #expect(Array(stride(from: Permutation.Rank(3), through: 7, by: 2)) == [3, 5, 7])
        #expect(Permutation.Rank(10).distance(to: 4) == -6)
        #expect(Permutation.Rank(digits: Array(1...30)).advanced(by: 1) > Permutation.Rank(digits: Array(1...30)))
    }

    @Test func codeCountsTheStepsFromTheIdentity() {
        var order: Permutation = Permutation()
        for place in 0..<200 {
            #expect(order.rank == Permutation.Rank(place))
            #expect(Permutation(rank: Permutation.Rank(place)) == order)
            order.advance(by: 1)
        }
    }

    @Test func permutationsOfNTakeThePlacesBelowNFactorial() {
        #expect(Permutation(rank: 23).minimumCount <= 4)
        #expect(Permutation(rank: 24).minimumCount == 5)
    }

    @Test func roundTripsAtAnySize() {
        var generator: SeededGenerator = SeededGenerator(state: 89)
        for count in [2, 9, 30, 1_000] {
            let permutation: Permutation = Permutation(shuffles: count, using: &generator)
            #expect(Permutation(rank: permutation.rank) == permutation)
        }
    }
}
