// repository: https://github.com/JonathanStorey/swift-permutation
// path: ReorderTable.swift
// dependencies: [Collections/Arrangement.swift, Collections/IdentifiedSet.swift, Collections/PermutableSet.swift, Record.swift, SeededGenerator.swift]

import Foundation
import IdentifiedCollections
import OrderedCollections
import Permutation

/// One reorder timed on a permutable collection and on the collection it replaces, after checking that both give the same order.
func speedup<Ours, Theirs, Key: Equatable>(
    iterations: Int,
    ours make: () -> Ours, _ oursBody: (inout Ours) -> Void, keys oursKeys: (Ours) -> [Key],
    theirs makeTheirs: () -> Theirs, _ theirsBody: (inout Theirs) -> Void, keys theirsKeys: (Theirs) -> [Key],
    _ operation: String
) -> Double {
    var expected: Ours = make()
    oursBody(&expected)
    var actual: Theirs = makeTheirs()
    theirsBody(&actual)
    // Shuffles draw from the same seed but may consume it differently, so only their contents are compared.
    if operation.hasPrefix("Shuffle") {
        precondition(oursKeys(expected).count == theirsKeys(actual).count, "\(operation) changed the count.")
    } else {
        precondition(oursKeys(expected) == theirsKeys(actual), "\(operation) gave different orders.")
    }
    let ours: Double = microseconds(median(iterations: iterations, make: make, oursBody))
    let theirs: Double = microseconds(median(iterations: iterations, make: makeTheirs, theirsBody))
    print("<!-- \(operation): \(rounded(ours)) µs vs \(rounded(theirs)) µs -->")
    return theirs / ours
}

/// Prints one table of reorder speedups at 16,384 elements: Arrangement against Array, PermutableSet against OrderedSet, and IdentifiedSet against IdentifiedArray.
func printReorderTable() {
    let size: Int = 16_384
    let iterations: Int = 201
    var generator: SeededGenerator = SeededGenerator(state: 42)
    let records: [Record] = (0..<size).map(Record.init(rank:)).shuffled(using: &generator)
    let numbers: [Int] = Array(0..<size).shuffled(using: &generator)
    let pivot: Int = size / 3

    typealias Row = (String, (inout Arrangement<Record>) -> Void, (inout [Record]) -> Void, (inout PermutableSet<Int>) -> Void, (inout OrderedSet<Int>) -> Void, (inout IdentifiedSet<Record>) -> Void, (inout IdentifiedArray<UUID, Record>) -> Void)
    let rows: [Row] = [
        ("Sort",
         { $0.sort { $0.rank < $1.rank } }, { $0.sort { $0.rank < $1.rank } },
         { $0.sort() }, { $0.sort() },
         { $0.sort { $0.rank < $1.rank } }, { $0.sort { $0.rank < $1.rank } }),
        ("Shuffle",
         { var g: SeededGenerator = SeededGenerator(state: 7); $0.shuffle(using: &g) }, { var g: SeededGenerator = SeededGenerator(state: 7); $0.shuffle(using: &g) },
         { var g: SeededGenerator = SeededGenerator(state: 7); $0.shuffle(using: &g) }, { var g: SeededGenerator = SeededGenerator(state: 7); $0.shuffle(using: &g) },
         { var g: SeededGenerator = SeededGenerator(state: 7); $0.shuffle(using: &g) }, { var g: SeededGenerator = SeededGenerator(state: 7); $0.shuffle(using: &g) }),
        ("Reverse",
         { $0.reverse() }, { $0.reverse() },
         { $0.reverse() }, { $0.reverse() },
         { $0.reverse() }, { $0.reverse() }),
        ("Move first to last",
         { $0.move(from: 0, to: $0.count - 1) }, { $0.append($0.remove(at: 0)) },
         { $0.move(from: 0, to: $0.count - 1) }, { $0.append($0.remove(at: 0)) },
         { $0.move(from: 0, to: $0.count - 1) }, { $0.move(fromOffsets: IndexSet(integer: 0), toOffset: $0.count) }),
        ("Rotate by a third",
         { $0.rotate(toStartAt: pivot) }, { $0 = Array($0[pivot...] + $0[..<pivot]) },
         { $0.rotate(toStartAt: pivot) }, { $0 = OrderedSet(uncheckedUniqueElements: $0.elements[pivot...] + $0.elements[..<pivot]) },
         { $0.rotate(toStartAt: pivot) }, { $0.move(fromOffsets: IndexSet(integersIn: 0..<pivot), toOffset: $0.count) }),
    ]

    print("")
    print("Speedups at \(size) elements, each the median of \(iterations) runs. Arrangement and IdentifiedSet hold `Record` values, PermutableSet holds `Int` values.")
    print("")
    print("| Reorder | Arrangement vs Array | PermutableSet vs OrderedSet | IdentifiedSet vs IdentifiedArray |")
    print("| --- | ---: | ---: | ---: |")
    for (name, arranged, array, permutable, ordered, identified, identifiedArray) in rows {
        let first: Double = speedup(iterations: iterations,
            ours: { Arrangement(records) }, arranged, keys: { $0.map(\.id) },
            theirs: { records.map { $0 } }, array, keys: { $0.map(\.id) }, "\(name), Arrangement")
        let second: Double = speedup(iterations: iterations,
            ours: { PermutableSet(numbers) }, permutable, keys: { Array($0) },
            theirs: { OrderedSet(numbers) }, ordered, keys: { Array($0) }, "\(name), PermutableSet")
        let third: Double = speedup(iterations: iterations,
            ours: { IdentifiedSet(records) }, identified, keys: { $0.map(\.id) },
            theirs: { IdentifiedArray(uniqueElements: records) }, identifiedArray, keys: { $0.map(\.id) }, "\(name), IdentifiedSet")
        print("| \(name) | \(rounded(first))× | \(rounded(second))× | \(rounded(third))× |")
    }

    var shuffled: Arrangement<Record> = Arrangement(records)
    var g: SeededGenerator = SeededGenerator(state: 9)
    let reorder: Permutation = shuffled.shuffle(using: &g)
    let repeats: Int = 1_000
    let power: Double = speedup(iterations: 21,
        ours: { Arrangement(records) }, { $0.apply(reorder.raised(to: repeats)) }, keys: { $0.map(\.id) },
        theirs: { records.map { $0 } }, { array in for _ in 0..<repeats { array.apply(reorder) } }, keys: { $0.map(\.id) }, "Repeat a reorder \(repeats) times")
    print("")
    print("Repeating one reorder \(repeats) times: raising the permutation to the \(repeats)th power and applying it once is \(rounded(power))× faster than applying it \(repeats) times to an array.")
}
