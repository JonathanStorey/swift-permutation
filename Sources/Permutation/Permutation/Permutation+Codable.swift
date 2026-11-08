// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Codable.swift
// dependencies: [Permutation/Permutation.swift]

// A permutation encodes as its Foata line, a plain array of the moved offsets, which is both the compact form and exactly what it stores.
//
// - Decoding checks the line before trusting it: every offset non-negative and listed once, and no cycle of a single offset, which the line never holds. A line that fails throws `DecodingError.dataCorrupted` instead of building a broken value.

extension Permutation: Codable {

    /// Encodes the Foata line as a plain array, such as `[2, 0, 5, 3, 4]` for the cycles `(2 0)(5 3 4)`.
    public func encode(to encoder: any Encoder) throws {
        var container: any SingleValueEncodingContainer = encoder.singleValueContainer()
        try container.encode(cycle)
    }

    /// Decodes a Foata line, throwing when an offset is negative or repeated, or when a cycle would hold a single offset.
    public init(from decoder: any Decoder) throws {
        let container: any SingleValueDecodingContainer = try decoder.singleValueContainer()
        let line: [Int] = try container.decode([Int].self)
        guard Permutation.isFoataLine(line) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "A permutation's line must list distinct non-negative offsets, each cycle holding at least two.")
        }
        self.init(cycle: line)
    }

    /// Whether the line is a valid Foata line: distinct non-negative offsets, where each offset larger than every one before it starts a cycle of at least two.
    static func isFoataLine(_ line: [Int]) -> Bool {
        var seen: Set<Int> = []
        var root: Int = -1
        var length: Int = 0
        for offset in line {
            guard offset >= 0, seen.insert(offset).inserted else { return false }
            if offset > root {
                if root >= 0 && length < 2 { return false }
                root = offset
                length = 1
            } else {
                length += 1
            }
        }
        return root < 0 || length >= 2
    }
}
