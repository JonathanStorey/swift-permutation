// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation+Move.swift
// dependencies: [Permutation.swift]

extension Permutation {

    /// Creates the single cycle that moves the element at `source` to `destination` within `0..<count`, shifting the elements between them one step toward `source`.
    @inlinable init(moving source: Int, to destination: Int, count: Int) {
        precondition((0..<count).contains(source) && (0..<count).contains(destination), "Both offsets must be within the collection.")
        if source < destination {
            self.init(cycle: Array((source...destination).reversed()))
        } else if source > destination {
            self.init(cycle: [source] + Array(destination..<source))
        } else {
            self.init(cycle: [])
        }
    }
}
