// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Stride.swift
// dependencies: [Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

// Every permutation has a place in one endless list, its rank, so `advance(by: 1)` steps to the next permutation the way `Strideable` steps any value.
//
// - The rank reads the Lehmer code of the sources in the factorial number system: digit `i` counts the earlier positions whose source is larger than position `i`'s, and is worth `i!`. Offsets that stay put add nothing, so every permutation of the first `n` offsets ranks below `n!` whatever `n` is, and stepping from the identity visits every order of `n` elements before it moves any offset past them.
// - Stepping adds the distance to the digits with carries, so it never computes a rank and works for a permutation of any size. Only `distance(to:)` multiplies by factorials, from the highest differing digit down, and traps if the true distance does not fit in an `Int`.
// - Digits and orders are read and rebuilt with a Fenwick tree in O(m log m), where m is `minimumCount`.

extension Permutation: Strideable {

    /// Returns the permutation `distance` places after this one in rank order, so `Permutation().advanced(by: 1)` swaps the first two offsets and a negative distance steps back. Stepping back past the identity is a precondition failure.
    public func advanced(by distance: Int) -> Permutation {
        guard distance != 0 else { return self }
        var digits: [Int] = lehmerDigits
        var carry: Int = distance
        var place: Int = 1
        while carry != 0 {
            if place >= digits.count {
                precondition(carry > 0, "No permutation ranks before the identity.")
                while digits.count <= place { digits.append(0) }
            }
            let base: Int = place + 1
            var quotient: Int = carry / base
            var digit: Int = digits[place] + carry % base
            if digit >= base {
                digit -= base
                quotient += 1
            } else if digit < 0 {
                digit += base
                quotient -= 1
            }
            digits[place] = digit
            carry = quotient
            place += 1
        }
        return Permutation(lehmerDigits: digits)
    }

    /// The number of steps from this permutation to the other in rank order, negative when the other ranks first. Traps when the distance does not fit in an `Int`, which takes permutations that differ beyond the first 20 offsets.
    public func distance(to other: Permutation) -> Int {
        let mine: [Int] = lehmerDigits
        let theirs: [Int] = other.lehmerDigits
        var distance: Int = 0
        for place in stride(from: Swift.max(mine.count, theirs.count) - 1, through: 1, by: -1) {
            let difference: Int = (place < theirs.count ? theirs[place] : 0) - (place < mine.count ? mine[place] : 0)
            distance = (distance + difference) * place
        }
        return distance
    }

    /// Whether this permutation ranks before the other, comparing digits from the highest place down so it never overflows.
    public static func < (lhs: Permutation, rhs: Permutation) -> Bool {
        let mine: [Int] = lhs.lehmerDigits
        let theirs: [Int] = rhs.lehmerDigits
        for place in stride(from: Swift.max(mine.count, theirs.count) - 1, through: 1, by: -1) {
            let left: Int = place < mine.count ? mine[place] : 0
            let right: Int = place < theirs.count ? theirs[place] : 0
            if left != right { return left < right }
        }
        return false
    }

    /// Replaces the permutation with the one `distance` places after it in rank order, and returns the new permutation.
    @discardableResult public mutating func advance(by distance: Int) -> Permutation {
        self = advanced(by: distance)
        return self
    }
}

extension Permutation {

    /// The Lehmer code of the sources over `0..<minimumCount`: digit `i` counts the positions before `i` whose source is larger than the source at `i`, so it lies in `0...i`, and the highest digit is never zero.
    @usableFromInline var lehmerDigits: [Int] {
        let count: Int = minimumCount
        let sources: [Int] = sources(count: count)
        var tree: [Int] = [Int](repeating: 0, count: count + 1)
        var digits: [Int] = [Int](repeating: 0, count: count)
        for position in 0..<count {
            var smaller: Int = 0
            var node: Int = sources[position]
            while node > 0 {
                smaller += tree[node]
                node -= node & -node
            }
            digits[position] = position - smaller
            node = sources[position] + 1
            while node <= count {
                tree[node] += 1
                node += node & -node
            }
        }
        return digits
    }

    /// Creates the permutation whose sources have the Lehmer code, filling positions from the last down: each takes the remaining source with exactly its digit of larger sources still remaining, found by descending a Fenwick tree.
    @usableFromInline init(lehmerDigits digits: [Int]) {
        let count: Int = digits.count
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
        var sources: [Int] = [Int](repeating: 0, count: count)
        for position in stride(from: count - 1, through: 0, by: -1) {
            var remaining: Int = position - digits[position] + 1
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
            sources[position] = node
            var update: Int = node + 1
            while update <= count {
                tree[update] -= 1
                update += update & -update
            }
        }
        self.init(sources: sources)
    }
}
