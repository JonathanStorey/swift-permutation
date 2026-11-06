// repository: https://github.com/JonathanStorey/swift-permutation
// path: main.swift
// dependencies: [IdentifiedArrayBenchmarks.swift, IdentifiedSetBenchmarks.swift, PermutableSetBenchmarks.swift, PermutationBenchmarks.swift, Record.swift]

import CollectionsBenchmark

var benchmark: Benchmark = Benchmark(title: "Permutation")
benchmark.registerInputGenerator(for: [Record].self) { size in
    (0..<size).map(Record.init(rank:)).shuffled()
}
benchmark.registerInputGenerator(for: [Int].self) { size in
    Array(0..<size).shuffled()
}
benchmark.addIdentifiedSetBenchmarks()
benchmark.addPermutationBenchmarks()
benchmark.addPermutableSetBenchmarks()
benchmark.addIdentifiedArrayBenchmarks()
benchmark.main()
