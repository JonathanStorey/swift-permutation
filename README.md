# Permutation

Reorder Swift collections **without moving their elements**, and get back the reorder itself as a value you can undo, store, compose and merge.

```swift
import Permutation

var players: IdentifiedSet<Player> = [ann, bob, cy]

let ranking: Permutation = players.sort { $0.score > $1.score }  // reorders, returns what it did
players.apply(ranking.inverted)                                   // undo in one call
```

Every sort, shuffle, reverse, rotate and move in this package returns a `Permutation`. Behind `IdentifiedSet` and `PermutableSet`, the elements stay where they were stored and only a small array of offsets is rewritten. A reorder costs the same whether each element is an `Int` or a 4 KB struct, and an O(1) lookup by id survives every reorder untouched.

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [A quick tour](#a-quick-tour)
- [Performance](#performance)
- [Development](#development)
- [Five fun facts about permutations](#five-fun-facts-about-permutations)

## Requirements

- Swift 6.0 or later
- iOS 17 or later, macOS 14 or later
- The optional SwiftUI `ReorderDifference` support needs the iOS 27 and macOS 27 SDKs (Swift 6.4).

## Installation

Add the package to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/JonathanStorey/swift-permutation.git", from: "0.1.0")
```

Then add `.product(name: "Permutation", package: "swift-permutation")` to your target's dependencies and `import Permutation`.

## A quick tour

### `Permutation`

A permutation stored in **Foata's single-line notation**: the cycles written one after another, each starting at its largest offset, in increasing order of those offsets. Offsets it doesn't mention stay put, so a single `Permutation` applies to any collection long enough.

```swift
let faro: Permutation = Permutation(shuffles: 52, .outFaro)
faro.order          // 8, the least common multiple of the cycle lengths
faro.isEven         // parity, read straight off the line
faro.cycleLengths   // lengths of the cycles, in one pass
faro[0]             // where the element at offset 0 goes

let both: Permutation = first.followed(by: second)  // composition
let undo: Permutation = both.inverted               // inverse
let cubed: Permutation = faro.advanced(by: 3)       // powers, negative too
let merged: Permutation? = mine.merging(with: theirs, from: base)  // three-way merge of reorders
```

`forEachMove` replays any permutation as the fewest single-element moves, which is what a list animation or a remote sync wants. `insert(at:)`, `remove(at:)` and `replaceSubrange(_:withCount:)` keep a stored permutation valid while the collection it describes grows and shrinks.

### `PermutableCollection`

A protocol with two requirements, `apply(_:)` and `swapAt(_:_:)`, that brings every reorder that returns its `Permutation`:

| Method | Returns |
| --- | --- |
| `sort()`, `sort(by:)` | the permutation that sorted it |
| `shuffle(_:)` | random, cyclic, derangement, riffle, or out- and in-faro |
| `reverse()`, `rotate(toStartAt:)` | the permutation applied |
| `move(from:to:)`, `move(fromOffsets:toOffset:)` | ready for SwiftUI's `onMove` |
| `swap(_:_:)` | a single transposition |
| `stablePartition(by:)` | the partition index |

A type that is also a `MutableCollection` keeps the standard library's in-place `sort` and `reverse`, and gets the permutation only by asking for one: `let ranking: Permutation = tiles.sort()`.

### `IdentifiedSet`

An ordered collection of `Identifiable` elements with O(1) lookup, insertion and removal by id. It conforms to `PermutableCollection` and `UpsertableCollection`.

```swift
var roster: IdentifiedSet<Player> = []
roster.append(ann)                    // false if the id is already there
roster.update(orAppend: changedBob)   // replace in place, or add
roster[id: ann.id]?.score += 1
roster.remove(atOffsets: offsets)     // ready for SwiftUI's onDelete
let moved: Permutation = roster.move(fromOffsets: source, toOffset: destination)
```

With SwiftUI, `$roster[id:]` and `$roster.elements()` give bindings that follow each element by id through every reorder.

### `PermutableSet`

The same storage with each `Hashable` element as its own key. It offers the set operations whose result has a clear order. The receiver's elements keep their order, and new elements follow in the order of the argument.

```swift
var tags: PermutableSet<String> = ["swift", "ios", "math"]
tags.formUnion(["math", "cs"])       // ["swift", "ios", "math", "cs"]
tags.subtract(["ios"])               // ["swift", "math", "cs"]
tags.isSubset(of: allTags)
let order: Permutation = tags.sort()
```

`PermutableSet` does not conform to `SetAlgebra`, because `==` respects order, which breaks SetAlgebra's laws.

## Performance

[**Benchmarks/RESULTS.md**](Benchmarks/RESULTS.md) has tables comparing `PermutableSet` with swift-collections' `OrderedSet`, and `IdentifiedSet` with Point-Free's `IdentifiedArray`, along with the charts. In short, removal and reordering are where moving offsets instead of elements pays off most.

## Development

```sh
swift build
swift test
```

The [Benchmarks](Benchmarks) package uses [swift-collections-benchmark](https://github.com/apple/swift-collections-benchmark). It takes about half an hour, so it runs from the **Benchmarks** workflow in the Actions tab, or locally:

```sh
cd Benchmarks
swift run -c release PermutationBenchmarks run results.json --cycles 3 --max-size 256k
swift run -c release PermutationBenchmarks render results.json chart.png --filter 'PermutableSet|OrderedSet'
python3 Scripts/tables.py results.json
```

The [Examples](Examples) package holds the fun facts below:

```sh
cd Examples
swift run -c release FunFacts
```

## Five fun facts about permutations

Each one is a few lines of code in the [Examples](Examples) package, with a page explaining the mathematics.

1. **Nobody gets their own coat, 36.8% of the time.** Hand back n coats at random, and the chance that nobody gets their own tends to 1/e. It barely changes between 10 guests and a million. → [Derangements](Examples/Docs/Derangements.md)
2. **100 prisoners beat (1/2)^100 by following cycles.** If each prisoner may open only half the drawers, a strategy built on cycle structure frees all of them 31% of the time, where guessing succeeds with probability about 10^−30. → [The 100 prisoners problem](Examples/Docs/HundredPrisoners.md)
3. **Eight perfect shuffles restore a deck.** Eight out-faro shuffles put 52 cards back in order, but the in-faro needs 52. Both numbers are the least common multiple of a cycle structure. → [Eight perfect shuffles](Examples/Docs/FaroShuffles.md)
4. **Half of all 15 puzzles are impossible.** Every slide flips the parity of the arrangement, so Sam Loyd's famous 14–15 swap can never be solved. → [The 15 puzzle](Examples/Docs/FifteenPuzzle.md)
5. **A shuffled deck hides an increasing run of about 2√n cards.** Ulam's problem links patience sorting to random matrix theory, and it also gives the fewest moves that sort a list, which `forEachMove` uses. → [Ulam's problem](Examples/Docs/UlamsProblem.md)

## License

See [LICENSE](LICENSE).
