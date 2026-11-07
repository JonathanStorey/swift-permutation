// repository: https://github.com/JonathanStorey/swift-permutation
// path: Permutation/LehmerCode.swift
// dependencies: []

/// A whole number written in the factorial number system, which is how a permutation's place among all permutations is counted.
///
/// The digit worth `k!` lies in `0...k`, so every number has one spelling, and the permutations of `n` offsets take exactly the places below `n!`. Because the digits grow with the number, a code never overflows: the place of a permutation of a thousand offsets is as easy to hold and add to as the place of one of three.
///
/// A code is signed so it can measure distances in both directions, as `Strideable` asks of its stride. Addition and subtraction carry digit by digit in O(n) for n digits. Multiplication, which `Strideable` requires but stepping never uses, doubles and adds in O(n² log n).
public struct LehmerCode: Sendable, Hashable {

    /// The digits from the one worth `1!` upward, so `digits[i]` is worth `(i + 1)!` and lies in `0...(i + 1)`, with no zeros at the end.
    public private(set) var digits: [Int]

    /// Whether the code is below zero. Zero is never negative.
    public private(set) var isNegative: Bool

    /// Creates a code from its digits, starting with the one worth `1!`, each at most its place.
    public init(digits: [Int], isNegative: Bool = false) {
        for (index, digit) in digits.enumerated() {
            precondition(digit >= 0 && digit <= index + 1, "The digit worth k! must lie in 0...k.")
        }
        self.init(unchecked: digits, isNegative: isNegative)
    }

    /// Creates a code from digits already in range, dropping zeros at the end.
    @usableFromInline init(unchecked digits: [Int], isNegative: Bool) {
        var trimmed: [Int] = digits
        while trimmed.last == 0 { trimmed.removeLast() }
        self.digits = trimmed
        self.isNegative = isNegative && !trimmed.isEmpty
    }

    /// Creates the code for the integer, dividing by 2, 3, 4 and so on to read off each digit.
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

// MARK: - Digit arithmetic

extension LehmerCode {

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

extension LehmerCode: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension LehmerCode: Comparable {

    public static func < (lhs: LehmerCode, rhs: LehmerCode) -> Bool {
        if lhs.isNegative != rhs.isNegative { return lhs.isNegative }
        let order: Int = compare(lhs.digits, rhs.digits)
        return lhs.isNegative ? order > 0 : order < 0
    }
}

extension LehmerCode: SignedNumeric {

    public init?<Source: BinaryInteger>(exactly source: Source) {
        self.init(source)
    }

    /// The code without its sign.
    public var magnitude: LehmerCode {
        LehmerCode(unchecked: digits, isNegative: false)
    }

    public static func + (lhs: LehmerCode, rhs: LehmerCode) -> LehmerCode {
        if lhs.isNegative == rhs.isNegative {
            return LehmerCode(unchecked: add(lhs.digits, rhs.digits), isNegative: lhs.isNegative)
        }
        switch compare(lhs.digits, rhs.digits) {
        case 0: return 0
        case 1: return LehmerCode(unchecked: subtract(lhs.digits, rhs.digits), isNegative: lhs.isNegative)
        default: return LehmerCode(unchecked: subtract(rhs.digits, lhs.digits), isNegative: rhs.isNegative)
        }
    }

    public static func - (lhs: LehmerCode, rhs: LehmerCode) -> LehmerCode {
        var negated: LehmerCode = rhs
        negated.negate()
        return lhs + negated
    }

    public static func += (lhs: inout LehmerCode, rhs: LehmerCode) {
        lhs = lhs + rhs
    }

    public static func -= (lhs: inout LehmerCode, rhs: LehmerCode) {
        lhs = lhs - rhs
    }

    /// Multiplies by doubling and adding, reading the right side's bits by halving it.
    public static func * (lhs: LehmerCode, rhs: LehmerCode) -> LehmerCode {
        guard !lhs.digits.isEmpty && !rhs.digits.isEmpty else { return 0 }
        var product: [Int] = []
        var addend: [Int] = lhs.digits
        var multiplier: [Int] = rhs.digits
        while !multiplier.isEmpty {
            if halve(&multiplier) == 1 { product = add(product, addend) }
            if !multiplier.isEmpty { addend = add(addend, addend) }
        }
        return LehmerCode(unchecked: product, isNegative: lhs.isNegative != rhs.isNegative)
    }

    public static func *= (lhs: inout LehmerCode, rhs: LehmerCode) {
        lhs = lhs * rhs
    }

    public mutating func negate() {
        isNegative = !isNegative && !digits.isEmpty
    }
}

public extension Int {

    /// The code as an `Int`, or nil when it does not fit, which happens for the places of permutations that move offsets past the first 20. Read with Horner's rule from the top digit down.
    init?(exactly code: LehmerCode) {
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

extension LehmerCode: CustomStringConvertible {

    /// The decimal value when it fits in an `Int`, otherwise the digits.
    public var description: String {
        if let value: Int = Int(exactly: self) { return String(value) }
        return "\(isNegative ? "-" : "")LehmerCode(digits: \(digits))"
    }
}

extension LehmerCode: Codable {

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
