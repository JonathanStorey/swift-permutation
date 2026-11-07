// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/LehmerCodeTests.swift
// dependencies: [Permutation/LehmerCode.swift, Support/SeededGenerator.swift]

import Foundation
import Testing
@testable import Permutation

@Suite struct LehmerCodeTests {

    @Test func digitsCountInTheFactorialNumberSystem() {
        #expect(LehmerCode(0).digits.isEmpty)
        #expect(LehmerCode(1).digits == [1])
        #expect(LehmerCode(5).digits == [1, 2])
        #expect(LehmerCode(6).digits == [0, 0, 1])
        #expect(LehmerCode(23).digits == [1, 2, 3])
        #expect(LehmerCode(-7).isNegative)
        #expect(Int(exactly: LehmerCode(-7)) == -7)
        #expect(Int(exactly: LehmerCode(Int.max)) == Int.max)
    }

    @Test func arithmeticMatchesIntegers() {
        var generator: SeededGenerator = SeededGenerator(state: 55)
        for _ in 0..<500 {
            let a: Int = Int.random(in: -1_000_000...1_000_000, using: &generator)
            let b: Int = Int.random(in: -1_000_000...1_000_000, using: &generator)
            let x: LehmerCode = LehmerCode(a)
            let y: LehmerCode = LehmerCode(b)
            #expect(Int(exactly: x + y) == a + b)
            #expect(Int(exactly: x - y) == a - b)
            #expect(Int(exactly: x * y) == a * b)
            #expect((x < y) == (a < b))
            #expect((x == y) == (a == b))
            #expect(Int(exactly: x.magnitude) == Int(a.magnitude))
        }
    }

    @Test func codesPastIntStillAddAndSubtract() {
        let huge: LehmerCode = LehmerCode(digits: Array(1...40))
        #expect(Int(exactly: huge) == nil)
        let sum: LehmerCode = huge + huge
        #expect(sum - huge == huge)
        #expect(sum > huge)
        #expect((huge * 3) - huge - huge == huge)
        #expect(huge - huge == 0)
    }

    @Test func codableRoundTrips() throws {
        for code in [LehmerCode(0), LehmerCode(-123), LehmerCode(digits: Array(1...30))] {
            let data: Data = try JSONEncoder().encode(code)
            #expect(try JSONDecoder().decode(LehmerCode.self, from: data) == code)
        }
        let bad: Data = Data(#"{"digits":[2]}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(LehmerCode.self, from: bad) }
    }

    @Test func stridesLikeAnInteger() {
        #expect(Array(stride(from: LehmerCode(3), through: 7, by: 2)) == [3, 5, 7])
        #expect(LehmerCode(10).distance(to: 4) == -6)
        #expect(LehmerCode(digits: Array(1...30)).advanced(by: 1) > LehmerCode(digits: Array(1...30)))
    }
}
