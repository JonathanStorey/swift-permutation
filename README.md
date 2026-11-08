# Permutation

Reorder Swift collections and get back the reorder itself as a value you can undo, store, compose and merge.

## Introduction

A list is sorted by date, a playlist is shuffled or a user drags a row to a new spot. Each of those changes is a **permutation**, a rule specifying the precise arrangement of each element. Mathematicians treat a permutation as an object you can hold, reverse and combine. The Swift standard library has no such object. Without it, one can still perform a reorder, but the record of what happened is gone.

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

- [Introduction](#introduction)
- [Requirements](#requirements)
- [Installation](#installation)
- [A quick tour](#a-quick-tour)
- [Documentation](#documentation)
- [Performance](#performance)
- [Development](#development)
- [Seven classic problems about permutations](#seven-classic-problems-about-permutations)

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

This is the record of the reordering. Where the standard library performs a reorder and forgets it, a `Permutation` holds it as a `Hashable`, `Codable` value type you can store in a property, compare, save to disk or send over the network.

It is stored in **Foata's single-line notation**: the cycles written one after another, each starting at its largest offset, in increasing order of those offsets. Offsets it doesn't mention stay put, so a single `Permutation` applies to any collection that is long enough.

```swift
var tasks: IdentifiedSet<Task> = loadTasks()

let byDate: Permutation = tasks.sort { $0.due < $1.due }  // every reorder returns one
let byPriority: Permutation = tasks.sort { $0.priority > $1.priority }

let both: Permutation = byDate.followed(by: byPriority)  // composition: two reorders as one
tasks.apply(both.inverted)                               // inverse: undo both in one step

both.moves                  // the fewest single-row moves that replay it, for an animation or a sync
both.swaps                  // the fewest exchanges that replay it
both.cycles                 // printed in standard notation like (2 0)(5 3 4)
both[0]                     // where the element at offset 0 went
let merged: Permutation? = mine.merging(with: theirs, from: base)  // three-way merge, nil on a conflict
let synced: Permutation = mine.merging(with: theirs, from: base, by: .relativeOrder)  // never fails
```

Because the reorder is an object, you can do things with it after the fact. `inverted` is a one-line undo, and `followed(by:)` folds a string of edits into one. `moves` replays any permutation as the fewest single-element moves, which is what a list animation or a remote sync wants, and `swaps` replays it as the fewest exchanges. Going the other way, `Permutation(new.difference(from: old))` reads a pure reorder back out of a `CollectionDifference`. `insert(at:)`, `remove(at:)` and `replaceSubrange(_:withCount:)` keep a stored permutation valid while the collection it describes grows and shrinks, so a synced order can apply every insertion and removal to base, mine and theirs and then merge with `.relativeOrder`. That merge keeps every pair either side reordered and gives up only pairs neither side touched, in O(n log n).

Full reference: [Permutation](Sources/Permutation/Permutation.docc/Permutation.md)

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

Every one of these still works in place, so nothing is copied, but unlike the standard library's versions, each one hands back what it did. When a type is also a `MutableCollection`, a call to `sort` or `reverse` that discards its result uses the standard library's in-place implementation. A call whose result is used as a `Permutation`, such as `let ranking: Permutation = tiles.sort()`, computes the permutation and applies it through `apply(_:)` instead.

To reorder without mutating, build the permutation first and apply it wherever you like. The original stays as it is:

```swift
let order: Permutation = Permutation(sorting: scores, by: >)
let ranked: [Int] = scores.applying(order)
let rankedNames: [String] = names.applying(order)    // a parallel array follows along
```

`Permutation.random(count:)`, `Permutation.derangement(count:)` and the other shuffle styles, along with `Permutation(reversing:)`, do the same for shuffles and reversals.

`sort(using:)` and `Permutation(sorting:using:)` take a Foundation `SortDescriptor` or `KeyPathComparator`, or an array of them in which each one breaks the ties of the ones before it:

```swift
let order: Permutation = roster.sort(using: [SortDescriptor(\.lastName), SortDescriptor(\.firstName)])
```

Full reference: [PermutableCollection](Sources/Permutation/Permutation.docc/PermutableCollection.md)

### `Arrangement`

The simplest `PermutableCollection` is a fixed list of elements that can only be reordered. Nothing can be added, removed or overwritten, which is exactly the guarantee `MutableCollection` can't make. The elements need not be `Hashable` or even `Equatable`, and since they never move in memory, an arrangement always remembers its starting order and knows the single permutation that took it from there to the order shown.

```swift
var photos: Arrangement<Photo> = Arrangement(album)  // large images, never copied
photos.sort { $0.date < $1.date }
photos.shuffle()
photos.permutation                  // every reorder so far, folded into one
photos.permutation.cycles.isEmpty   // false: the reorders haven't cancelled out
photos.permutation = Permutation()  // back to the original order in one step
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

`permutations` walks the same `n!` orders lazily in that rank order, starting from the original order, without touching the arrangement, so a search can stop with `break` or `first(where:)`:

```swift
for order in hand.permutations { print(order) }          // all 6 orders; the k-th has permutation == Permutation(rank: k)
let found = hand.permutations.first { $0.first == "c" }  // stops at the first match
```

Full reference: [Arrangement](Sources/Permutation/Permutation.docc/Arrangement.md)

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

Full reference: [IdentifiedSet](Sources/Permutation/Permutation.docc/IdentifiedSet.md)

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

Full reference: [PermutableSet](Sources/Permutation/Permutation.docc/PermutableSet.md)

### `PermutableDictionary`

An ordered dictionary with O(1) lookup, insertion and removal by key, whose keys are an `Arrangement`. Every reorder moves whole entries, whether you sort the dictionary, its `keys` or its `values`, so each key stays paired with its value. Reassigning values among keys that stay in place is a separate operation, `reassignValues`:

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

Full reference: [PermutableDictionary](Sources/Permutation/Permutation.docc/PermutableDictionary.md)

## Documentation

Each type has a reference page in the style of Apple's documentation, with an overview and every member grouped by task. The pages are a [DocC](https://www.swift.org/documentation/docc/) catalog, so they read as Markdown on GitHub and build into browsable documentation with Xcode's **Product › Build Documentation**.

Start with the [package overview](Sources/Permutation/Permutation.docc/README.md), then two guides: [Recording and undoing reorders](Sources/Permutation/Permutation.docc/Recording-and-undoing-reorders.md) and [Syncing a reordered list across devices](Sources/Permutation/Permutation.docc/Syncing-a-reordered-list-across-devices.md).

| Type | What it is |
| --- | --- |
| [`Permutation`](Sources/Permutation/Permutation.docc/Permutation.md) | A reorder held as a value |
| [`PermutableCollection`](Sources/Permutation/Permutation.docc/PermutableCollection.md) | The protocol for collections that reorder by swapping |
| [`UpsertableCollection`](Sources/Permutation/Permutation.docc/UpsertableCollection.md) | The protocol for collections that hold each element once |
| [`Arrangement`](Sources/Permutation/Permutation.docc/Arrangement.md) | A fixed list that can only be reordered |
| [`IdentifiedSet`](Sources/Permutation/Permutation.docc/IdentifiedSet.md) | Identifiable elements with O(1) lookup by id |
| [`PermutableSet`](Sources/Permutation/Permutation.docc/PermutableSet.md) | An ordered set of hashable elements |
| [`PermutableDictionary`](Sources/Permutation/Permutation.docc/PermutableDictionary.md) | An ordered dictionary whose entries move together |

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

The [Examples](Examples) package runs the classic problems below:

```sh
cd Examples
swift run -c release FunFacts
```

## Seven classic problems about permutations

Each is a famous question with a surprising answer, solved in a few lines of code in the [Examples](Examples) package, with a page explaining the mathematics. Three of them turn out to be about Euler's number, e.

1. **The hat-check problem.** n hats are handed back at random. How likely is it that nobody gets their own? Montmort asked in 1708, and the answer is the series for 1/e itself, 1 − 1/1! + 1/2! − 1/3! + …, cut off after n terms. It is 36.8% for 10 guests and still 36.8% for a million. Euler's number runs all through it: the number of people who do get their own hat follows a Poisson law with mean exactly 1, and redrawing until nobody matches takes e tries on average. → [The hat-check problem](Examples/Docs/HatCheckProblem.md)
2. **The 100 prisoners problem.** Each of 100 prisoners may open half of 100 drawers to find their own number, and all go free only if everyone succeeds. Guessing wins with probability (1/2)^100, about 10^−30. Following the cycles of the drawer permutation wins 31% of the time, 1 − ln 2 in the limit, where ln is the logarithm to base e. → [The 100 prisoners problem](Examples/Docs/HundredPrisoners.md)
3. **The perfect shuffle problem.** How many perfect shuffles restore a 52-card deck? Eight out-faros do it, but in-faros need 52. Both numbers are the least common multiple of the shuffle's cycle lengths. → [The perfect shuffle problem](Examples/Docs/FaroShuffles.md)
4. **The 15 puzzle.** Can every scrambled board be solved? No. Every slide flips the parity of the arrangement, so exactly half of all positions, including Sam Loyd's famous 14–15 swap, are impossible. → [The 15 puzzle](Examples/Docs/FifteenPuzzle.md)
5. **Ulam's problem.** How long is the longest increasing run hidden in a shuffled deck? About 2√n, with fluctuations from random matrix theory. Its complement is the fewest moves that sort a list, which `moves` uses. → [Ulam's problem](Examples/Docs/UlamsProblem.md)
6. **Secret Santa.** Friends redraw from the hat until nobody holds their own name. That takes e ≈ 2.7 draws on average, and even then the gifts form one unbroken chain through everyone only e/n of the time. → [Secret Santa](Examples/Docs/SecretSanta.md)
7. **Wallis's product.** The chance that every cycle of a shuffled 20-card deck has even length equals the chance of 10 heads in 20 coin flips, and Wallis's 1656 product turns it into π. A million shuffles give 3.14. → [Wallis's product from shuffled cards](Examples/Docs/PiFromShuffles.md)

## License

See [LICENSE](LICENSE).
