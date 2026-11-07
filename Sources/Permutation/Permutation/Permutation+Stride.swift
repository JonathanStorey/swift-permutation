// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Stride.swift
// dependencies: [Permutation/Permutation.swift]

// Every permutation has a place in one endless list, its rank, so `advance(by: 1)` steps to the next permutation the way `Strideable` steps any value.
//
// - The order is read off the Foata word, the line with each fixed point written in as its own cycle. Positions count from the right, so the last position matters most, and at each position a larger offset ranks first. Offsets past the moved ones sit at their own positions, which is the first choice there, so every permutation of the first `n` offsets ranks below `n!` whatever `n` is, and stepping from the identity visits every order of `n` elements before it moves any offset past them.
// - One step works straight on the word, like `next_permutation` read from the right: find the first rise from the left, swap its larger end with the first smaller entry before it, and reverse what lies before it. The entries touched average fewer than three, so a step costs one pass to write the fixed points in and one to drop them.
// - A longer step adds the distance to the word's Lehmer code in the factorial number system, carrying digit by digit, so it never computes a rank and works for a permutation of any size. Only `distance(to:)` multiplies by factorials, from the highest differing digit down, and traps if the true distance does not fit in an `Int`.
// - Digits are read and turned back into a word with a Fenwick tree in O(m log m), where m is `minimumCount`.

extension Permutation: Strideable {

    /// Returns the permutation `distance` places after this one in rank order, so `Permutation().advanced(by: 1)` swaps the first two offsets and a negative distance steps back. Stepping back past the identity is a precondition failure.
    public func advanced(by distance: Int) -> Permutation {
        switch distance {
        case 0: return self
        case 1: return successor()
        case -1: return predecessor()
        default: break
        }
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

    /// The next permutation in rank order, stepped straight on the Foata word: the first rise from the left, read as `word[p - 1] < word[p]`, takes the first earlier entry smaller than `word[p]` in exchange, and the entries before `p` are reversed. A word that falls all the way down is the last order of its length, so the next offset is written in as a fixed point to rise to.
    @usableFromInline func successor() -> Permutation {
        var word: [Int] = foataWord(count: minimumCount)
        while word.count < 2 { word.append(word.count) }
        var rise: Int = 1
        while rise < word.count && word[rise - 1] > word[rise] { rise += 1 }
        if rise == word.count { word.append(word.count) }
        var partner: Int = 0
        while word[partner] > word[rise] { partner += 1 }
        word.swapAt(partner, rise)
        word[..<rise].reverse()
        return Permutation(foataWord: word)
    }

    /// The previous permutation in rank order, the mirror of `successor()`: the first fall from the left takes the first earlier entry larger than it in exchange, and the entries before it are reversed. Stepping back from the identity is a precondition failure.
    @usableFromInline func predecessor() -> Permutation {
        var word: [Int] = foataWord(count: minimumCount)
        var fall: Int = 1
        while fall < word.count && word[fall - 1] < word[fall] { fall += 1 }
        precondition(fall < word.count, "No permutation ranks before the identity.")
        var partner: Int = 0
        while word[partner] < word[fall] { partner += 1 }
        word.swapAt(partner, fall)
        word[..<fall].reverse()
        return Permutation(foataWord: word)
    }

    /// The line over `0..<count` with every fixed point written in as its own cycle, just before the first cycle whose largest offset is larger. The result lists every offset below `count` once, so it reads as a permutation of its own.
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

    /// The Lehmer code of the Foata word over `0..<minimumCount`: digit `i` counts the entries before position `i` that are larger than the entry there, so it lies in `0...i`.
    @usableFromInline var lehmerDigits: [Int] {
        let count: Int = minimumCount
        let word: [Int] = foataWord(count: count)
        var tree: [Int] = [Int](repeating: 0, count: count + 1)
        var digits: [Int] = [Int](repeating: 0, count: count)
        for position in 0..<count {
            var smaller: Int = 0
            var node: Int = word[position]
            while node > 0 {
                smaller += tree[node]
                node -= node & -node
            }
            digits[position] = position - smaller
            node = word[position] + 1
            while node <= count {
                tree[node] += 1
                node += node & -node
            }
        }
        return digits
    }

    /// Creates the permutation whose Foata word has the Lehmer code, filling positions from the last down: each takes the remaining offset with exactly its digit of larger offsets still remaining, found by descending a Fenwick tree.
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
        var word: [Int] = [Int](repeating: 0, count: count)
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
            word[position] = node
            var update: Int = node + 1
            while update <= count {
                tree[update] -= 1
                update += update & -update
            }
        }
        self.init(foataWord: word)
    }
}
