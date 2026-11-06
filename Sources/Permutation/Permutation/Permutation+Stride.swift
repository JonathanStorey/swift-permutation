// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Stride.swift
// dependencies: [Permutation/Permutation+Sources.swift, Permutation/Permutation.swift]

extension Permutation {

    /// Replaces the permutation with the one that applies it `distance` times, and returns the new permutation.
    @discardableResult public mutating func advance(by distance: Int) -> Permutation {
        self = advanced(by: distance)
        return self
    }

    /// Returns the permutation that applies this one `distance` times, so a negative distance applies the inverse.
    ///
    /// Within a cycle of length `L`, the element at position `j` lands at position `j + distance` modulo `L`, so the power's sources are written straight from each cycle of the line and turned back into Foata form in one pass, which splits each cycle into `gcd(L, distance)` cycles without sorting. Offsets scattered far apart fall back to splitting cycles one by one.
    public func advanced(by distance: Int) -> Permutation {
        let count: Int = minimumCount
        guard Permutation.prefersDense(count: count, support: cycle.count) else { return advancedSparse(by: distance) }
        var sources: [Int] = Array(0..<count)
        var blockStart: Int = 0
        var root: Int = -1
        for position in 0...cycle.count {
            if position == cycle.count || cycle[position] > root {
                let length: Int = position - blockStart
                if length > 1 {
                    let step: Int = (distance % length + length) % length
                    for index in 0..<length {
                        let target: Int = index + step < length ? index + step : index + step - length
                        sources[cycle[blockStart + target]] = cycle[blockStart + index]
                    }
                }
                if position < cycle.count {
                    root = cycle[position]
                    blockStart = position
                }
            }
        }
        return Permutation(sources: sources)
    }

    /// Returns the power by splitting each cycle of length `L` into `gcd(L, distance)` cycles that step `distance` offsets at a time, for offsets scattered far apart.
    func advancedSparse(by distance: Int) -> Permutation {
        var advanced: [[Int]] = []
        for cycle in cycles {
            let length: Int = cycle.count
            let step: Int = (distance % length + length) % length
            guard step != 0 else { continue }
            var divisor: Int = length
            var remainder: Int = step
            while remainder != 0 {
                (divisor, remainder) = (remainder, divisor % remainder)
            }
            for start in 0..<divisor {
                advanced.append((0..<(length / divisor)).map { cycle[(start + $0 * step) % length] })
            }
        }
        return Permutation(cycles: advanced)
    }
}
