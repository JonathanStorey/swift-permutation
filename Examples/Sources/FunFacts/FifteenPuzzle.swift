// repository: https://github.com/JonathanStorey/swift-permutation
// path: Examples/Sources/FunFacts/FifteenPuzzle.swift
// dependencies: [SplitMix64.swift]

import Permutation

/// The 15 puzzle: exactly half of all arrangements can never be solved, and parity tells which half.
///
/// Explained in [Docs/FifteenPuzzle.md](../../Docs/FifteenPuzzle.md).
enum FifteenPuzzle {

    /// Whether the board, listed row by row with 0 for the blank, can slide back to 1…15 with the blank last.
    ///
    /// Each slide is one swap with the blank, so the arrangement's parity flips with every move, and so does the blank's distance from its home corner. The two must therefore match.
    static func isSolvable(_ board: [Int]) -> Bool {
        precondition(board.count == 16 && Set(board) == Set(0..<16), "A board holds 0 through 15 once each.")
        let labels: [Int] = board.map { $0 == 0 ? 16 : $0 }
        var sorting: PermutableSet<Int> = PermutableSet(labels)
        // Sorting the board returns the permutation that solves it, and its parity matches the board's own.
        let solution: Permutation = sorting.sort()
        let blank: Int = board.firstIndex(of: 0)!
        let distance: Int = (3 - blank / 4) + (3 - blank % 4)
        return solution.isEven == distance.isMultiple(of: 2)
    }

    static func run() {
        let loyd: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 14, 0]
        var generator: SplitMix64 = SplitMix64(state: 4)
        let trials: Int = 100_000
        var solvable: Int = 0
        for _ in 0..<trials where isSolvable(Array(0..<16).shuffled(using: &generator)) { solvable += 1 }
        print("4. The 15 puzzle")
        print("   Sam Loyd's 14–15 swap solvable: \(isSolvable(loyd))")
        print("   share of \(trials) random boards that are solvable: \(format(Double(solvable) / Double(trials)))")
        precondition(!isSolvable(loyd))
        precondition(isSolvable(Array(1...15) + [0]))
    }
}
