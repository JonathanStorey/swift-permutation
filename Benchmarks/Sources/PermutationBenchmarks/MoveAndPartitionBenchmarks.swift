// repository: https://github.com/JonathanStorey/swift-permutation
// path: MoveAndPartitionBenchmarks.swift
// dependencies: [Collections/PermutableCollection+DiscardedResult.swift, Record.swift]

import CollectionsBenchmark
import Foundation
import IdentifiedCollections
import OrderedCollections
import Permutation

extension Benchmark {

    /// Adds a multi-selection move and a partition for every pair. Each task builds a fresh, uniquely owned collection outside the timed region and times only the reorder.
    ///
    /// - The move sends every tenth element to the front, as dragging a multi-row selection in SwiftUI does. Array, OrderedSet and OrderedDictionary have no `move(fromOffsets:toOffset:)` outside SwiftUI, so their tasks split the elements into the moved and the rest and rebuild.
    /// - The partition sends the records with an odd rank to the back. This package's `stablePartition(by:)` keeps both groups in their original order. The other collections' `partition(by:)` is not stable, so it does less work for a weaker result.
    mutating func addMoveAndPartitionBenchmarks() {

        func everyTenth(_ count: Int) -> StrideTo<Int> { stride(from: 0, to: count, by: 10) }
        let isOdd: (Record) -> Bool = { !$0.rank.isMultiple(of: 2) }

        func split<Element>(_ elements: some Sequence<Element>) -> [Element] {
            var moved: [Element] = []
            var rest: [Element] = []
            for (offset, element) in elements.enumerated() {
                if offset.isMultiple(of: 10) { moved.append(element) } else { rest.append(element) }
            }
            return moved + rest
        }

        // MARK: Move every tenth to the front

        add(title: "Arrangement<Record> move every tenth to the front", input: [Record].self) { input in
            return { timer in
                var arrangement: Arrangement<Record> = Arrangement(input)
                timer.measure { arrangement.move(fromOffsets: everyTenth(arrangement.count), toOffset: 0) }
                blackHole(arrangement)
            }
        }
        add(title: "Array<Record> move every tenth to the front", input: [Record].self) { input in
            return { timer in
                var array: [Record] = input.map { $0 }
                timer.measure { array = split(array) }
                blackHole(array)
            }
        }

        add(title: "PermutableSet<Record> move every tenth to the front", input: [Record].self) { input in
            return { timer in
                var set: PermutableSet<Record> = PermutableSet(input)
                timer.measure { set.move(fromOffsets: everyTenth(set.count), toOffset: 0) }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Record> move every tenth to the front", input: [Record].self) { input in
            return { timer in
                var set: OrderedSet<Record> = OrderedSet(input)
                timer.measure { set = OrderedSet(uncheckedUniqueElements: split(set.elements)) }
                blackHole(set)
            }
        }

        add(title: "PermutableDictionary<Int, Record> move every tenth to the front", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.move(fromOffsets: everyTenth(dictionary.count), toOffset: 0) }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> move every tenth to the front", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
                timer.measure {
                    let keys: [Int] = split(dictionary.keys)
                    let values: [Record] = split(dictionary.values)
                    dictionary = OrderedDictionary(uncheckedUniqueKeys: keys, values: values)
                }
                blackHole(dictionary)
            }
        }

        add(title: "IdentifiedSet<Record> move every tenth to the front", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                timer.measure { set.move(fromOffsets: everyTenth(set.count), toOffset: 0) }
                blackHole(set)
            }
        }
        add(title: "IdentifiedArray<Record> move every tenth to the front", input: [Record].self) { input in
            return { timer in
                var array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
                timer.measure { array.move(fromOffsets: IndexSet(everyTenth(array.count)), toOffset: 0) }
                blackHole(array)
            }
        }

        // MARK: Partition by odd rank (stable here, unstable in the others)

        add(title: "Arrangement<Record> partition by odd rank", input: [Record].self) { input in
            return { timer in
                var arrangement: Arrangement<Record> = Arrangement(input)
                timer.measure { blackHole(arrangement.stablePartition(by: isOdd)) }
                blackHole(arrangement)
            }
        }
        add(title: "Array<Record> partition by odd rank", input: [Record].self) { input in
            return { timer in
                var array: [Record] = input.map { $0 }
                timer.measure { blackHole(array.partition(by: isOdd)) }
                blackHole(array)
            }
        }

        add(title: "PermutableSet<Record> partition by odd rank", input: [Record].self) { input in
            return { timer in
                var set: PermutableSet<Record> = PermutableSet(input)
                timer.measure { blackHole(set.stablePartition(by: isOdd)) }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Record> partition by odd rank", input: [Record].self) { input in
            return { timer in
                var set: OrderedSet<Record> = OrderedSet(input)
                timer.measure { blackHole(set.partition(by: isOdd)) }
                blackHole(set)
            }
        }

        add(title: "PermutableDictionary<Int, Record> partition by odd rank", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
                timer.measure { blackHole(dictionary.stablePartition { isOdd($0.value) }) }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> partition by odd rank", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
                timer.measure { blackHole(dictionary.partition { isOdd($0.value) }) }
                blackHole(dictionary)
            }
        }

        add(title: "IdentifiedSet<Record> partition by odd rank", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                timer.measure { blackHole(set.stablePartition(by: isOdd)) }
                blackHole(set)
            }
        }
        add(title: "IdentifiedArray<Record> partition by odd rank", input: [Record].self) { input in
            return { timer in
                var array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
                timer.measure { blackHole(array.partition(by: isOdd)) }
                blackHole(array)
            }
        }
    }
}
