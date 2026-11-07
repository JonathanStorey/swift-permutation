// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+LehmerCode.swift
// dependencies: [Permutation/LehmerCode.swift, Permutation/Permutation+Advance.swift, Permutation/Permutation.swift]

// A permutation's place among all permutations, as a `LehmerCode`, which makes `Permutation` `Strideable` with no ceiling.
//
// - The place counts in the order `advance(by: 1)` steps through: `Permutation(lehmerCode: k)` is exactly `Permutation().advanced(by: k)`.
// - The code is read off the Foata word, the line with each fixed point written in. The digit worth `i!` counts the entries before position `i` that are larger than the entry there, so offsets that stay put add nothing and every permutation of the first `n` offsets has a code below `n!`.
// - Both directions count with a Fenwick tree in O(m log m), where m is `minimumCount`.

extension Permutation {

    /// This permutation's place in the order `advance(by:)` steps through, starting from the identity at zero.
    public var lehmerCode: LehmerCode {
        let count: Int = minimumCount
        guard count > 1 else { return 0 }
        let word: [Int] = foataWord(count: count)
        var tree: [Int] = [Int](repeating: 0, count: count + 1)
        var digits: [Int] = [Int](repeating: 0, count: count - 1)
        for position in 0..<count {
            var smaller: Int = 0
            var node: Int = word[position]
            while node > 0 {
                smaller += tree[node]
                node -= node & -node
            }
            if position > 0 { digits[position - 1] = position - smaller }
            node = word[position] + 1
            while node <= count {
                tree[node] += 1
                node += node & -node
            }
        }
        return LehmerCode(unchecked: digits, isNegative: false)
    }

    /// Creates the permutation at the place the code gives, filling the Foata word from its last position down: each takes the remaining offset with exactly its digit of larger offsets still remaining, found by descending a Fenwick tree. The code must not be negative.
    public init(lehmerCode code: LehmerCode) {
        precondition(!code.isNegative, "No permutation comes before the identity.")
        let count: Int = code.digits.count + 1
        guard count > 1 else {
            self.init(cycle: [])
            return
        }
        var tree: [Int] = [Int](repeating: 0, count: count + 1)
        for node in 1...count {
            tree[node] += 1
            let parent: Int = node + (node & -node)
            if parent <= count { tree[parent] += tree[node] }
        }
        var highest: Int = 1
        while highest * 2 <= count { highest *= 2 }
        var word: [Int] = [Int](repeating: 0, count: count)
        for position in stride(from: count - 1, through: 0, by: -1) {
            let digit: Int = position > 0 ? code.digits[position - 1] : 0
            var remaining: Int = position - digit + 1
            var node: Int = 0
            var step: Int = highest
            while step > 0 {
                let next: Int = node + step
                if next <= count && tree[next] < remaining {
                    node = next
                    remaining -= tree[next]
                }
                step >>= 1
            }
            word[position] = node
            var update: Int = node + 1
            while update <= count {
                tree[update] -= 1
                update += update & -update
            }
        }
        self.init(foataWord: word)
    }

    /// Replaces the permutation with the one `distance` places after it, and returns the new permutation.
    @discardableResult public mutating func advance(by distance: LehmerCode) -> Permutation {
        self = advanced(by: distance)
        return self
    }
}

extension Permutation: Strideable {

    /// Returns the permutation `distance` places after this one, in O(m log m) however far the jump. Stepping back past the identity is a precondition failure.
    public func advanced(by distance: LehmerCode) -> Permutation {
        guard !distance.digits.isEmpty else { return self }
        return Permutation(lehmerCode: lehmerCode + distance)
    }

    /// The number of places from this permutation to the other, negative when the other comes first.
    public func distance(to other: Permutation) -> LehmerCode {
        other.lehmerCode - lehmerCode
    }

    /// Whether this permutation comes before the other in the order `advance(by:)` steps through.
    public static func < (lhs: Permutation, rhs: Permutation) -> Bool {
        lhs.lehmerCode < rhs.lehmerCode
    }
}
