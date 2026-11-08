// repository: https://github.com/JonathanStorey/swift-permutation
// path: ArrangementBenchmarks.swift
// dependencies: [Collections/Arrangement.swift, Collections/PermutableCollection.swift, Record.swift]

import CollectionsBenchmark
import Permutation

extension Benchmark {

    /// Adds matching reorder tasks for Arrangement and Array, both holding records, so each chart line has a partner. Every task builds a fresh, uniquely owned collection outside the timed region and times only the reorder.
    mutating func addArrangementBenchmarks() {

        func arranged(_ title: String, _ body: @escaping (inout Arrangement<Record>) -> Void) {
            add(title: "Arrangement<Record> \(title)", input: [Record].self) { input in
                return { timer in
                    var arrangement: Arrangement<Record> = Arrangement(input.map { $0 })
                    timer.measure { body(&arrangement) }
                    blackHole(arrangement)
                }
            }
        }

        func array(_ title: String, _ body: @escaping (inout [Record]) -> Void) {
            add(title: "Array<Record> \(title)", input: [Record].self) { input in
                return { timer in
                    var array: [Record] = input.map { $0 }
                    timer.measure { body(&array) }
                    blackHole(array)
                }
            }
        }

        arranged("sort(by:)") { $0.sort { $0.rank < $1.rank } }
        array("sort(by:)") { $0.sort { $0.rank < $1.rank } }

        arranged("shuffle()") { $0.shuffle() }
        array("shuffle()") { $0.shuffle() }

        arranged("reverse()") { $0.reverse() }
        array("reverse()") { $0.reverse() }

        arranged("rotate by a third") { $0.rotate(toStartAt: $0.count / 3) }
        array("rotate by a third") { array in
            let pivot: Int = array.count / 3
            array = Array(array[pivot...] + array[..<pivot])
        }

        arranged("move first to last") { arrangement in
            guard !arrangement.isEmpty else { return }
            arrangement.move(from: 0, to: arrangement.count - 1)
        }
        array("move first to last") { array in
            guard !array.isEmpty else { return }
            array.append(array.remove(at: 0))
        }
    }
}
