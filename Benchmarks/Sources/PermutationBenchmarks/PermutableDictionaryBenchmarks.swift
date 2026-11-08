// repository: https://github.com/JonathanStorey/swift-permutation
// path: PermutableDictionaryBenchmarks.swift
// dependencies: [Collections/Arrangement.swift, Collections/PermutableCollection.swift, Collections/PermutableDictionary.swift]

import CollectionsBenchmark
import OrderedCollections
import Permutation

extension Benchmark {

    /// Adds matching tasks for PermutableDictionary and swift-collections' OrderedDictionary. Every task takes shuffled integers of the input size as keys, pairs each with a value, builds its dictionary outside the timed region where it can, and times only the operation.
    mutating func addPermutableDictionaryBenchmarks() {

        // MARK: Building

        addSimple(title: "PermutableDictionary<Int, Int> init from keys and values", input: [Int].self) { input in
            blackHole(PermutableDictionary(uniqueKeys: input, values: input))
        }
        addSimple(title: "OrderedDictionary<Int, Int> init from keys and values", input: [Int].self) { input in
            blackHole(OrderedDictionary(uniqueKeys: input, values: input))
        }

        add(title: "PermutableDictionary<Int, Int> subscript insert one at a time", input: [Int].self) { input in
            return { timer in
                var dictionary: PermutableDictionary<Int, Int> = [:]
                timer.measure {
                    for key in input { dictionary[key] = key }
                }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Int> subscript insert one at a time", input: [Int].self) { input in
            return { timer in
                var dictionary: OrderedDictionary<Int, Int> = [:]
                timer.measure {
                    for key in input { dictionary[key] = key }
                }
                blackHole(dictionary)
            }
        }

        // MARK: Lookup

        add(title: "PermutableDictionary<Int, Int> subscript lookup", input: [Int].self) { input in
            var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: input)
            dictionary.reassignValues()
            let probes: [Int] = input.shuffled()
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for key in probes { total &+= dictionary[key]! }
                    blackHole(total)
                }
            }
        }
        add(title: "OrderedDictionary<Int, Int> subscript lookup", input: [Int].self) { input in
            var dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: input)
            dictionary.values.shuffle()
            let probes: [Int] = input.shuffled()
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for key in probes { total &+= dictionary[key]! }
                    blackHole(total)
                }
            }
        }

        add(title: "PermutableDictionary<Int, Int> iteration", input: [Int].self) { input in
            let dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: input)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for entry in dictionary { total &+= entry.key &+ entry.value }
                    blackHole(total)
                }
            }
        }
        add(title: "OrderedDictionary<Int, Int> iteration", input: [Int].self) { input in
            let dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: input)
            return { timer in
                timer.measure {
                    var total: Int = 0
                    for entry in dictionary { total &+= entry.key &+ entry.value }
                    blackHole(total)
                }
            }
        }

        // MARK: Removing

        add(title: "PermutableDictionary<Int, Int> removeValue(forKey:) 1%", input: [Int].self) { input in
            let doomed: [Int] = Array(input.shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: input)
                timer.measure {
                    for key in doomed { dictionary.removeValue(forKey: key) }
                }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Int> removeValue(forKey:) 1%", input: [Int].self) { input in
            let doomed: [Int] = Array(input.shuffled().prefix(Swift.max(1, input.count / 100)))
            return { timer in
                var dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: input)
                timer.measure {
                    for key in doomed { dictionary.removeValue(forKey: key) }
                }
                blackHole(dictionary)
            }
        }

        // MARK: Reordering entries

        add(title: "PermutableDictionary<Int, Int> sort by key", input: [Int].self) { input in
            return { timer in
                var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: input)
                timer.measure { dictionary.keys.sort() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Int> sort by key", input: [Int].self) { input in
            return { timer in
                var dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: input)
                timer.measure { dictionary.sort() }
                blackHole(dictionary)
            }
        }

        add(title: "PermutableDictionary<Int, Int> shuffle", input: [Int].self) { input in
            return { timer in
                var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: input)
                timer.measure { dictionary.shuffle() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Int> shuffle", input: [Int].self) { input in
            return { timer in
                var dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: input)
                timer.measure { dictionary.shuffle() }
                blackHole(dictionary)
            }
        }

        add(title: "PermutableDictionary<Int, Int> reverse", input: [Int].self) { input in
            return { timer in
                var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: input)
                timer.measure { dictionary.reverse() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Int> reverse", input: [Int].self) { input in
            return { timer in
                var dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: input)
                timer.measure { dictionary.reverse() }
                blackHole(dictionary)
            }
        }

        add(title: "PermutableDictionary<Int, Int> rotate by a third", input: [Int].self) { input in
            return { timer in
                var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: input)
                timer.measure { dictionary.rotate(toStartAt: dictionary.count / 3) }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Int> rotate by a third", input: [Int].self) { input in
            return { timer in
                var dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: input)
                timer.measure {
                    let pivot: Int = dictionary.count / 3
                    let keys: [Int] = dictionary.keys.elements
                    let values: [Int] = Array(dictionary.values)
                    dictionary = OrderedDictionary(uncheckedUniqueKeys: keys[pivot...] + keys[..<pivot], values: values[pivot...] + values[..<pivot])
                }
                blackHole(dictionary)
            }
        }

        add(title: "PermutableDictionary<Int, Int> move first to last", input: [Int].self) { input in
            return { timer in
                var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: input)
                timer.measure {
                    if !dictionary.isEmpty { dictionary.move(from: 0, to: dictionary.count - 1) }
                }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Int> move first to last", input: [Int].self) { input in
            return { timer in
                var dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: input)
                timer.measure {
                    if !dictionary.isEmpty {
                        let (key, value): (Int, Int) = dictionary.remove(at: 0)
                        dictionary[key] = value
                    }
                }
                blackHole(dictionary)
            }
        }

        // MARK: Reordering by value

        add(title: "PermutableDictionary<Int, Int> sort by value", input: [Int].self) { input in
            let values: [Int] = input.shuffled()
            return { timer in
                var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: values)
                timer.measure { dictionary.values.sort() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Int> sort by value", input: [Int].self) { input in
            let values: [Int] = input.shuffled()
            return { timer in
                var dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: values)
                timer.measure { dictionary.sort { $0.value < $1.value } }
                blackHole(dictionary)
            }
        }

        // MARK: Reassigning values among keys

        add(title: "PermutableDictionary<Int, Int> shuffle values among keys", input: [Int].self) { input in
            return { timer in
                var dictionary: PermutableDictionary<Int, Int> = PermutableDictionary(uniqueKeys: input, values: input)
                timer.measure { dictionary.reassignValues() }
                blackHole(dictionary)
            }
        }
        add(title: "OrderedDictionary<Int, Int> shuffle values among keys", input: [Int].self) { input in
            return { timer in
                var dictionary: OrderedDictionary<Int, Int> = OrderedDictionary(uniqueKeys: input, values: input)
                timer.measure { dictionary.values.shuffle() }
                blackHole(dictionary)
            }
        }
    }
}
