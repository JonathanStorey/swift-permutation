// repository: https://github.com/JonathanStorey/swift-permutation
// path: Collections/Collection+Permutation.swift
// dependencies: [Permutation/Permutation.swift]

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

    /// Rotates each cycle in place through one carried element, finding each index in O(1) and allocating nothing.
    @inlinable mutating func rotateCyclesOffsettingIndices(of permutation: Permutation) where Self: RandomAccessCollection {
        precondition(permutation.minimumCount <= count, "Every offset in the cycle must be within the collection.")
        let line: [Int] = permutation.cycle
        guard let first: Int = line.first else { return }
        let base: Index = startIndex
        var start: Int = first
        var carried: Element = self[index(base, offsetBy: first)]
        for offset in line.dropFirst() {
            if offset > start {
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
