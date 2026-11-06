// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Collection+Permutation.swift
// dependencies: [Collections/PermutableCollection.swift, Permutation/Permutation+ForEach.swift, Permutation/Permutation.swift]

// Applying a permutation to the standard collection protocols, each in the cheapest way its protocol allows:
//
// - MutableCollection rotates each cycle in place through one carried element, writing each moved element once plus once per cycle and allocating nothing with random access.
// - RangeReplaceableCollection without MutableCollection, such as String, rebuilds once in the new order.
// - Collection returns an array in the new order.
//
// A type that conforms to more than one gets the in-place rotation, through the tie-breaking extensions at the end of the file.

// MARK: - Collection

public extension Collection {

    /// Returns the elements in the order the permutation gives them, leaving offsets outside its cycles in place.
    @inlinable func applying(_ permutation: Permutation) -> [Element] {
        var elements: [Element] = Array(self)
        elements.apply(permutation)
        return elements
    }
}

// MARK: - MutableCollection

extension MutableCollection {

    /// Rotates each cycle in place through one carried element, at indices found in one walk, for a collection without random access.
    @inlinable mutating func rotateCyclesWalkingIndices(of permutation: Permutation) {
        let minimumCount: Int = permutation.minimumCount
        precondition(minimumCount <= count, "Every offset in the cycle must be within the collection.")
        let positions: [Index] = Array(indices.prefix(minimumCount))
        let line: [Int] = permutation.cycle
        guard let first: Int = line.first else { return }
        var start: Int = first
        var carried: Element = self[positions[first]]
        for offset in line.dropFirst() {
            if offset > start {
                self[positions[start]] = carried
                start = offset
                carried = self[positions[offset]]
            } else {
                swap(&carried, &self[positions[offset]])
            }
        }
        self[positions[start]] = carried
    }

    /// Rotates each cycle in place through one carried element, finding each index in O(1) and allocating nothing. Only each cycle's largest offset is checked against the count, which covers the rest in Foata form.
    @inlinable mutating func rotateCyclesOffsettingIndices(of permutation: Permutation) where Self: RandomAccessCollection {
        let count: Int = self.count
        let line: [Int] = permutation.cycle
        guard let first: Int = line.first else { return }
        let base: Index = startIndex
        precondition(first < count, "Every offset in the cycle must be within the collection.")
        var start: Int = first
        var carried: Element = self[index(base, offsetBy: first)]
        for offset in line.dropFirst() {
            if offset > start {
                precondition(offset < count, "Every offset in the cycle must be within the collection.")
                self[index(base, offsetBy: start)] = carried
                start = offset
                carried = self[index(base, offsetBy: offset)]
            } else {
                let position: Index = index(base, offsetBy: offset)
                swap(&carried, &self[position])
            }
        }
        self[index(base, offsetBy: start)] = carried
    }
}

public extension MutableCollection {

    /// Applies the permutation in place, rotating each cycle through one carried element.
    @inlinable mutating func apply(_ permutation: Permutation) {
        rotateCyclesWalkingIndices(of: permutation)
    }
}

public extension MutableCollection where Self: RandomAccessCollection {

    /// Applies the permutation in place, rotating each cycle through one carried element without allocating.
    @inlinable mutating func apply(_ permutation: Permutation) {
        rotateCyclesOffsettingIndices(of: permutation)
    }
}

// MARK: - RangeReplaceableCollection

public extension RangeReplaceableCollection {

    /// Returns a copy in the order the permutation gives, built in one pass, leaving offsets outside its cycles in place.
    @inlinable func applying(_ permutation: Permutation) -> Self {
        let minimumCount: Int = permutation.minimumCount
        precondition(minimumCount <= count, "Every offset in the cycle must be within the collection.")
        let positions: [Index] = Array(indices.prefix(minimumCount))
        var order: [Int] = Array(0..<minimumCount)
        order.apply(permutation)
        var result: Self = Self()
        result.reserveCapacity(count)
        for offset in order { result.append(self[positions[offset]]) }
        result.append(contentsOf: self[(positions.last.map(index(after:)) ?? startIndex)...])
        return result
    }

    /// Applies the permutation by rebuilding the collection once in the new order.
    @inlinable mutating func apply(_ permutation: Permutation) {
        self = applying(permutation)
    }
}

// MARK: - Conforming to more than one

public extension MutableCollection where Self: RangeReplaceableCollection {

    /// Applies the permutation in place, which beats rebuilding.
    @inlinable mutating func apply(_ permutation: Permutation) {
        rotateCyclesWalkingIndices(of: permutation)
    }

    /// Returns a copy with the permutation applied in place, which beats rebuilding. A copy is independent only for a type with value semantics, as range-replaceable collections are expected to have.
    @inlinable func applying(_ permutation: Permutation) -> Self {
        var copy: Self = self
        copy.apply(permutation)
        return copy
    }
}

public extension MutableCollection where Self: RandomAccessCollection & RangeReplaceableCollection {

