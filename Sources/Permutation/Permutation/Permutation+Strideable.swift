// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Strideable.swift
// dependencies: [Permutation/Permutation+Rank.swift, Permutation/Permutation.swift]

// `Permutation` is `Strideable` with `Permutation.Rank` as its stride, so a loop that starts at the identity visits every order and a jump of any size never overflows.
//
// - The order is the one `rank` counts: `Permutation(rank: k)` is exactly `Permutation().advanced(by: k)`. Since `Permutation.Rank` is `ExpressibleByIntegerLiteral`, `advance(by: 1)` reads as it always did.
// - A short distance steps straight on the Foata word, the line with each fixed point written in as its own cycle, like `next_permutation` read from the right: find the first rise from the left, swap its larger end with the first smaller entry before it, and reverse what lies before it. The entries touched average fewer than three.
// - Offsets past the moved ones are already where a step leaves them for last, so stepping from the identity visits all `n!` orders of the first `n` offsets before it moves any offset past them. No count is needed.
// - A long distance jumps through the rank instead, in O(m log m) however far.

extension Permutation: Strideable {

    /// Returns the permutation `distance` places after this one, so `Permutation().advanced(by: 1)` swaps the first two offsets and a negative distance steps back. Stepping back past the identity is a precondition failure. Up to 16 places are stepped straight on the Foata word, and anything farther jumps through the rank in O(m log m).
    public func advanced(by distance: Permutation.Rank) -> Permutation {
        guard !distance.digits.isEmpty else { return self }
        guard distance.digits.count <= 3, let steps: Int = Int(exactly: distance), steps.magnitude <= 16 else {
            return Permutation(rank: rank + distance)
        }
        var word: [Int] = foataWord(count: minimumCount)
        if steps > 0 {
            for _ in 0..<steps { Permutation.stepForward(&word) }
        } else {
            for _ in 0..<steps.magnitude { Permutation.stepBack(&word) }
        }
        return Permutation(foataWord: word)
    }

    /// The number of places from this permutation to the other, negative when the other comes first.
    public func distance(to other: Permutation) -> Permutation.Rank {
        other.rank - rank
    }

    /// Whether this permutation comes before the other in the order `advanced(by:)` steps through.
    public static func < (lhs: Permutation, rhs: Permutation) -> Bool {
        lhs.rank < rhs.rank
    }
}

extension Permutation {

    /// Replaces the permutation with the one `distance` places after it, and returns the new permutation.
    @discardableResult public mutating func advance(by distance: Permutation.Rank) -> Permutation {
        self = advanced(by: distance)
        return self
    }

    /// Steps a Foata word to the next: the first rise from the left, read as `word[p - 1] < word[p]`, takes the first earlier entry smaller than `word[p]` in exchange, and the entries before `p` are reversed. A word that falls all the way down is the last order of its length, so the next offset is written in as a fixed point to rise to.
    @usableFromInline static func stepForward(_ word: inout [Int]) {
        while word.count < 2 { word.append(word.count) }
        var rise: Int = 1
        while rise < word.count && word[rise - 1] > word[rise] { rise += 1 }
        if rise == word.count { word.append(word.count) }
        var partner: Int = 0
        while word[partner] > word[rise] { partner += 1 }
        word.swapAt(partner, rise)
        word[..<rise].reverse()
    }

    /// Steps a Foata word back, the mirror of `stepForward(_:)`: the first fall from the left takes the first earlier entry larger than it in exchange, and the entries before it are reversed.
    @usableFromInline static func stepBack(_ word: inout [Int]) {
        var fall: Int = 1
        while fall < word.count && word[fall - 1] < word[fall] { fall += 1 }
        precondition(fall < word.count, "No permutation comes before the identity.")
        var partner: Int = 0
        while word[partner] < word[fall] { partner += 1 }
        word.swapAt(partner, fall)
        word[..<fall].reverse()
    }
}
