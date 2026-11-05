import Testing
@testable import Permutation

struct ProbeTiles: MutableCollection, RandomAccessCollection, PermutableCollection {
    var values: [Int]
    var startIndex: Int { values.startIndex }
    var endIndex: Int { values.endIndex }
    subscript(position: Int) -> Int {
        get { values[position] }
        set { values[position] = newValue }
    }
}

@Suite struct ProbeOverloads {
    @Test func probe() {
        var t = ProbeTiles(values: [3, 1, 2, 5, 4])
        t.sort(by: <)
        t.sort()
        let a = t.sort(by: >)
        print("PROBE sort let:", type(of: a))
        let b: Permutation = t.sort(by: <)
        print("PROBE sort typed:", b)
        t.reverse()
        let c = t.reverse()
        print("PROBE reverse let:", type(of: c))
        t.shuffle()
        let d = t.shuffle()
        print("PROBE shuffle let:", type(of: d))
        let e = t.partition { $0 > 2 }
        print("PROBE partition:", e, t.values)
        t.apply(Permutation(reversing: 5))
        let f = t.applying(Permutation(reversing: 5))
        print("PROBE applying:", type(of: f))
        t.swapAt(0, 1)
    }
}
