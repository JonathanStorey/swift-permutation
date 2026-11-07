// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Reverse.swift
// dependencies: [Permutation/Permutation.swift]

extension Permutation {

    /// Creates the permutation that reverses the first `count` offsets, as `applying` it to a collection of that length would. It writes each swapped pair directly with its larger offset first.
    @inlinable public init(reversing count: Int) {
        var line: [Int] = []
        line.reserveCapacity(count)
        for offset in (0..<(count / 2)).reversed() {
            line.append(count - 1 - offset)
            line.append(offset)
        }
        self.init(cycle: line)
    }
}
