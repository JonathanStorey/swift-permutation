# Permutation

Reorder Swift collections and get back the reorder itself as a value you can undo, store, compose and merge.

## Why permutations

A list is sorted by date, a playlist is shuffled or a user drags a row to a new spot. Each of those changes is a **permutation**, a rule to arrange the order of each element. Mathematicians treat a permutation as an object you can hold, reverse and combine. The Swift standard library has no such object. Without it, one can still perform a reorder, but once the shuffling is done, the record of what happened is gone.

Most reordering in Swift is performed within a collection that conforms to `MutableCollection`. However, this ability to sort comes with the promise of "mutability", which allows any element of the collection to be overwritten at any time. While this works in many situations, there are collection types that can't safely make that promise of "mutability". For example, an ordered set can't hold the same element twice. In SwiftUI, a `List` also misbehaves if two elements share the same identifier.

This package allows one to separate the act of reordering from mutation while simultaneously preserving the details of the sort. `Permutation` is the small value type that records the details of a reorder. Every sort, shuffle, reverse and move returns one, so the information is kept. You can invert it to undo, combine two of them into one, replay it as the fewest drag-and-drop moves, or apply it to a second collection so the two stay in step.

Meanwhile, our base protocol `PermutableCollection` only requires that a collection can swap two of its elements. Unlike `MutableCollection`, it never needs to overwrite them, so sets, dictionaries and identified collections can reorder freely without risking their rules. By focusing on permutation, our collections (`Arrangement`, `IdentifiedSet`, `PermutableSet` and `PermutableDictionary`) outperform the standard library and other competing packages on most reordering operations.

```swift
import Permutation

var players: IdentifiedSet<Player> = [ann, bob, cy]

let ranking: Permutation = players.sort { $0.score > $1.score }  // reorders, returns what it did
players.apply(ranking.inverted)                                   // undo in one call
```

The package provides four collections: `Arrangement`, `IdentifiedSet`, `PermutableSet` and `PermutableDictionary`.

## Contents

