// repository: https://github.com/JonathanStorey/swift-permutation
// path: Examples/Sources/FunFacts/SecretSanta.swift
// dependencies: [SplitMix64.swift]

import Permutation

/// Secret Santa: in a fair draw where nobody gets themselves, the chance that the gifts form one unbroken chain through everyone is about e/n.
///
/// Explained in [Docs/SecretSanta.md](../../Docs/SecretSanta.md).
enum SecretSanta {

    static let names: [String] = ["Ava", "Ben", "Cyd", "Dee", "Eli", "Fay", "Gus", "Hal", "Ivy", "Jo"]

    /// Draws a fair Secret Santa: every giver starts paired with themselves, then the recipients are reassigned by a derangement while the givers stay put.
    static func draw(using generator: inout SplitMix64) -> PermutableDictionary<String, String> {
        var recipients: PermutableDictionary<String, String> = PermutableDictionary(uniqueKeys: names, values: names)
        recipients.reassignValues(shuffling: .derangement, using: &generator)
        return recipients
    }

    /// Follows the gifts from the first giver until they come back around, returning everyone visited in order.
    static func chain(in recipients: PermutableDictionary<String, String>) -> [String] {
        var visited: [String] = [names[0]]
        var giver: String = recipients[names[0]]!
        while giver != names[0] {
            visited.append(giver)
            giver = recipients[giver]!
        }
        return visited
    }

    static func run() {
        let n: Int = names.count
        let trials: Int = 200_000
        var generator: SplitMix64 = SplitMix64(state: 6)
        let example: PermutableDictionary<String, String> = draw(using: &generator)
        var oneChain: Int = 0
        for _ in 0..<trials {
            let recipients: PermutableDictionary<String, String> = draw(using: &generator)
            precondition(recipients.allSatisfy { $0.key != $0.value } && Array(recipients.keys) == names)
            if chain(in: recipients).count == n { oneChain += 1 }
        }
        // A single chain is an n-cycle: (n − 1)! of them among the D(n) derangements.
        var cycles: Double = 1
        for k in 1..<n { cycles *= Double(k) }
        let exact: Double = cycles / HatCheckProblem.derangements(n)
        let simulated: Double = Double(oneChain) / Double(trials)
        print("6. Secret Santa: \(n) friends, \(trials) fair draws")
        print("   one draw: " + chain(in: example).joined(separator: " → ") + " → \(names[0])")
        print("   simulated chance of one chain through everyone: \(format(simulated))")
        print("   exact (n − 1)! / D(n): \(format(exact))    e/n: \(format(2.718281828459045 / Double(n)))")
        // Redrawing the whole hat until nobody holds their own name takes n!/D(n) draws on average, which tends to e.
        print("   expected hat draws until nobody holds their own name, n! / D(n): \(format(cycles * Double(n) / HatCheckProblem.derangements(n)))    e: \(format(2.718281828459045))")
        precondition(abs(simulated - exact) < 0.005)
    }
}
