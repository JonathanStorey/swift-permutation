// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+MathProperties.swift
// dependencies: [Permutation/Permutation.swift]

extension Permutation {

    /// The offset that the element at `offset` moves to: the next offset in its cycle, wrapping from the last back to the largest. An offset outside every cycle stays where it is.
    ///
    /// ```swift
    /// let rotation: Permutation = Permutation(cycles: [[2, 0, 1]])
    /// rotation[destinationOf: 2]   // 0
    /// rotation[destinationOf: 7]   // 7, outside every cycle
    /// ```
    public subscript(destinationOf offset: Int) -> Int {
        precondition(offset >= 0, "An offset cannot be negative.")
        var rootPosition: Int = -1
        var root: Int = -1
        for position in cycle.indices {
            let current: Int = cycle[position]
            if current > root {
                root = current
                rootPosition = position
            }
            if current == offset {
                let next: Int = position + 1
                return next < cycle.count && cycle[next] < root ? cycle[next] : cycle[rootPosition]
            }
        }
        return offset
    }

    /// Returns the permutation that applies this one and then swaps the elements at offsets `first` and `second`.
    ///
    /// Swapping two offsets of one cycle splits it in two, and swapping offsets of different cycles joins them, so only the one or two cycles involved are rewritten and the rest of the line is copied as it stands.
    public func swapping(_ first: Int, _ second: Int) -> Permutation {
        precondition(first >= 0 && second >= 0, "An offset cannot be negative.")
        guard first != second else { return self }
        let firstBlock: Range<Int>? = block(containing: first)
        let secondBlock: Range<Int>? = block(containing: second)
        var replaced: [[Int]] = []
        if let block: Range<Int> = firstBlock, block == secondBlock {
            let length: Int = block.count
            let firstIndex: Int = cycle[block].firstIndex(of: first)! - block.lowerBound
            let secondIndex: Int = cycle[block].firstIndex(of: second)! - block.lowerBound
            let low: Int = min(firstIndex, secondIndex)
            let high: Int = max(firstIndex, secondIndex)
            replaced.append((low..<high).map { cycle[block.lowerBound + $0] })
            replaced.append((high..<(low + length)).map { cycle[block.lowerBound + $0 % length] })
        } else {
            replaced.append(rotated(firstBlock, toStartAt: first) + rotated(secondBlock, toStartAt: second))
        }
        var removed: [Range<Int>] = [firstBlock, secondBlock].compactMap { $0 }.sorted { $0.lowerBound < $1.lowerBound }
        if removed.count == 2, removed[0] == removed[1] { removed.removeLast() }
        var inserted: [[Int]] = []
        for cycle in replaced where cycle.count > 1 {
            let rootIndex: Int = cycle.indices.max { cycle[$0] < cycle[$1] }!
            inserted.append(Array(cycle[rootIndex...] + cycle[..<rootIndex]))
        }
        inserted.sort { $0[0] < $1[0] }
        var line: [Int] = []
        line.reserveCapacity(cycle.count + 2)
        var nextInserted: Int = 0
        var nextRemoved: Int = 0
        var root: Int = -1
        for position in cycle.indices {
            if nextRemoved < removed.count, position == removed[nextRemoved].lowerBound {
                nextRemoved += 1
            }
            if nextRemoved > 0, removed[nextRemoved - 1].contains(position) { continue }
            if cycle[position] > root {
                root = cycle[position]
                while nextInserted < inserted.count, inserted[nextInserted][0] < root {
                    line.append(contentsOf: inserted[nextInserted])
                    nextInserted += 1
                }
            }
            line.append(cycle[position])
        }
        for cycle in inserted[nextInserted...] {
            line.append(contentsOf: cycle)
        }
        return Permutation(cycle: line)
    }

    /// The positions on the line of the cycle holding `offset`, or `nil` when the offset is a fixed point.
    func block(containing offset: Int) -> Range<Int>? {
        var blockStart: Int = 0
        var root: Int = -1
        var found: Bool = false
        for position in cycle.indices {
            if cycle[position] > root {
                if found { return blockStart..<position }
                root = cycle[position]
                blockStart = position
            }
            if cycle[position] == offset { found = true }
        }
        return found ? blockStart..<cycle.count : nil
    }

    /// The cycle at `block` read starting from `offset`, or just `[offset]` for a fixed point.
    func rotated(_ block: Range<Int>?, toStartAt offset: Int) -> [Int] {
        guard let block: Range<Int> = block else { return [offset] }
        let start: Int = cycle[block].firstIndex(of: offset)!
        return Array(cycle[start..<block.upperBound] + cycle[block.lowerBound..<start])
    }
}
