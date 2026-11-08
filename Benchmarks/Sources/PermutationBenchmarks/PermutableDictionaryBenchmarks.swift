// repository: https://github.com/JonathanStorey/swift-permutation
// path: PermutableDictionaryBenchmarks.swift
// dependencies: [Collections/Arrangement.swift, Collections/PermutableCollection.swift, Collections/PermutableDictionary.swift]

import CollectionsBenchmark
import OrderedCollections
import Permutation

extension Benchmark {

    /// Adds matching tasks for PermutableDictionary and swift-collections' OrderedDictionary. Every task takes shuffled integers of the input size as keys, pairs each with a record holding a 64-byte payload, builds its dictionary outside the timed region where it can, and times only the operation.
    mutating func addPermutableDictionaryBenchmarks() {

        // MARK: Building

        add(title: "PermutableDictionary<Int, Record> init from keys and values", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                timer.measure { blackHole(PermutableDictionary(uniqueKeys: input, values: records)) }
            }
        }
        add(title: "OrderedDictionary<Int, Record> init from keys and values", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                timer.measure { blackHole(OrderedDictionary(uniqueKeys: input, values: records)) }
            }
        }

        add(title: "PermutableDictionary<Int, Record> subscript insert one at a time", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = [:]
                timer.measure {
                    for (key, record) in zip(input, records) { dictionary[key] = record }
                }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> subscript insert one at a time", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = [:]
                timer.measure {
                    for (key, record) in zip(input, records) { dictionary[key] = record }
                }
                blackHole(dictionary)
            }
        }

        // MARK: Lookup

        add(title: "PermutableDictionary<Int, Record> subscript lookup", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
            dictionary.reassignValues()
            let probes: [Int] = input.shuffled()
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for key in probes { total &+= dictionary[key]!.rank }
                    blackHole(total)
                }
            }
        }
        add(title: "OrderedDictionary<Int, Record> subscript lookup", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
            dictionary.values.shuffle()
            let probes: [Int] = input.shuffled()
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for key in probes { total &+= dictionary[key]!.rank }
                    blackHole(total)
                }
            }
        }

        add(title: "PermutableDictionary<Int, Record> iteration", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            let dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for entry in dictionary { total &+= entry.key &+ entry.value.rank }
                    blackHole(total)
                }
            }
        }
        add(title: "OrderedDictionary<Int, Record> iteration", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            let dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for entry in dictionary { total &+= entry.key &+ entry.value.rank }
                    blackHole(total)
                }
            }
        }

        // MARK: Removing

        add(title: "PermutableDictionary<Int, Record> removeValue(forKey:) 1%", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            let doomed: [Int] = Array(input.shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
                timer.measure {
                    for key in doomed { dictionary.removeValue(forKey: key) }
                }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> removeValue(forKey:) 1%", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            let doomed: [Int] = Array(input.shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
                timer.measure {
                    for key in doomed { dictionary.removeValue(forKey: key) }
                }
                blackHole(dictionary)
            }
        }

        // MARK: Reordering entries

        add(title: "PermutableDictionary<Int, Record> sort by key", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.keys.sort() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> sort by key", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.sort() }
                blackHole(dictionary)
            }
        }

        add(title: "PermutableDictionary<Int, Record> shuffle", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.shuffle() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> shuffle", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.shuffle() }
                blackHole(dictionary)
            }
        }

        add(title: "PermutableDictionary<Int, Record> reverse", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.reverse() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> reverse", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.reverse() }
                blackHole(dictionary)
            }
        }

        add(title: "PermutableDictionary<Int, Record> rotate by a third", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.rotate(toStartAt: dictionary.count / 3) }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> rotate by a third", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
                timer.measure {
                    let pivot: Int = dictionary.count / 3
                    let keys: [Int] = dictionary.keys.elements
                    let values: [Record] = Array(dictionary.values)
                    dictionary = OrderedDictionary(uncheckedUniqueKeys: keys[pivot...] + keys[..<pivot], values: values[pivot...] + values[..<pivot])
                }
                blackHole(dictionary)
            }
        }

        add(title: "PermutableDictionary<Int, Record> move first to last", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
                timer.measure {
                    if !dictionary.isEmpty { dictionary.move(from: 0, to: dictionary.count - 1) }
                }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> move first to last", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
                timer.measure {
                    if !dictionary.isEmpty {
                        let (key, value): (Int, Record) = dictionary.remove(at: 0)
                        dictionary[key] = value
                    }
                }
                blackHole(dictionary)
            }
        }

        // MARK: Reordering by value

        add(title: "PermutableDictionary<Int, Record> sort by value", input: [Int].self) { input in
            let values: [Record] = input.shuffled().map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: values)
                timer.measure { dictionary.values.sort() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> sort by value", input: [Int].self) { input in
            let values: [Record] = input.shuffled().map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: values)
                timer.measure { dictionary.sort { $0.value < $1.value } }
                blackHole(dictionary)
            }
        }

        // MARK: Reassigning values among keys

        add(title: "PermutableDictionary<Int, Record> shuffle values among keys", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: PermutableDictionary<Int, Record> = PermutableDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.reassignValues() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Record> shuffle values among keys", input: [Int].self) { input in
            let records: [Record] = input.map(Record.init(rank:))
            return { timer in
                var dictionary: OrderedDictionary<Int, Record> = OrderedDictionary(uniqueKeys: input, values: records)
                timer.measure { dictionary.values.shuffle() }
                blackHole(dictionary)
            }
        }
    }
}