- [Why permutations](#why-permutations)
- [Requirements](#requirements)
- [Installation](#installation)
- [A quick tour](#a-quick-tour)
- [Performance](#performance)
- [Development](#development)
- [Seven fun facts about permutations](#seven-fun-facts-about-permutations)

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

This is the record of the reordering. Where the standard library performs a reorder and forgets it, a `Permutation` holds it as an ordinary value you can keep in a property, compare, save to disk or send over the network.

It is stored in **Foata's single-line notation**: the cycles written one after another, each starting at its largest offset, in increasing order of those offsets. Offsets it doesn't mention stay put, so a single `Permutation` applies to any collection that is long enough.

```swift
let faro: Permutation = Permutation(shuffles: 52, .outFaro)
faro.order          // 8, the least common multiple of the cycle lengths
faro.isEven         // parity, read straight off the line
faro.cycleLengths   // lengths of the cycles, in one pass
faro[0]             // where the element at offset 0 goes

let both: Permutation = first.followed(by: second)  // composition
let undo: Permutation = both.inverted               // inverse
let cubed: Permutation = faro.raised(to: 3)         // powers, negative too
let next: Permutation = faro.advanced(by: 1)        // the next permutation, one cheap step
let place: Permutation.Rank = faro.rank             // its place among all permutations, never overflows
let far: Permutation = Permutation(rank: 1_000_000_000)  // jump straight to any place
let merged: Permutation? = mine.merging(with: theirs, from: base)  // three-way merge of reorders
```

Because the reorder is an object, you can do things with it after the fact. `inverted` is a one-line undo, and `followed(by:)` folds a string of edits into one. `forEachMove` replays any permutation as the fewest single-element moves, which is what a list animation or a remote sync wants. `insert(at:)`, `remove(at:)` and `replaceSubrange(_:withCount:)` keep a stored permutation valid while the collection it describes grows and shrinks.

### `PermutableCollection`

This is the protocol the standard library skipped over. `MutableCollection` asks a collection to accept any new element at any position, a promise that sets, dictionaries and identified collections can't keep without risking duplicates. `PermutableCollection` asks only that two elements trade places, which every ordered collection can do safely.

It has two requirements, `apply(_:)` and `swapAt(_:_:)`, and in return supplies every reorder below, each returning its `Permutation`:

| Method | Returns |
| --- | --- |
| `sort()`, `sort(by:)`, `sort(using:)` | the permutation that sorted it |
| `shuffle(_:)` | random, cyclic, derangement, riffle, or out- and in-faro |
| `reverse()`, `rotate(toStartAt:)` | the permutation applied |
| `move(from:to:)`, `move(fromOffsets:toOffset:)` | ready for SwiftUI's `onMove` |
| `swap(_:_:)` | a single transposition |
| `stablePartition(by:)` | the partition index |

Every one of these still works in place, so nothing is copied, but unlike the standard library's versions, each one hands back what it did. A type that is also a `MutableCollection` keeps the standard library's in-place `sort` and `reverse`, and gets the permutation only by asking for one: `let ranking: Permutation = tiles.sort()`.

To reorder without mutating, build the permutation first and apply it wherever you like. The original stays as it is:

```swift
let order: Permutation = Permutation(sorting: scores, by: >)
let ranked: [Int] = scores.applying(order)
let rankedNames: [String] = names.applying(order)    // a parallel array follows along
```

`Permutation(shuffles:)` and `Permutation(reversing:)` do the same for shuffles and reversals.

`sort(using:)` and `Permutation(sorting:using:)` take a Foundation `SortDescriptor` or `KeyPathComparator`, or an array of them in which each one breaks the ties of the ones before it:

```swift
let order: Permutation = roster.sort(using: [SortDescriptor(\.lastName), SortDescriptor(\.firstName)])
```

### `Arrangement`

The simplest `PermutableCollection` is a fixed list of elements that can only be reordered. Nothing can be added, removed or overwritten, which is exactly the guarantee `MutableCollection` can't make. The elements need not be `Hashable` or even `Equatable`, and since they never move in memory, an arrangement always remembers its starting order and knows the single permutation that took it from there to the order shown.

```swift
var deck: Arrangement<Card> = Arrangement(newDeck)
deck.shuffle(.outFaro)
deck.permutation          // every reorder so far, folded into one
deck.isInOriginalOrder    // true again after 8 out-faros
deck.permutation = Permutation()  // back to the original order in one step
```

`advance(by:)` steps a permutation to the next one with a few swaps on its Foata line. Starting from the identity, the first `n!` steps visit every order of `n` elements:

```swift
var hand: Arrangement<String> = ["a", "b", "c"]
var order: Permutation = Permutation()
for _ in 0..<6 {                  // 3! orders
    hand.permutation = order
    print(hand)
    order.advance(by: 1)
}
```

`forEachPermutation` walks the same `n!` orders in place, one swap apart, and puts the elements back when it finishes:

```swift
hand.forEachPermutation { print(Array($0)) }  // all 6 orders, starting with the current one
```

### `IdentifiedSet`

An ordered collection of `Identifiable` elements with O(1) lookup, insertion and removal by id, built for SwiftUI's `List` and `ForEach`. Element binding is supported as well, working through the ID rather than the index. Reordering a list of large models is as cheap as reordering numbers, and the permutation it returns is what you need to undo the change or animate it. It conforms to `PermutableCollection` and `UpsertableCollection`.

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

The same storage with each `Hashable` element as its own key. It only offers the set operations whose result has a clear order. The receiver's elements keep their order, and new elements follow in the order of the argument.

```swift
var tags: PermutableSet<String> = ["swift", "ios", "math"]
tags.formUnion(["math", "cs"])       // ["swift", "ios", "math", "cs"]
tags.subtract(["ios"])               // ["swift", "math", "cs"]
tags.isSubset(of: allTags)
let order: Permutation = tags.sort()
```

`PermutableSet` does not conform to `SetAlgebra`, because `==` respects order, which breaks the laws of `SetAlgebra`.

### `PermutableDictionary`

An ordered dictionary with O(1) lookup, insertion and removal by key, whose keys are an `Arrangement`. Every reorder moves whole entries, whether you sort the dictionary, its `keys` or its `values`, so a key never loses its value by accident. Handing values around while the keys stay put is a separate, deliberately named operation:

```swift
var scores: PermutableDictionary<String, Int> = ["ann": 3, "bob": 9, "cy": 5]
scores.keys.sort()               // moves whole entries: ["ann": 3, "bob": 9, "cy": 5]
scores.values.sort()             // sorts by value, ties keep their order: ["ann": 3, "cy": 5, "bob": 9]
scores.values.sorted()           // just the values, dictionary untouched: [3, 5, 9]
scores.sort { $0.value > $1.value }  // any order you like: ["bob": 9, "cy": 5, "ann": 3]
scores["dee", default: 0] += 1   // edits in place, appending when new

var santas = PermutableDictionary(uniqueKeys: friends, values: friends)
santas.reassignValues(shuffling: .derangement)  // keys stay put: a fair Secret Santa
```

Reordering the dictionary, its `keys` or its `values` moves each key together with its value. `reassignValues` hands values around among keys that stay where they are. Neither copies a key or a value, because both live in storage that reordering never touches, and both hand back the permutation so either kind of reorder can be undone.

## Performance

[**Benchmarks/RESULTS.md**](Benchmarks/RESULTS.md) has tables and charts comparing `PermutableSet` and `PermutableDictionary` with swift-collections' `OrderedSet` and `OrderedDictionary`, and `IdentifiedSet` with Point-Free's `IdentifiedArray`. In short, removal and reordering are where moving offsets instead of elements pays off most.

## Development

```sh
swift build
swift test
```

The [Benchmarks](Benchmarks) package uses [swift-collections-benchmark](https://github.com/apple/swift-collections-benchmark). A full run takes about half an hour, so it runs from the **Benchmarks** workflow in the Actions tab, or locally:

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

## Seven fun facts about permutations

Each one is a few lines of code in the [Examples](Examples) package, with a page explaining the mathematics.

1. **Nobody gets their own coat, 36.8% of the time.** Hand back n coats at random, and the chance that nobody gets their own tends to 1/e. It barely changes between 10 guests and a million. → [Derangements](Examples/Docs/Derangements.md)
2. **100 prisoners beat (1/2)^100 by following cycles.** If each prisoner may open only half the drawers, a strategy built on cycle structure frees all of them 31% of the time, while guessing succeeds with probability about 10^−30. → [The 100 prisoners problem](Examples/Docs/HundredPrisoners.md)
3. **Eight perfect shuffles restore a deck.** Eight out-faro shuffles put 52 cards back in order, but in-faros need 52. Both numbers are the least common multiple of a cycle structure. → [Eight perfect shuffles](Examples/Docs/FaroShuffles.md)
4. **Half of all 15 puzzles are impossible.** Every slide flips the parity of the arrangement, so Sam Loyd's famous 14–15 swap can never be solved. → [The 15 puzzle](Examples/Docs/FifteenPuzzle.md)
5. **A shuffled deck hides an increasing run of about 2√n cards.** Ulam's problem links patience sorting to random matrix theory, and it also gives the fewest moves that sort a list, which `forEachMove` uses. → [Ulam's problem](Examples/Docs/UlamsProblem.md)
6. **A fair Secret Santa forms one big chain only e/n of the time.** Follow the gifts from person to person, and with ten friends the chain closes before reaching everyone almost three times in four. → [Secret Santa](Examples/Docs/SecretSanta.md)
7. **Shuffled cards know π.** The chance that every cycle of a shuffled 20-card deck has even length is the same as getting 10 heads in 20 coin flips, and Wallis's product turns it into π. A million shuffles give 3.14. → [Pi from shuffles](Examples/Docs/PiFromShuffles.md)

## License

See [LICENSE](LICENSE).
