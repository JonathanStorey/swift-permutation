import Testing
@testable import Permutation

@Suite struct ProbeOverloads {
    @Test func probe() {
        var t = Tiles(values: [3, 1, 2, 5, 4])
        let inferredSort = t.sort()
        let inferredReverse = t.reverse()
        let inferredShuffle = t.shuffle()
        print("PROBE", inferredSort, inferredReverse, inferredShuffle)
    }
}
