// repository: https://github.com/JonathanStorey/swift-permutation
// path: PermutationBenchmarks.swift
// dependencies: [Collections/Collection+Permutation.swift, Collections/IdentifiedSet.swift, Permutation/Permutation+Composition.swift, Permutation/Permutation+ForEach.swift, Permutation/Permutation+Merge.swift, Permutation/Permutation+RangeReplace.swift, Permutation/Permutation+Shuffle.swift, Permutation/Permutation+Power.swift, Record.swift]

import CollectionsBenchmark
import Permutation

extension Benchmark {

    /// Adds the tasks that time permutations themselves and the paths that build or apply them. Each builds its permutations outside the timed region.
    mutating func addPermutationBenchmarks() {

        // MARK: Building and combining

        add(title: "Permutation inverted", input: [Int].self) { input in
            let permutation: Permutation = Permutation(shuffles: input.count)
            return { timer in
                timer.measure { blackHole(permutation.inverted) }
            }
        }

        add(title: "Permutation followed(by:)", input: [Int].self) { input in
            let first: Permutation = Permutation(shuffles: input.count)
            let second: Permutation = Permutation(shuffles: input.count)
            return { timer in
                timer.measure { blackHole(first.followed(by: second)) }
            }
        }

        add(title: "Permutation merging(with:) identical", input: [Int].self) { input in
            let permutation: Permutation = Permutation(shuffles: input.count)
            return { timer in
                timer.measure { blackHole(permutation.merging(with: permutation)) }
            }
        }

        add(title: "Permutation raised(to: 3)", input: [Int].self) { input in
            let permutation: Permutation = Permutation(shuffles: input.count)
            return { timer in
                timer.measure { blackHole(permutation.raised(to: 3)) }
            }
        }

        add(title: "Permutation insert(at:) middle", input: [Int].self) { input in
            let permutation: Permutation = Permutation(shuffles: input.count)
            return { timer in
                var copy: Permutation = permutation
                timer.measure { copy.insert(at: input.count / 2) }
                blackHole(copy)
            }
        }

        add(title: "Permutation init(shuffles:) riffle", input: [Int].self) { input in
            return { timer in
                timer.measure { blackHole(Permutation(shuffles: input.count, .riffle)) }
            }
        }

        add(title: "Permutation forEachMove random", input: [Int].self) { input in
            let permutation: Permutation = Permutation(shuffles: input.count)
            return { timer in
                var total: Int = 0
                timer.measure { permutation.forEachMove { from, to in total &+= from &+ to } }
                blackHole(total)
            }
        }

        // MARK: Applying

        add(title: "Array<Int> apply(_:) random permutation", input: [Int].self) { input in
            let permutation: Permutation = Permutation(shuffles: input.count)
            return { timer in
                var array: [Int] = input
                array.reserveCapacity(input.count)
                timer.measure { array.apply(permutation) }
                blackHole(array)
            }
        }

        add(title: "IdentifiedSet<Record> move(fromOffsets:) last to next to last", input: [Record].self) { input in
            return { timer in
                var set: IdentifiedSet<Record> = IdentifiedSet(input)
                set.reserveCapacity(input.count)
                let last: Int = Swift.max(input.count - 1, 0)
                timer.measure { set.move(fromOffsets: [last], toOffset: Swift.max(last - 1, 0)) }
                blackHole(set)
            }
        }
    }
}
