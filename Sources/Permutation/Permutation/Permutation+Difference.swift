// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Difference.swift
// dependencies: [Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

// Reading a reorder out of a `CollectionDifference`, the reverse of `moves`.
//
// - Every offset in a difference is counted in a collection its own insertions and removals have shifted, so a difference is a permutation only when it is a pure reorder: every removal paired with an insertion of the same element. Anything else yields nil rather than a permutation that moves the wrong elements.
// - The pairing comes from calling `inferringMoves()` here, which pairs an element only when it is removed exactly once and inserted exactly once, so moved duplicates stay unpaired and yield nil instead of a guess. Pairs that arrive already associated are checked for equal elements.
// - Each insertion's new offset takes its removal's old offset as its source, and the untouched old offsets fill the remaining new offsets in order, in one pass. Offsets past the largest one mentioned stay put, so no count is needed.

extension Permutation {

    /// Creates the permutation a difference describes when it only reorders, or nil when it inserts or removes anything, or moves an element that appears more than once.
    ///
    /// The difference is paired with `inferringMoves()` first, so `new.difference(from: old)` can be passed straight in, and `old.applying(permutation)` then equals `new`.
    public init?<Element: Hashable>(_ difference: CollectionDifference<Element>) {
        var count: Int = 0
        var isRemoved: Set<Int> = []
        var removedElements: [Int: Element] = [:]
        var insertions: [(offset: Int, source: Int, element: Element)] = []
        for change in difference.inferringMoves() {
            switch change {
            case let .remove(offset, element, associatedWith):
                guard associatedWith != nil else { return nil }
                isRemoved.insert(offset)
                removedElements[offset] = element
                count = max(count, offset + 1)
            case let .insert(offset, element, associatedWith):
                guard let source: Int = associatedWith else { return nil }
                insertions.append((offset, source, element))
                count = max(count, offset + 1)
            }
        }
        var sources: [Int] = [Int](repeating: -1, count: count)
        for insertion in insertions {
            guard removedElements[insertion.source] == insertion.element else { return nil }
            sources[insertion.offset] = insertion.source
        }
        var next: Int = 0
        for position in sources.indices where sources[position] < 0 {
            while isRemoved.contains(next) { next += 1 }
            sources[position] = next
            next += 1
        }
        self.init(sources: sources)
    }
}
