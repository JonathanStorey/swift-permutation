// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+LehmerCodeTests.swift
// dependencies: [Permutation/LehmerCode.swift, Permutation/Permutation+Advance.swift, Permutation/Permutation+LehmerCode.swift, Permutation/Permutation+Shuffle.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationLehmerCodeTests {

    @Test func codeCountsTheStepsFromTheIdentity() {
        var order: Permutation = Permutation()
        for place in 0..<200 {
            #expect(order.lehmerCode == LehmerCode(place))
            #expect(Permutation(lehmerCode: LehmerCode(place)) == order)
            order.advance(by: 1)
        }
    }

    @Test func permutationsOfNTakeThePlacesBelowNFactorial() {
        #expect(Permutation(lehmerCode: 23).minimumCount <= 4)
        #expect(Permutation(lehmerCode: 24).minimumCount == 5)
    }

    @Test func roundTripsAtAnySize() {
        var generator: SeededGenerator = SeededGenerator(state: 89)
        for count in [2, 9, 30, 1_000] {
            let permutation: Permutation = Permutation(shuffles: count, using: &generator)
            #expect(Permutation(lehmerCode: permutation.lehmerCode) == permutation)
        }
    }

    @Test func longJumpsAgreeWithSteps() {
        var generator: SeededGenerator = SeededGenerator(state: 144)
        for count in [5, 12, 400] {
            let permutation: Permutation = Permutation(shuffles: count, using: &generator)
            var stepped: Permutation = permutation
            for _ in 0..<40 { stepped.advance(by: 1) }
            #expect(permutation.advanced(by: 40) == stepped)
            #expect(Permutation(lehmerCode: permutation.lehmerCode + 40) == stepped)
            #expect(stepped.advanced(by: -40) == permutation)
            #expect(stepped.lehmerCode - permutation.lehmerCode == 40)
            #expect(permutation.lehmerCode < stepped.lehmerCode)
        }
    }

    @Test func distancesPastIntStayExact() {
        var generator: SeededGenerator = SeededGenerator(state: 233)
        let permutation: Permutation = Permutation(shuffles: 50, using: &generator)
        let jump: LehmerCode = LehmerCode(digits: Array(1...45))
        let later: Permutation = Permutation(lehmerCode: permutation.lehmerCode + jump)
        #expect(later.lehmerCode - permutation.lehmerCode == jump)
        #expect(Permutation(lehmerCode: later.lehmerCode - jump) == permutation)
        #expect(Int(exactly: Permutation(reversing: 30).lehmerCode) == nil)
    }

    @Test func strideOverCodesWalksEveryOrder() {
        let orders: [Permutation] = stride(from: LehmerCode(0), to: 6, by: 1).map(Permutation.init(lehmerCode:))
        #expect(orders.count == 6)
        #expect(Set(orders.map { [0, 1, 2].applying($0) }).count == 6)
    }
}
