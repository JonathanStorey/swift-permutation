// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+CodableTests.swift
// dependencies: [Permutation/Permutation+Codable.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation.swift, Support/SeededGenerator.swift]

import Foundation
import Testing
@testable import Permutation

@Suite struct PermutationCodableTests {

    @Test func encodesTheFoataLine() throws {
        let data: Data = try JSONEncoder().encode(Permutation(cycle: [2, 0, 5, 3, 4]))
        #expect(String(decoding: data, as: UTF8.self) == "[2,0,5,3,4]")
        #expect(String(decoding: try JSONEncoder().encode(Permutation()), as: UTF8.self) == "[]")
    }

    @Test func roundTripsAnyPermutation() throws {
        var generator: SeededGenerator = SeededGenerator(state: 3)
        for count in [0, 1, 2, 7, 300] {
            let permutation: Permutation = Permutation(shuffles: count, using: &generator)
            let data: Data = try JSONEncoder().encode(permutation)
            #expect(try JSONDecoder().decode(Permutation.self, from: data) == permutation)
        }
    }

    @Test(arguments: ["[1]", "[0,1]", "[2,0,3]", "[1,0,1]", "[-1,0]", "[1,-2]"]) func rejectsAnInvalidLine(json: String) {
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Permutation.self, from: Data(json.utf8)) }
    }
}
