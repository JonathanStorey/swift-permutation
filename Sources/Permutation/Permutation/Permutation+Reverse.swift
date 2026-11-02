// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Reverse.swift
// dependencies: [Permutation/Permutation.swift]

extension Permutation {

    /// Creates the permutation that reverses `0..<count`, writing each swapped pair directly with its larger offset first.
    @inlinable init(reversing count: Int) {
        var line: [Int] = []
        line.reserveCapacity(count)
        for offset in (0..<(count / 2)).reversed() {
            line.append(count - 1 - offset)
            line.append(offset)
        }
        self.init(cycle: line)
    }
}
