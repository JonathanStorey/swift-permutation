// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Rotate.swift
// dependencies: [Permutation.swift]

extension Permutation {

    /// Creates the permutation that moves the element at offset `shift` to the front of `0..<count`, writing one cycle per residue class modulo the greatest common divisor.
    @inlinable init(rotating count: Int, by shift: Int) {
        guard count > 0, shift % count != 0 else {
            self.init(cycle: [])
            return
        }
        let step: Int = (shift % count + count) % count
        var divisor: Int = count
        var remainder: Int = step
        while remainder != 0 {
            (divisor, remainder) = (remainder, divisor % remainder)
        }
        var line: [Int] = []
        line.reserveCapacity(count)
        for start in (count - divisor)..<count {
            var offset: Int = start
            repeat {
                line.append(offset)
                offset = offset >= step ? offset - step : offset + count - step
            } while offset != start
        }
        self.init(cycle: line)
    }
}
