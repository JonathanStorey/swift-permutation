// repository: https://github.com/JonathanStorey/swift-permutation
// path: PermutableSetBenchmarks.swift
// dependencies: [Collections/PermutableCollection.swift, Collections/PermutableSet.swift]

import CollectionsBenchmark
import OrderedCollections
import Permutation

extension Benchmark {

    /// Adds matching tasks for PermutableSet and swift-collections' OrderedSet, so each chart line has a partner. Every task takes shuffled records of the input size, each with a 64-byte payload,, builds its set outside the timed region where it can, and times only the operation.
    mutating func addPermutableSetBenchmarks() {

        // MARK: Building

        addSimple(title: "PermutableSet<Record> init from array", input: [Record].self) { input in
            blackHole(PermutableSet(input))
        }
        addSimple(title: "OrderedSet<Record> init from array", input: [Record].self) { input in
            blackHole(OrderedSet(input))
        }

        add(title: "PermutableSet<Record> append one at a time", input: [Record].self) { input in
            return { timer in
                var set: PermutableSet<Record> = []
                timer.measure {
                    for value in input { set.append(value) }
                }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Record> append one at a time", input: [Record].self) { input in
            return { timer in
                var set: OrderedSet<Record> = []
                timer.measure {
                    for value in input { set.append(value) }
                }
                blackHole(set)
            }
        }

        // MARK: Lookup

        add(title: "PermutableSet<Record> successful contains", input: [Record].self) { input in
            let set: PermutableSet<Record> = PermutableSet(input)
            let probes: [Record] = input.shuffled()
            return { timer in
                timer.measure {
                    for value in probes { precondition(set.contains(value)) }
                }
            }
        }
        add(title: "OrderedSet<Record> successful contains", input: [Record].self) { input in
            let set: OrderedSet<Record> = OrderedSet(input)
            let probes: [Record] = input.shuffled()
            return { timer in
                timer.measure {
                    for value in probes { precondition(set.contains(value)) }
                }
            }
        }

        add(title: "PermutableSet<Record> iteration", input: [Record].self) { input in
            let set: PermutableSet<Record> = PermutableSet(input)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for value in set { total &+= value.rank }
                    blackHole(total)
                }
            }
        }
        add(title: "PermutableSet<Record> iteration after shuffle", input: [Record].self) { input in
            var set: PermutableSet<Record> = PermutableSet(input)
            set.shuffle()
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for value in set { total &+= value.rank }
                    blackHole(total)
                }
            }
        }
        add(title: "OrderedSet<Record> iteration", input: [Record].self) { input in
            let set: OrderedSet<Record> = OrderedSet(input)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for value in set { total &+= value.rank }
                    blackHole(total)
                }
            }
        }

        // MARK: Removing

        add(title: "PermutableSet<Record> remove 1% one at a time", input: [Record].self) { input in
            let doomed: [Record] = Array(input.shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var set: PermutableSet<Record> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    for value in doomed { set.remove(value) }
                }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Record> remove 1% one at a time", input: [Record].self) { input in
            let doomed: [Record] = Array(input.shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var set: OrderedSet<Record> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    for value in doomed { set.remove(value) }
                }
                blackHole(set)
            }
        }

        // MARK: Reordering

        add(title: "PermutableSet<Record> sort", input: [Record].self) { input in
            return { timer in
                var set: PermutableSet<Record> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.sort() }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Record> sort", input: [Record].self) { input in
            return { timer in
                var set: OrderedSet<Record> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.sort() }
                blackHole(set)
            }
        }

        add(title: "PermutableSet<Record> shuffle", input: [Record].self) { input in
            return { timer in
                var set: PermutableSet<Record> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.shuffle() }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Record> shuffle", input: [Record].self) { input in
            return { timer in
                var set: OrderedSet<Record> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.shuffle() }
                blackHole(set)
            }
        }

        add(title: "PermutableSet<Record> reverse", input: [Record].self) { input in
            return { timer in
                var set: PermutableSet<Record> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.reverse() }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Record> reverse", input: [Record].self) { input in
            return { timer in
                var set: OrderedSet<Record> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.reverse() }
                blackHole(set)
            }
        }

        add(title: "PermutableSet<Record> rotate by a third", input: [Record].self) { input in
            return { timer in
                var set: PermutableSet<Record> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.rotate(toStartAt: set.count / 3) }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Record> rotate by a third", input: [Record].self) { input in
            return { timer in
                var set: OrderedSet<Record> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    let pivot: Int = set.count / 3
                    set = OrderedSet(uncheckedUniqueElements: set.elements[pivot...] + set.elements[..<pivot])
                }
                blackHole(set)
            }
        }

        add(title: "PermutableSet<Record> move first to last", input: [Record].self) { input in
            return { timer in
                var set: PermutableSet<Record> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    if !set.isEmpty { set.move(from: 0, to: set.count - 1) }
                }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Record> move first to last", input: [Record].self) { input in
            return { timer in
                var set: OrderedSet<Record> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    if !set.isEmpty { set.append(set.remove(at: 0)) }
                }
                blackHole(set)
            }
        }

        // MARK: Set operations

        add(title: "PermutableSet<Record> union half-overlapping", input: [Record].self) { input in
            let set: PermutableSet<Record> = PermutableSet(input)
            let other: [Record] = Array(input.prefix(input.count / 2)) + (0..<(input.count - input.count / 2)).map { Record(rank: input.count + $0) }
            return { timer in
                timer.measure { blackHole(set.union(other)) }
            }
        }
        add(title: "OrderedSet<Record> union half-overlapping", input: [Record].self) { input in
            let set: OrderedSet<Record> = OrderedSet(input)
            let other: [Record] = Array(input.prefix(input.count / 2)) + (0..<(input.count - input.count / 2)).map { Record(rank: input.count + $0) }
            return { timer in
                timer.measure { blackHole(set.union(other)) }
            }
        }

        add(title: "PermutableSet<Record> intersection half-overlapping", input: [Record].self) { input in
            let set: PermutableSet<Record> = PermutableSet(input)
            let other: [Record] = Array(input.prefix(input.count / 2)) + (0..<(input.count - input.count / 2)).map { Record(rank: input.count + $0) }
            return { timer in
                timer.measure { blackHole(set.intersection(other)) }
            }
        }
        add(title: "OrderedSet<Record> intersection half-overlapping", input: [Record].self) { input in
            let set: OrderedSet<Record> = OrderedSet(input)
            let other: [Record] = Array(input.prefix(input.count / 2)) + (0..<(input.count - input.count / 2)).map { Record(rank: input.count + $0) }
            return { timer in
                timer.measure { blackHole(set.intersection(other)) }
            }
        }

        add(title: "PermutableSet<Record> subtracting half-overlapping", input: [Record].self) { input in
            let set: PermutableSet<Record> = PermutableSet(input)
            let other: [Record] = Array(input.prefix(input.count / 2)) + (0..<(input.count - input.count / 2)).map { Record(rank: input.count + $0) }
            return { timer in
                timer.measure { blackHole(set.subtracting(other)) }
            }
        }
        add(title: "OrderedSet<Record> subtracting half-overlapping", input: [Record].self) { input in
            let set: OrderedSet<Record> = OrderedSet(input)
            let other: [Record] = Array(input.prefix(input.count / 2)) + (0..<(input.count - input.count / 2)).map { Record(rank: input.count + $0) }
            return { timer in
                timer.measure { blackHole(set.subtracting(other)) }
            }
        }
    }
}
