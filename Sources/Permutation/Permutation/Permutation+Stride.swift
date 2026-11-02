// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Stride.swift
// dependencies: [Permutation/Permutation.swift]

extension Permutation {

    /// Replaces the permutation with the one that applies it `distance` times, and returns the new permutation.
    @discardableResult public mutating func advance(by distance: Int) -> Permutation {
        self = advanced(by: distance)
        return self
    }

    /// Returns the permutation that applies this one `distance` times, splitting each cycle of length `L` into `gcd(L, distance)` cycles that step `distance` offsets at a time, so a negative distance applies the inverse.
    public func advanced(by distance: Int) -> Permutation {
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
