// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/Permutation+Rank.swift
// dependencies: []

extension Permutation {

    /// A permutation's place among all permutations: its Lehmer code, read as a whole number in the factorial number system.
    ///
    /// The digit worth `k!` lies in `0...k`, so every number has one spelling, and the permutations of `n` offsets take exactly the places below `n!`. Because the digits grow with the number, a rank never overflows: the place of a permutation of a thousand offsets is as easy to hold and add to as the place of one of three.
    ///
    /// A rank is signed so it can measure distances in both directions, as `Strideable` asks of a stride. It is `Strideable` itself too, with itself as its stride, so `stride(from: 0, to: 24, by: 1)` counts through the places of every order of four offsets. Addition and subtraction carry digit by digit in O(n) for n digits. Multiplication, which `Strideable` requires but stepping never uses, doubles and adds in O(n² log n).
    public struct Rank: Sendable, Hashable {

        /// The digits from the one worth `1!` upward, so `digits[i]` is worth `(i + 1)!` and lies in `0...(i + 1)`, with no zeros at the end.
        public private(set) var digits: [Int]

        /// Whether the rank is below zero. Zero is never negative.
        public private(set) var isNegative: Bool

        /// Creates a rank from its digits, starting with the one worth `1!`, each at most its place.
        public init(digits: [Int], isNegative: Bool = false) {
            for (index, digit) in digits.enumerated() {
                precondition(digit >= 0 && digit <= index + 1, "The digit worth k! must lie in 0...k.")
            }
            self.init(unchecked: digits, isNegative: isNegative)
        }

        /// Creates a rank from digits already in range, dropping zeros at the end.
        @usableFromInline init(unchecked digits: [Int], isNegative: Bool) {
            var trimmed: [Int] = digits
            while trimmed.last == 0 { trimmed.removeLast() }
            self.digits = trimmed
            self.isNegative = isNegative && !trimmed.isEmpty
        }

        /// Creates the rank for the integer, dividing by 2, 3, 4 and so on to read off each digit.
        public init<Source: BinaryInteger>(_ source: Source) {
            var remaining: Source.Magnitude = source.magnitude
            var digits: [Int] = []
            var base: Int = 2
            while remaining != 0 {
                let divisor: Source.Magnitude = Source.Magnitude(base)
                digits.append(Int(remaining % divisor))
                remaining /= divisor
                base += 1
            }
            self.init(unchecked: digits, isNegative: source < 0)
        }
    }
}

// MARK: - Digit arithmetic

extension Permutation.Rank {

    /// Adds two magnitudes, carrying at most one into each next place.
    @usableFromInline static func add(_ lhs: [Int], _ rhs: [Int]) -> [Int] {
        var sum: [Int] = []
        sum.reserveCapacity(Swift.max(lhs.count, rhs.count) + 1)
        var carry: Int = 0
        var index: Int = 0
        while index < lhs.count || index < rhs.count || carry > 0 {
            let base: Int = index + 2
            let digit: Int = (index < lhs.count ? lhs[index] : 0) + (index < rhs.count ? rhs[index] : 0) + carry
            carry = digit >= base ? 1 : 0
            sum.append(digit - carry * base)
            index += 1
        }
        return sum
    }

    /// Subtracts the smaller magnitude from the larger, borrowing at most one from each next place.
    @usableFromInline static func subtract(_ larger: [Int], _ smaller: [Int]) -> [Int] {
        var difference: [Int] = larger
        var borrow: Int = 0
        for index in difference.indices {
            var digit: Int = difference[index] - (index < smaller.count ? smaller[index] : 0) - borrow
            borrow = digit < 0 ? 1 : 0
            digit += borrow * (index + 2)
            difference[index] = digit
        }
        return difference
    }

    /// Compares two trimmed magnitudes, returning -1, 0 or 1.
    @usableFromInline static func compare(_ lhs: [Int], _ rhs: [Int]) -> Int {
        if lhs.count != rhs.count { return lhs.count < rhs.count ? -1 : 1 }
        for index in lhs.indices.reversed() where lhs[index] != rhs[index] {
            return lhs[index] < rhs[index] ? -1 : 1
        }
        return 0
    }

    /// Halves a magnitude in place from the top place down and returns the remainder, 0 or 1. A remainder carried into a place is worth `place + 1` of its digit, since `(place + 1)! = (place + 1) · place!`.
    @usableFromInline static func halve(_ digits: inout [Int]) -> Int {
        var remainder: Int = 0
        for index in digits.indices.reversed() {
            let current: Int = digits[index] + remainder * (index + 2)
            digits[index] = current / 2
            remainder = current % 2
        }
        while digits.last == 0 { digits.removeLast() }
        return remainder
    }
}

// MARK: - Numbers

extension Permutation.Rank: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension Permutation.Rank: Comparable {

