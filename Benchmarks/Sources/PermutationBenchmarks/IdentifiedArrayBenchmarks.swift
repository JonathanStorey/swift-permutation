// repository: https://github.com/JonathanStorey/swift-permutation
// path: IdentifiedArrayBenchmarks.swift
// dependencies: [Collections/IdentifiedSet.swift, Collections/PermutableCollection.swift, Record.swift]

import CollectionsBenchmark
import IdentifiedCollections
import Permutation

extension Benchmark {

    /// Adds tasks for Point-Free's IdentifiedArray that pair with the IdentifiedSet tasks of the same name, so the two can be charted and tabled side by side.
    mutating func addIdentifiedArrayBenchmarks() {

        addSimple(title: "IdentifiedArray<Record> init from array", input: [Record].self) { input in
            blackHole(IdentifiedArray(uniqueElements: input))
        }

        add(title: "IdentifiedArray<Record> append one at a time", input: [Record].self) { input in
            return { timer in
                var array: IdentifiedArrayOf<Record> = []
                timer.measure {
                    for record in input { array.append(record) }
                }
                blackHole(array)
            }
        }

        add(title: "IdentifiedArray<Record> successful contains(id:)", input: [Record].self) { input in
            let array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
            let ids: [Record.ID] = input.map(\.id).shuffled()
            return { timer in
                timer.measure {
                    for id in ids { precondition(array.ids.contains(id)) }
                }
            }
        }

        add(title: "IdentifiedArray<Record> subscript(id:) read", input: [Record].self) { input in
            let array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
            let ids: [Record.ID] = input.map(\.id).shuffled()
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for id in ids { total &+= array[id: id]!.rank }
                    blackHole(total)
                }
            }
        }

        add(title: "IdentifiedArray<Record> iteration", input: [Record].self) { input in
            let array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for record in array { total &+= record.rank }
                    blackHole(total)
                }
            }
        }

        add(title: "IdentifiedArray<Record> remove(id:) 1%", input: [Record].self) { input in
            let ids: [Record.ID] = Array(input.map(\.id).shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
                timer.measure {
                    for id in ids { array.remove(id: id) }
                }
                blackHole(array)
            }
        }
        add(title: "IdentifiedSet<Record> remove(id:) 1%", input: [Record].self) { input in
            let ids: [Record.ID] = Array(input.map(\.id).shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    for id in ids { set.remove(id: id) }
                }
                blackHole(set)
            }
        }

        add(title: "IdentifiedArray<Record> removeAll(where:) half", input: [Record].self) { input in
            return { timer in
                var array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
                timer.measure { array.removeAll { $0.rank.isMultiple(of: 2) } }
                blackHole(array)
            }
        }

        add(title: "IdentifiedArray<Record> reverse()", input: [Record].self) { input in
            return { timer in
                var array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
                timer.measure { array.reverse() }
                blackHole(array)
            }
        }

        add(title: "IdentifiedArray<Record> shuffle()", input: [Record].self) { input in
            return { timer in
                var array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
                timer.measure { array.shuffle() }
                blackHole(array)
            }
        }

        add(title: "IdentifiedArray<Record> sort(by:)", input: [Record].self) { input in
            return { timer in
                var array: IdentifiedArrayOf<Record> = IdentifiedArray(uniqueElements: input)
                timer.measure { array.sort { $0.rank < $1.rank } }
                blackHole(array)
            }
        }
    }
}
