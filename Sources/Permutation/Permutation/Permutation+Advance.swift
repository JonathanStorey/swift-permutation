// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Advance.swift
// dependencies: [Permutation/Permutation.swift]

// Stepping from one permutation to the next, so a loop that starts at the identity visits every order.
//
// - Each step works straight on the Foata word, the line with each fixed point written in as its own cycle, like `next_permutation` read from the right: find the first rise from the left, swap its larger end with the first smaller entry before it, and reverse what lies before it. The entries touched average fewer than three.
// - Offsets past the moved ones are already where a step leaves them for last, so stepping from the identity visits all `n!` orders of the first `n` offsets before it moves any offset past them. No count is needed.
// - A few steps write the fixed points in once, take every step on the word, and drop them once at the end. Longer jumps go through the `Permutation.Rank` instead.

extension Permutation {

    /// Returns the permutation `distance` steps after this one, so `Permutation().advanced(by: 1)` swaps the first two offsets and a negative distance steps back. Stepping back past the identity is a precondition failure. A short distance is stepped straight on the Foata word, and a long one jumps through the `Permutation.Rank` in O(m log m).
    public func advanced(by distance: Int) -> Permutation {
        guard distance != 0 else { return self }
        guard distance.magnitude <= 16 else { return advanced(by: Permutation.Rank(distance)) }
        var word: [Int] = foataWord(count: minimumCount)
        if distance > 0 {
            for _ in 0..<distance { Permutation.stepForward(&word) }
        } else {
            for _ in 0..<distance.magnitude { Permutation.stepBack(&word) }
        }
        return Permutation(foataWord: word)
    }

    /// Replaces the permutation with the one `distance` steps after it, and returns the new permutation.
    @discardableResult public mutating func advance(by distance: Int) -> Permutation {
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

    /// The line over `0..<count` with every fixed point written in as its own cycle, just before the first cycle whose largest offset is larger. The result lists every offset below `count` once.
    @usableFromInline func foataWord(count: Int) -> [Int] {
        var isMoved: [Bool] = [Bool](repeating: false, count: count)
        for offset in cycle { isMoved[offset] = true }
        var word: [Int] = []
        word.reserveCapacity(count)
        var candidate: Int = 0
        var position: Int = 0
        while position < cycle.count {
            let root: Int = cycle[position]
            while candidate < root {
                if !isMoved[candidate] { word.append(candidate) }
                candidate += 1
            }
            word.append(root)
            position += 1
            while position < cycle.count && cycle[position] < root {
                word.append(cycle[position])
                position += 1
            }
        }
        while candidate < count {
            if !isMoved[candidate] { word.append(candidate) }
            candidate += 1
        }
        return word
    }

    /// Creates the permutation whose Foata word, fixed points included, is the word: each entry larger than every one before it starts a cycle, and cycles of one offset are dropped.
    @usableFromInline init(foataWord word: [Int]) {
        var line: [Int] = []
        line.reserveCapacity(word.count)
        var start: Int = 0
        while start < word.count {
            let root: Int = word[start]
            var end: Int = start + 1
            while end < word.count && word[end] < root { end += 1 }
            if end - start > 1 { line.append(contentsOf: word[start..<end]) }
            start = end
        }
        self.init(cycle: line)
    }
}