    /// Two ranks are equal when they have the same sign and digits. Written out so that `Strideable`'s default, which goes through `distance(to:)`, never stands in.
    public static func == (lhs: Permutation.Rank, rhs: Permutation.Rank) -> Bool {
        lhs.isNegative == rhs.isNegative && lhs.digits == rhs.digits
    }

    public static func < (lhs: Permutation.Rank, rhs: Permutation.Rank) -> Bool {
        if lhs.isNegative != rhs.isNegative { return lhs.isNegative }
        let order: Int = compare(lhs.digits, rhs.digits)
        return lhs.isNegative ? order > 0 : order < 0
    }
}

extension Permutation.Rank: SignedNumeric {

    public init?<Source: BinaryInteger>(exactly source: Source) {
        self.init(source)
    }

    /// The rank without its sign.
    public var magnitude: Permutation.Rank {
        Permutation.Rank(unchecked: digits, isNegative: false)
    }

    public static func + (lhs: Permutation.Rank, rhs: Permutation.Rank) -> Permutation.Rank {
        if lhs.isNegative == rhs.isNegative {
            return Permutation.Rank(unchecked: add(lhs.digits, rhs.digits), isNegative: lhs.isNegative)
        }
        switch compare(lhs.digits, rhs.digits) {
        case 0: return 0
        case 1: return Permutation.Rank(unchecked: subtract(lhs.digits, rhs.digits), isNegative: lhs.isNegative)
        default: return Permutation.Rank(unchecked: subtract(rhs.digits, lhs.digits), isNegative: rhs.isNegative)
        }
    }

    public static func - (lhs: Permutation.Rank, rhs: Permutation.Rank) -> Permutation.Rank {
        var negated: Permutation.Rank = rhs
        negated.negate()
        return lhs + negated
    }

    public static func += (lhs: inout Permutation.Rank, rhs: Permutation.Rank) {
        lhs = lhs + rhs
    }

    public static func -= (lhs: inout Permutation.Rank, rhs: Permutation.Rank) {
        lhs = lhs - rhs
    }

    /// Multiplies by doubling and adding, reading the right side's bits by halving it.
    public static func * (lhs: Permutation.Rank, rhs: Permutation.Rank) -> Permutation.Rank {
        guard !lhs.digits.isEmpty && !rhs.digits.isEmpty else { return 0 }
        var product: [Int] = []
        var addend: [Int] = lhs.digits
        var multiplier: [Int] = rhs.digits
        while !multiplier.isEmpty {
            if halve(&multiplier) == 1 { product = add(product, addend) }
            if !multiplier.isEmpty { addend = add(addend, addend) }
        }
        return Permutation.Rank(unchecked: product, isNegative: lhs.isNegative != rhs.isNegative)
    }

    public static func *= (lhs: inout Permutation.Rank, rhs: Permutation.Rank) {
        lhs = lhs * rhs
    }

    public mutating func negate() {
        isNegative = !isNegative && !digits.isEmpty
    }
}

public extension Int {

    /// The rank as an `Int`, or nil when it does not fit, which happens for the places of permutations that move offsets past the first 20. Read with Horner's rule from the top digit down.
    init?(exactly code: Permutation.Rank) {
        var value: Int = 0
        for index in code.digits.indices.reversed() {
            let (sum, sumOverflow): (Int, Bool) = value.addingReportingOverflow(code.digits[index])
            let (product, productOverflow): (Int, Bool) = sum.multipliedReportingOverflow(by: index + 1)
            guard !sumOverflow && !productOverflow else { return nil }
            value = product
        }
        self = code.isNegative ? -value : value
    }
}

extension Permutation.Rank: Strideable {

    /// The rank `distance` places later.
    public func advanced(by distance: Permutation.Rank) -> Permutation.Rank {
        self + distance
    }

    /// The number of places from this rank to the other.
    public func distance(to other: Permutation.Rank) -> Permutation.Rank {
        other - self
    }
}

extension Permutation.Rank: CustomStringConvertible {

    /// The decimal value when it fits in an `Int`, otherwise the digits.
    public var description: String {
        if let value: Int = Int(exactly: self) { return String(value) }
        return "\(isNegative ? "-" : "")Rank(digits: \(digits))"
    }
}

extension Permutation.Rank: Codable {

    private enum CodingKeys: String, CodingKey {
        case digits
        case isNegative
    }

    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        let digits: [Int] = try container.decode([Int].self, forKey: .digits)
        let isNegative: Bool = try container.decodeIfPresent(Bool.self, forKey: .isNegative) ?? false
        for (index, digit) in digits.enumerated() where digit < 0 || digit > index + 1 {
            throw DecodingError.dataCorruptedError(forKey: .digits, in: container, debugDescription: "The digit worth k! must lie in 0...k.")
        }
        self.init(unchecked: digits, isNegative: isNegative)
    }

    public func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(digits, forKey: .digits)
        if isNegative { try container.encode(isNegative, forKey: .isNegative) }
    }
}
