// repository: https://github.com/JonathanStorey/swift-permutation
// path: IdentifiedSetBenchmarks.swift
// dependencies: [Collections/IdentifiedSet.swift, Collections/PermutableCollection.swift, Record.swift]

import CollectionsBenchmark
import Permutation

extension Benchmark {

    /// Adds every IdentifiedSet task. Each takes shuffled records of the input size, builds a fresh set outside the timed region, and reserves capacity there so the set stops sharing the input's storage, and times only the operation, so the charts show time per element.
    mutating func addIdentifiedSetBenchmarks() {

        // MARK: Building

        addSimple(title: "IdentifiedSet<Record> init from array", input: [Record].self) { input in
            blackHole(IdentifiedSet(input))
        }

        add(title: "IdentifiedSet<Record> append one at a time", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = []
                timer.measure {
                    for record in input { set.append(record) }
                }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> append(contentsOf:)", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = []
                timer.measure { set.append(contentsOf: input) }
                blackHole(set)
            }
        }

        // MARK: Lookup

        add(title: "IdentifiedSet<Record> successful contains(id:)", input: [Record].self) { input in
            let set: IdentifiedSet<Record> = IdentifiedSet(input)
            let ids: [Record.ID] = input.map(\.id).shuffled()
            return { timer in
                timer.measure {
                    for id in ids { precondition(set.contains(id: id)) }
                }
            }
        }

        add(title: "IdentifiedSet<Record> unsuccessful contains(id:)", input: [Record].self) { input in
            let set: IdentifiedSet<Record> = IdentifiedSet(input)
            let ids: [Record.ID] = input.map { _ in Record(rank: 0).id }
            return { timer in
                timer.measure {
                    for id in ids { precondition(!set.contains(id: id)) }
                }
            }
        }

        add(title: "IdentifiedSet<Record> subscript(id:) read", input: [Record].self) { input in
            let set: IdentifiedSet<Record> = IdentifiedSet(input)
            let ids: [Record.ID] = input.map(\.id).shuffled()
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for id in ids { total &+= set[id: id]!.rank }
                    blackHole(total)
                }
            }
        }

        add(title: "IdentifiedSet<Record> iteration", input: [Record].self) { input in
            let set: IdentifiedSet<Record> = IdentifiedSet(input)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for record in set { total &+= record.rank }
                    blackHole(total)
                }
            }
        }

        // MARK: Updating

        add(title: "IdentifiedSet<Record> replace(_:) every element", input: [Record].self) { input in
            let changed: [Record] = input.shuffled().map { record in
                var record: Record = record
                record.rank += 1
                return record
            }
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    for record in changed { set.replace(record) }
                }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> update(orAppend:) batch, half new", input: [Record].self) { input in
            let half: Int = input.count / 2
            let batch: [Record] = input.shuffled()
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input[..<half])
                set.reserveCapacity(input.count)
                timer.measure { set.update(orAppend: batch) }
                blackHole(set)
            }
        }

        // MARK: Removing

        add(title: "IdentifiedSet<Record> remove(id:) every element", input: [Record].self) { input in
            let ids: [Record.ID] = input.map(\.id).shuffled()
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    for id in ids { set.remove(id: id) }
                }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> removeAll(where:) half", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.removeAll { $0.rank.isMultiple(of: 2) } }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> remove(ids:) half", input: [Record].self) { input in
            let ids: [Record.ID] = input.filter { $0.rank.isMultiple(of: 2) }.map(\.id).shuffled()
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.remove(ids: ids) }
                blackHole(set)
            }
        }

        // MARK: Reordering

        add(title: "IdentifiedSet<Record> reverse()", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.reverse() }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> shuffle()", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.shuffle() }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> sort(by:)", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.sort { $0.rank < $1.rank } }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> rotate(toStartAt:) middle", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.rotate(toStartAt: set.count / 2) }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> rotate by a third", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.rotate(toStartAt: set.count / 3) }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> move first to last", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    if !set.isEmpty { set.move(from: 0, to: set.count - 1) }
                }
                blackHole(set)
            }
        }

        add(title: "IdentifiedSet<Record> apply(_:) random permutation", input: [Record].self) { input in
            let permutation: Permutation = Permutation(shuffles: input.count)
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.apply(permutation) }
                blackHole(set)
            }
        }
    }
}
