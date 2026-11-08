// repository: https://github.com/JonathanStorey/swift-permutation
// path: main.swift
// dependencies: [Collections/IdentifiedSet.swift, Collections/PermutableCollection.swift, IdentifiedComparison.swift, Record.swift]

import Permutation

/// Keeps the optimizer from discarding a result.
@inline(never) func blackHole<T>(_ value: T) {
    withExtendedLifetime(value) {}
}

/// Returns the median time of running the body on a fresh, uniquely owned copy made outside the timed region.
func median<C>(iterations: Int, make: () -> C, _ body: (inout C) -> Void) -> Duration {
    let clock: ContinuousClock = ContinuousClock()
    var samples: [Duration] = []
    samples.reserveCapacity(iterations)
    for _ in 0..<iterations {
        var subject: C = make()
        let elapsed: Duration = clock.measure { body(&subject) }
        blackHole(subject)
        samples.append(elapsed)
    }
    samples.sort()
    return samples[samples.count / 2]
}

/// The duration in microseconds.
func microseconds(_ duration: Duration) -> Double {
    let (seconds, attoseconds): (Int64, Int64) = duration.components
    return Double(seconds) * 1_000_000 + Double(attoseconds) / 1_000_000_000_000
}

/// The value rounded to one decimal place.
func rounded(_ value: Double) -> String {
    String((value * 10).rounded() / 10)
}

/// A table cell with the time and how many times faster or slower it is than the permutable time.
func cell(_ time: Double?, against permutable: Double) -> String {
    guard let time: Double = time else { return "—" }
    let comparison: String = time <= permutable ? "\(rounded(permutable / time))× faster" : "\(rounded(time / permutable))× slower"
    return "\(rounded(time)) µs (\(comparison))"
}

let sizes: [Int] = [1_000, 100_000]
print("Median time per operation, with each MutableCollection and RangeReplaceableCollection time compared to the PermutableCollection time.")
print("")
print("| Operation | Count | PermutableCollection | MutableCollection | RangeReplaceableCollection |")
print("|---|---:|---:|---:|---:|")
for size in sizes {
    var generator: SeededGenerator = SeededGenerator(state: 42)
    let base: [Int] = Array(0..<size).shuffled(using: &generator)
    let iterations: Int = max(11, 2_000_000 / size)
    for comparison in Comparison.all {
        var expected: Cards = Cards(elements: base)
        comparison.permutable(&expected)
        if let mutable: (inout [Int]) -> Void = comparison.mutable, comparison.mutableMatches {
            var actual: [Int] = base
            mutable(&actual)
            precondition(actual == expected.elements, "\(comparison.operation) through MutableCollection gave a different order.")
        }
        if let rangeReplaceable: (inout [Int]) -> Void = comparison.rangeReplaceable {
            var actual: [Int] = base
            rangeReplaceable(&actual)
            precondition(actual == expected.elements, "\(comparison.operation) through RangeReplaceableCollection gave a different order.")
        }
        let permutable: Double = microseconds(median(iterations: iterations, make: { Cards(elements: base.map { $0 }) }, comparison.permutable))
        let mutable: Double? = comparison.mutable.map { body in microseconds(median(iterations: iterations, make: { base.map { $0 } }, body)) }
        let rangeReplaceable: Double? = comparison.rangeReplaceable.map { body in microseconds(median(iterations: iterations, make: { base.map { $0 } }, body)) }
        print("| `\(comparison.operation)` | \(size) | \(rounded(permutable)) µs | \(cell(mutable, against: permutable)) | \(cell(rangeReplaceable, against: permutable)) |")
    }
}

print("")
print("Median time per operation on `Record` values (UUID id, 64-byte payload), with each array time compared to the IdentifiedSet time. \"Array + id index\" rebuilds a `[UUID: Int]` position index after each reorder, which is what an array needs to keep lookups by id O(1).")
print("")
print("| Operation | Count | IdentifiedSet | Array | Array + id index |")
print("|---|---:|---:|---:|---:|")
for size in sizes {
    var generator: SeededGenerator = SeededGenerator(state: 42)
    let records: [Record] = (0..<size).map(Record.init(rank:)).shuffled(using: &generator)
    let iterations: Int = max(11, 2_000_000 / size)
    for comparison in IdentifiedComparison.all {
        var expected: IdentifiedSet<Record> = IdentifiedSet(records)
        comparison.identified(&expected)
        var actual: [Record] = records
        comparison.array(&actual)
        precondition(actual.map(\.id) == expected.map(\.id), "\(comparison.operation) on an array gave a different order.")
        let identified: Double = microseconds(median(iterations: iterations, make: { IdentifiedSet(records) }, comparison.identified))
        let array: Double = microseconds(median(iterations: iterations, make: { records.map { $0 } }, comparison.array))
        let indexed: Double? = comparison.reindexes ? microseconds(median(iterations: iterations, make: { records.map { $0 } }) { array in
            comparison.array(&array)
            blackHole(IdentifiedComparison.index(array))
        }) : nil
        print("| `\(comparison.operation)` | \(size) | \(rounded(identified)) µs | \(cell(array, against: identified)) | \(cell(indexed, against: identified)) |")
    }
}

print("")
print("Median time per operation on `Record` values (UUID id, 64-byte payload), with each array time compared to the Arrangement time.")
print("")
print("| Operation | Count | Arrangement | Array |")
print("|---|---:|---:|---:|")
for size in [16_384, 100_000] {
    var generator: SeededGenerator = SeededGenerator(state: 42)
    let records: [Record] = (0..<size).map(Record.init(rank:)).shuffled(using: &generator)
    let iterations: Int = max(11, 2_000_000 / size)
    let comparisons: [(String, (inout Arrangement<Record>) -> Void, (inout [Record]) -> Void)] = [
        ("sort(by:)", { $0.sort { $0.rank < $1.rank } }, { $0.sort { $0.rank < $1.rank } }),
        ("shuffle()", { var g: SeededGenerator = SeededGenerator(state: 7); $0.shuffle(using: &g) }, { var g: SeededGenerator = SeededGenerator(state: 7); $0.shuffle(using: &g) }),
        ("reverse()", { $0.reverse() }, { $0.reverse() }),
        ("apply(_:) undo of a sort", { arrangement in let p: Permutation = arrangement.sort { $0.rank < $1.rank }; arrangement.apply(p.inverted) }, { array in let p: Permutation = Permutation(sorting: array.map(\.rank)); array.apply(p); array.apply(p.inverted) }),
    ]
    for (operation, arranged, array) in comparisons {
        var expected: Arrangement<Record> = Arrangement(records)
        arranged(&expected)
        var actual: [Record] = records
        array(&actual)
        precondition(actual.map(\.id) == expected.map(\.id), "\(operation) on an array gave a different order.")
        let arrangement: Double = microseconds(median(iterations: iterations, make: { Arrangement(records) }, arranged))
        let plain: Double = microseconds(median(iterations: iterations, make: { records.map { $0 } }, array))
        print("| `\(operation)` | \(size) | \(rounded(arrangement)) µs | \(cell(plain, against: arrangement)) |")
    }
}

printReorderTable()
