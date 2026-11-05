// repository: https://github.com/JonathanStorey/swift-permutation
// path: IdentifiedComparison.swift
// dependencies: [Collections/IdentifiedSet.swift, Collections/PermutableCollection.swift, Record.swift, SeededGenerator.swift]

import Foundation
import Permutation

/// One operation on identifiable records written three ways: on `IdentifiedSet`, on a plain array, and on a plain array whose id index is rebuilt afterward so lookups by id stay O(1).
struct IdentifiedComparison {

    let operation: String
    let identified: (inout IdentifiedSet<Record>) -> Void
    let array: (inout [Record]) -> Void
    let reindexes: Bool

    init(_ operation: String, reindexes: Bool = true, identified: @escaping (inout IdentifiedSet<Record>) -> Void, array: @escaping (inout [Record]) -> Void) {
        self.operation = operation
        self.identified = identified
        self.array = array
        self.reindexes = reindexes
    }

    /// The position of every record, keyed by id, as an array-backed collection would rebuild it after a reorder.
    static func index(_ records: [Record]) -> [UUID: Int] {
        var index: [UUID: Int] = [:]
        index.reserveCapacity(records.count)
        for (position, record) in records.enumerated() { index[record.id] = position }
        return index
    }

    static var all: [IdentifiedComparison] {
        [
            IdentifiedComparison("move(from:to:)", identified: { set in
                set.move(from: 0, to: set.count - 1)
            }, array: { array in
                array.append(array.remove(at: 0))
            }),
            IdentifiedComparison("reverse()", identified: { set in
                set.reverse()
            }, array: { array in
                array.reverse()
            }),
            IdentifiedComparison("rotate(toStartAt:)", identified: { set in
                set.rotate(toStartAt: set.count / 3)
            }, array: { array in
                let pivot: Int = array.count / 3
                array[..<pivot].reverse()
                array[pivot...].reverse()
                array.reverse()
            }),
            IdentifiedComparison("shuffle(using:)", identified: { set in
                var generator: SeededGenerator = SeededGenerator(state: 7)
                set.shuffle(using: &generator)
            }, array: { array in
                var generator: SeededGenerator = SeededGenerator(state: 7)
                array.shuffle(using: &generator)
            }),
            IdentifiedComparison("sort(by:)", identified: { set in
                set.sort { $0.rank < $1.rank }
            }, array: { array in
                array.sort { $0.rank < $1.rank }
            }),
            IdentifiedComparison("rebuild from an array", identified: { set in
                set = IdentifiedSet(Array(set))
            }, array: { array in
                array = Array(array)
            }),
            IdentifiedComparison("100 removals by id", identified: { set in
                let step: Int = max(1, set.count / 100)
                let ids: [UUID] = stride(from: 0, to: set.count, by: step).map { set[$0].id }
                for id in ids { set.remove(id: id) }
            }, array: { array in
                let step: Int = max(1, array.count / 100)
                let ids: [UUID] = stride(from: 0, to: array.count, by: step).map { array[$0].id }
                for id in ids { array.remove(at: array.firstIndex { $0.id == id }!) }
            }),
            IdentifiedComparison("100 appends", reindexes: false, identified: { set in
                for record in Record.extras { set.append(record) }
            }, array: { array in
                for record in Record.extras { array.append(record) }
            }),
            IdentifiedComparison("100 lookups of missing ids", reindexes: false, identified: { set in
                var found: Int = 0
                for id in Record.missingIDs where set.contains(id: id) { found += 1 }
                blackHole(found)
            }, array: { array in
                var found: Int = 0
                for id in Record.missingIDs where array.contains(where: { $0.id == id }) { found += 1 }
                blackHole(found)
            }),
            IdentifiedComparison("100 lookups by id", reindexes: false, identified: { set in
                let step: Int = max(1, set.count / 100)
                var total: Int = 0
                for position in stride(from: 0, to: set.count, by: step) {
                    total &+= set[id: set[position].id]!.rank
                }
                blackHole(total)
            }, array: { array in
                let step: Int = max(1, array.count / 100)
                var total: Int = 0
                for position in stride(from: 0, to: array.count, by: step) {
                    let id: UUID = array[position].id
                    total &+= array.first { $0.id == id }!.rank
                }
                blackHole(total)
            }),
        ]
    }
}
