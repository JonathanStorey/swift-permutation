// repository: https://github.com/JonathanStorey/swift-permutation
// path: main.swift
// dependencies: [IdentifiedSetBenchmarks.swift, Record.swift]

import CollectionsBenchmark

var benchmark: Benchmark = Benchmark(title: "Permutation")
benchmark.registerInputGenerator(for: [Record].self) { size in
    (0..<size).map(Record.init(rank:)).shuffled()
}
benchmark.addIdentifiedSetBenchmarks()
benchmark.main()
