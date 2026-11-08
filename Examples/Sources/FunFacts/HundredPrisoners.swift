// repository: https://github.com/JonathanStorey/swift-permutation
// path: Examples/Sources/FunFacts/HundredPrisoners.swift
// dependencies: [SplitMix64.swift]

import Permutation

/// The 100 prisoners problem: following the cycles frees everyone about 31% of the time, against (1/2)^100 by guessing.
///
/// Explained in [Docs/HundredPrisoners.md](../../Docs/HundredPrisoners.md).
enum HundredPrisoners {

    static func run() {
        let prisoners: Int = 100
        let trials: Int = 100_000
        var generator: SplitMix64 = SplitMix64(state: 2)
        var freed: Int = 0
        for _ in 0..<trials {
            // Prisoner k opens drawer k, then the drawer named inside, and so on, walking k's cycle.
            // Everyone succeeds exactly when no cycle is longer than the 50 drawers each may open.
            let drawers: Permutation = Permutation(shuffles: prisoners, using: &generator)
            if (drawers.cycles.map(\.count).max() ?? 0) <= prisoners / 2 { freed += 1 }
        }
        var exact: Double = 1
        for length in (prisoners / 2 + 1)...prisoners { exact -= 1 / Double(length) }
        print("2. The 100 prisoners: \(trials) random rooms")
        print("   simulated chance everyone is freed: \(format(Double(freed) / Double(trials)))")
        print("   exact 1 − (1/51 + … + 1/100): \(format(exact))    random guessing: 2^-100")
        precondition(abs(Double(freed) / Double(trials) - exact) < 0.01)
    }
}