    /// Applies the permutation in place without allocating.
    @inlinable mutating func apply(_ permutation: Permutation) {
        rotateCyclesOffsettingIndices(of: permutation)
    }

    /// Returns a copy with the permutation applied in place, which costs one copy and no rebuild.
    @inlinable func applying(_ permutation: Permutation) -> Self {
        var copy: Self = self
        copy.apply(permutation)
        return copy
    }
}

// MARK: - PermutableCollection conforming to the standard protocols too
//
// A PermutableCollection that is also a MutableCollection or a RangeReplaceableCollection would otherwise see two equally specific versions of `apply`, `applying`, `sort` and `reverse`, which fails to compile. These extensions settle each one:
//
// - `apply` and `applying` take the cheapest path the standard protocols allow, as above.
// - A MutableCollection keeps the standard library's in-place `sort` and `reverse`, which build no permutation. A call still gets the permutation it applied by asking for one, as in `let permutation: Permutation = tiles.sort()`.

public extension PermutableCollection where Self: MutableCollection {

    /// Applies the permutation in place, rotating each cycle through one carried element.
    @inlinable mutating func apply(_ permutation: Permutation) {
        rotateCyclesWalkingIndices(of: permutation)
    }
}

public extension PermutableCollection where Self: MutableCollection & BidirectionalCollection {

    /// Reverses the elements in place as `MutableCollection` does, building no permutation. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func reverse() {
        standardReverse(&self)
    }
}

public extension PermutableCollection where Self: MutableCollection & RandomAccessCollection {

    /// Applies the permutation in place, rotating each cycle through one carried element without allocating.
    @inlinable mutating func apply(_ permutation: Permutation) {
        rotateCyclesOffsettingIndices(of: permutation)
    }

    /// Sorts the elements in place as `MutableCollection` does, building no permutation. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows {
        try standardSort(&self, by: areInIncreasingOrder)
    }
}

public extension PermutableCollection where Self: MutableCollection & RandomAccessCollection, Element: Comparable {

    /// Sorts the elements in ascending order in place as `MutableCollection` does, building no permutation. Ask for a `Permutation` result to get the one applied.
    @inlinable mutating func sort() {
        standardSort(&self, by: <)
    }
}

public extension PermutableCollection where Self: RangeReplaceableCollection {

    /// Applies the permutation through the collection's own swaps, which beats rebuilding.
    @inlinable mutating func apply(_ permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        precondition(permutation.minimumCount <= count, "Every offset in the cycle must be within the collection.")
        let positions: [Index] = Array(indices.prefix(permutation.minimumCount))
        permutation.forEachSwap { swapAt(positions[$0], positions[$1]) }
    }

    /// Returns a copy with the permutation applied through the collection's own swaps.
    @inlinable func applying(_ permutation: Permutation) -> Self {
        var copy: Self = self
        copy.apply(permutation)
        return copy
    }
}

public extension PermutableCollection where Self: RandomAccessCollection & RangeReplaceableCollection {

    /// Applies the permutation through the collection's own swaps, offsetting each index in O(1) and checking only each swap's larger offset against the count.
    @inlinable mutating func apply(_ permutation: Permutation) {
        guard !permutation.cycle.isEmpty else { return }
        let count: Int = self.count
        permutation.forEachSwap { root, offset in
            precondition(root < count, "Every offset in the cycle must be within the collection.")
            swapAt(index(startIndex, offsetBy: root), index(startIndex, offsetBy: offset))
        }
    }
}

public extension PermutableCollection where Self: MutableCollection & RangeReplaceableCollection {

    /// Applies the permutation in place, which beats rebuilding.
    @inlinable mutating func apply(_ permutation: Permutation) {
        rotateCyclesWalkingIndices(of: permutation)
    }

    /// Returns a copy with the permutation applied in place.
    @inlinable func applying(_ permutation: Permutation) -> Self {
        var copy: Self = self
        copy.apply(permutation)
        return copy
    }
}

public extension PermutableCollection where Self: MutableCollection & RandomAccessCollection & RangeReplaceableCollection {

    /// Applies the permutation in place without allocating.
    @inlinable mutating func apply(_ permutation: Permutation) {
        rotateCyclesOffsettingIndices(of: permutation)
    }

    /// Returns a copy with the permutation applied in place, which costs one copy and no rebuild.
    @inlinable func applying(_ permutation: Permutation) -> Self {
        var copy: Self = self
        copy.apply(permutation)
        return copy
    }
}

/// Sorts with the standard library's in-place sort, which a PermutableCollection's own `sort` would otherwise shadow.
@inlinable func standardSort<Elements: MutableCollection & RandomAccessCollection>(_ elements: inout Elements, by areInIncreasingOrder: (Elements.Element, Elements.Element) throws -> Bool) rethrows {
    try elements.sort(by: areInIncreasingOrder)
}

/// Reverses with the standard library's in-place reverse, which a PermutableCollection's own `reverse` would otherwise shadow.
@inlinable func standardReverse<Elements: MutableCollection & BidirectionalCollection>(_ elements: inout Elements) {
    elements.reverse()
}
