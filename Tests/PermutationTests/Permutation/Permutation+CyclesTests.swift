// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+CyclesTests.swift
// dependencies: [Permutation/Permutation+Composition.swift, Permutation/Permutation+Cycles.swift, Permutation/Permutation+Power.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Sources.swift, Permutation/Permutation.swift, Support/Deck.swift, Support/SeededGenerator.swift]

import Testing
@testable import Permutation

@Suite struct PermutationCyclesTests {

    func randomPermutations(seed: UInt64, maximumCount: Int = 9) -> [Permutation] {
        var generator: SeededGenerator = SeededGenerator(state: seed)
        return (0..<200).map { _ in Permutation(shuffles: Int.random(in: 0...maximumCount, using: &generator), using: &generator) }
    }

    @Test func cyclesSplitTheLineAtEachLargestOffset() {
        let cycles: Permutation.Cycles = Permutation(cycle: [2, 0, 1, 5, 3, 7, 6, 4]).cycles
        #expect(Array(cycles) == [[2, 0, 1], [5, 3], [7, 6, 4]])
        #expect(Array(cycles.dropFirst()) == [[5, 3], [7, 6, 4]])
        #expect(cycles.count == 3)
        #expect(cycles.movedCount == 8)
        #expect(Permutation().cycles.isEmpty)
        #expect(Array(Permutation().cycles).isEmpty)
        for permutation in randomPermutations(seed: 11) {
            #expect(permutation.cycles.map(\.count).reduce(0, +) == permutation.cycles.movedCount)
            #expect(permutation.cycles.allSatisfy { $0.count > 1 })
            #expect(Permutation(cycles: Array(permutation.cycles)) == permutation)
        }
    }

    @Test func cyclesPrintInStandardNotation() {
        #expect(Permutation(cycle: [2, 0, 5, 3, 4]).cycles.description == "(2 0)(5 3 4)")
        #expect(Permutation().cycles.description == "()")
        #expect(Permutation(cycle: [2, 0, 5, 3, 4]).description == "(2 0)(5 3 4)")
        #expect(Permutation(cycle: [2, 0, 5, 3, 4]).debugDescription == "Permutation((2 0)(5 3 4))")
        #expect("\(Permutation())" == "()")
    }

    @Test func cycleContainingFindsTheOffsetsCycle() {
        let cycles: Permutation.Cycles = Permutation(cycle: [2, 0, 5, 3, 4]).cycles
        #expect(cycles.cycle(containing: 0) == [2, 0])
        #expect(cycles.cycle(containing: 4) == [5, 3, 4])
        #expect(cycles.cycle(containing: 5) == [5, 3, 4])
        #expect(cycles.cycle(containing: 1) == nil)
        #expect(cycles.cycle(containing: 9) == nil)
    }

    @Test func initFromCyclesTakesAnyRotationAndOrder() {
        #expect(Permutation(cycles: [[4, 5, 3], [0, 2], [1]]) == Permutation(cycle: [2, 0, 5, 3, 4]))
        #expect(Permutation(cycles: []) == Permutation())
    }

    @Test func orderIsTheFirstPowerThatIsTheIdentity() {
        #expect(Permutation(cycle: []).cycles.order == 1)
        #expect(Permutation(cycle: [2, 0, 1, 4, 3]).cycles.order == 6)
        for permutation in randomPermutations(seed: 12) {
            let order: Int = permutation.cycles.order
            #expect(permutation.raised(to: order).cycle.isEmpty)
            #expect((1..<order).allSatisfy { !permutation.raised(to: $0).cycle.isEmpty })
        }
    }

    @Test func parityMatchesTheParityOfInversions() {
        #expect(Permutation(cycle: []).cycles.parity == .even)
        #expect(Permutation(cycle: [1, 0]).cycles.parity == .odd)
        #expect(Permutation(cycle: [2, 0, 1]).cycles.parity == .even)
        for permutation in randomPermutations(seed: 13) {
            let sources: [Int] = permutation.sources(count: permutation.minimumCount)
            var inversions: Int = 0
            for i in sources.indices {
                for j in sources.indices where i < j && sources[i] > sources[j] {
                    inversions += 1
                }
            }
            #expect(permutation.cycles.parity == (inversions.isMultiple(of: 2) ? .even : .odd))
        }
    }

    @Test func isInvolutionMatchesSquaringToTheIdentity() {
        #expect(Permutation(cycle: []).cycles.isInvolution)
        #expect(Permutation(cycle: [1, 0, 4, 2]).cycles.isInvolution)
        #expect(!Permutation(cycle: [2, 0, 1]).cycles.isInvolution)
        for permutation in randomPermutations(seed: 14, maximumCount: 5) {
            #expect(permutation.cycles.isInvolution == permutation.followed(by: permutation).cycle.isEmpty)
        }
    }

    @Test func cyclesSplitsTheLineAtEachNewLargestOffset() {
        var cycles: [[Int]] = []
        for cycle in Permutation(cycle: [2, 0, 5, 3, 4, 7, 6]).cycles { cycles.append(cycle) }
        #expect(cycles == [[2, 0], [5, 3, 4], [7, 6]])
    }

    @Test func cyclesOfEmptyPermutationCallsNothing() {
        var calls: Int = 0
        for _ in Permutation(shuffles: 0).cycles { calls += 1 }
        #expect(calls == 0)
    }

    @Test func cyclesMovesEachElementToTheNextOffset() {
        var generator: SeededGenerator = SeededGenerator(state: 7)
        let original: [String] = (0..<40).map(String.init)
        let permutation: Permutation = Permutation(shuffles: 40, using: &generator)
        var deck: Deck = Deck(cards: original)
        deck.apply(permutation)
        var rotated: [String] = original
        for cycle in permutation.cycles {
            let last: String = rotated[cycle[cycle.count - 1]]
            for position in stride(from: cycle.count - 1, to: 0, by: -1) {
                rotated[cycle[position]] = rotated[cycle[position - 1]]
            }
            rotated[cycle[0]] = last
        }
        #expect(rotated == deck.cards)
    }
}
