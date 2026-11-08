// repository: https://github.com/JonathanStorey/swift-permutation
// path: PermutableSetBenchmarks.swift
// dependencies: [Collections/PermutableCollection.swift, Collections/PermutableSet.swift]

import CollectionsBenchmark
import OrderedCollections
import Permutation

extension Benchmark {

    /// Adds matching tasks for PermutableSet and swift-collections' OrderedSet, so each chart line has a partner. Every task takes shuffled integers of the input size, builds its set outside the timed region where it can, and times only the operation.
    mutating func addPermutableSetBenchmarks() {

        // MARK: Building

        addSimple(title: "PermutableSet<Int> init from array", input: [Int].self) { input in
            blackHole(PermutableSet(input))
        }
        addSimple(title: "OrderedSet<Int> init from array", input: [Int].self) { input in
            blackHole(OrderedSet(input))
        }

        add(title: "PermutableSet<Int> append one at a time", input: [Int].self) { input in
            return { timer in
                var set: PermutableSet<Int> = []
                timer.measure {
                    for value in input { set.append(value) }
                }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Int> append one at a time", input: [Int].self) { input in
            return { timer in
                var set: OrderedSet<Int> = []
                timer.measure {
                    for value in input { set.append(value) }
                }
                blackHole(set)
            }
        }

        // MARK: Lookup

        add(title: "PermutableSet<Int> successful contains", input: [Int].self) { input in
            let set: PermutableSet<Int> = PermutableSet(input)
            let probes: [Int] = input.shuffled()
            return { timer in
                timer.measure {
                    for value in probes { precondition(set.contains(value)) }
                }
            }
        }
        add(title: "OrderedSet<Int> successful contains", input: [Int].self) { input in
            let set: OrderedSet<Int> = OrderedSet(input)
            let probes: [Int] = input.shuffled()
            return { timer in
                timer.measure {
                    for value in probes { precondition(set.contains(value)) }
                }
            }
        }

        add(title: "PermutableSet<Int> iteration", input: [Int].self) { input in
            let set: PermutableSet<Int> = PermutableSet(input)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for value in set { total &+= value }
                    blackHole(total)
                }
            }
        }
        add(title: "PermutableSet<Int> iteration after shuffle", input: [Int].self) { input in
            var set: PermutableSet<Int> = PermutableSet(input)
            set.shuffle()
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for value in set { total &+= value }
                    blackHole(total)
                }
            }
        }
        add(title: "OrderedSet<Int> iteration", input: [Int].self) { input in
            let set: OrderedSet<Int> = OrderedSet(input)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for value in set { total &+= value }
                    blackHole(total)
                }
            }
        }

        // MARK: Removing

        add(title: "PermutableSet<Int> remove 1% one at a time", input: [Int].self) { input in
            let doomed: [Int] = Array(input.shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var set: PermutableSet<Int> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    for value in doomed { set.remove(value) }
                }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Int> remove 1% one at a time", input: [Int].self) { input in
            let doomed: [Int] = Array(input.shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var set: OrderedSet<Int> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    for value in doomed { set.remove(value) }
                }
                blackHole(set)
            }
        }

        // MARK: Reordering

        add(title: "PermutableSet<Int> sort", input: [Int].self) { input in
            return { timer in
                var set: PermutableSet<Int> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.sort() }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Int> sort", input: [Int].self) { input in
            return { timer in
                var set: OrderedSet<Int> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.sort() }
                blackHole(set)
            }
        }

        add(title: "PermutableSet<Int> shuffle", input: [Int].self) { input in
            return { timer in
                var set: PermutableSet<Int> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.shuffle() }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Int> shuffle", input: [Int].self) { input in
            return { timer in
                var set: OrderedSet<Int> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.shuffle() }
                blackHole(set)
            }
        }

        add(title: "PermutableSet<Int> reverse", input: [Int].self) { input in
            return { timer in
                var set: PermutableSet<Int> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.reverse() }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Int> reverse", input: [Int].self) { input in
            return { timer in
                var set: OrderedSet<Int> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.reverse() }
                blackHole(set)
            }
        }

        add(title: "PermutableSet<Int> rotate by a third", input: [Int].self) { input in
            return { timer in
                var set: PermutableSet<Int> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure { set.rotate(toStartAt: set.count / 3) }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Int> rotate by a third", input: [Int].self) { input in
            return { timer in
                var set: OrderedSet<Int> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    let pivot: Int = set.count / 3
                    set = OrderedSet(uncheckedUniqueElements: set.elements[pivot...] + set.elements[..<pivot])
                }
                blackHole(set)
            }
        }

        add(title: "PermutableSet<Int> move first to last", input: [Int].self) { input in
            return { timer in
                var set: PermutableSet<Int> = PermutableSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    if !set.isEmpty { set.move(from: 0, to: set.count - 1) }
                }
                blackHole(set)
            }
        }
        add(title: "OrderedSet<Int> move first to last", input: [Int].self) { input in
            return { timer in
                var set: OrderedSet<Int> = OrderedSet(input)
                set.reserveCapacity(input.count)
                timer.measure {
                    if !set.isEmpty { set.append(set.remove(at: 0)) }
                }
                blackHole(set)
            }
        }

        // MARK: Set operations

        add(title: "PermutableSet<Int> union half-overlapping", input: [Int].self) { input in
            let set: PermutableSet<Int> = PermutableSet(input)
            let other: [Int] = input.map { $0 + input.count / 2 }
            return { timer in
                timer.measure { blackHole(set.union(other)) }
            }
        }
        add(title: "OrderedSet<Int> union half-overlapping", input: [Int].self) { input in
            let set: OrderedSet<Int> = OrderedSet(input)
            let other: [Int] = input.map { $0 + input.count / 2 }
            return { timer in
                timer.measure { blackHole(set.union(other)) }
            }
        }

        add(title: "PermutableSet<Int> intersection half-overlapping", input: [Int].self) { input in
            let set: PermutableSet<Int> = PermutableSet(input)
            let other: [Int] = input.map { $0 + input.count / 2 }
            return { timer in
                timer.measure { blackHole(set.intersection(other)) }
            }
        }
        add(title: "OrderedSet<Int> intersection half-overlapping", input: [Int].self) { input in
            let set: OrderedSet<Int> = OrderedSet(input)
            let other: [Int] = input.map { $0 + input.count / 2 }
            return { timer in
                timer.measure { blackHole(set.intersection(other)) }
            }
        }

        add(title: "PermutableSet<Int> subtracting half-overlapping", input: [Int].self) { input in
            let set: PermutableSet<Int> = PermutableSet(input)
            let other: [Int] = input.map { $0 + input.count / 2 }
            return { timer in
                timer.measure { blackHole(set.subtracting(other)) }
            }
        }
        add(title: "OrderedSet<Int> subtracting half-overlapping", input: [Int].self) { input in
            let set: OrderedSet<Int> = OrderedSet(input)
            let other: [Int] = input.map { $0 + input.count / 2 }
            return { timer in
                timer.measure { blackHole(set.subtracting(other)) }
            }
        }
    }
}
