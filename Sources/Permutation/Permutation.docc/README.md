# ``Permutation``

Reorder collections and keep each reorder as a value you can undo, combine, replay, store and merge.

## Overview

A sort, a shuffle or a drag-and-drop move is a *permutation*: a rule that says where each element of a collection goes. The standard library performs these reorders and discards the rule. This package keeps it. Every reorder returns a ``Permutation``, a value type you can invert to undo the reorder, compose with other reorders, replay as the fewest moves for an animation or a sync, apply to a second collection, encode, and merge with a reorder made on another device.

Most reordering in Swift happens through `MutableCollection`, which requires a collection to accept any element at any position. Sets, dictionaries and collections of identifiable elements can't make that guarantee without risking duplicates, so they can't sort or shuffle in place. ``PermutableCollection`` requires only that a collection can exchange two of its elements, which every ordered collection can do safely. The package provides four collections that conform to it, ``Arrangement``, ``IdentifiedSet``, ``PermutableSet`` and ``PermutableDictionary``. Each stores its elements in an array that reordering never changes and reorders a table of offsets instead, so the cost of a reorder doesn't depend on the size of the elements.

The sections below show the package at work in common scenarios.

### Undo a reorder

Assign the result of any reorder to keep its permutation. The collection is reordered in place either way, and ``Permutation/inverted`` undoes the reorder in one call.

```swift
var players: IdentifiedSet<Player> = [ann, bob, cy]

let ranking: Permutation = players.sort { $0.score > $1.score }
players.apply(ranking.inverted)  // back to the order before the sort
```

``Permutation/followed(by:)`` folds a series of reorders into one permutation, so an undo stack of any depth collapses to a single value:

```swift
let byDate: Permutation = tasks.sort { $0.due < $1.due }
let byPriority: Permutation = tasks.sort { $0.priority > $1.priority }
let history: Permutation = byDate.followed(by: byPriority)
tasks.apply(history.inverted)  // undoes both sorts
```

### Build a reorderable SwiftUI list

``IdentifiedSet`` holds `Identifiable` elements with constant-time lookup, insertion and removal by id, and refuses a second element with the same id, which is the guarantee SwiftUI's `List` and `ForEach` rely on. Its `move(fromOffsets:toOffset:)` and `remove(atOffsets:)` take the arguments of `onMove` and `onDelete` directly, and `$roster.elements()` gives each row a binding that follows its element by id through every reorder.

```swift
struct RosterView: View {
    @State private var roster: IdentifiedSet<Player> = []

    var body: some View {
        List {
            ForEach($roster.elements()) { $player in
                Stepper(player.name, value: $player.score)
            }
            .onMove { roster.move(fromOffsets: $0, toOffset: $1) }
            .onDelete { roster.remove(atOffsets: $0) }
        }
    }
}
```

Adding and updating elements uses the vocabulary of ``UpsertableCollection``:

```swift
roster.append(ann)                   // false when the id is already present
roster.update(orAppend: changedBob)  // replaces in place, or appends
roster[id: ann.id]?.score += 1       // edits through the id
```

### Sort by more than one property

`sort(using:)` takes a Foundation `SortDescriptor` or `KeyPathComparator`, or an array of them in which each one breaks the ties of the ones before it. Like every reorder, it returns the permutation it applied.

```swift
let order: Permutation = roster.sort(using: [SortDescriptor(\.lastName), SortDescriptor(\.firstName)])
```

### Reorder parallel arrays together

A permutation describes positions, not elements, so it reorders any collection that is long enough. Compute a permutation from one collection without changing it, then apply it to each collection that needs to stay aligned.

```swift
let order: Permutation = Permutation(sorting: scores, by: >)
let rankedScores: [Int] = scores.applying(order)
let rankedNames: [String] = names.applying(order)
```

``Permutation/random(count:)``, ``Permutation/derangement(count:)``, ``Permutation/init(reversing:)`` and the other initializers and shuffle styles build permutations the same way.

### Animate or sync a reorder with the fewest moves

``Permutation/moves`` replays a permutation as the fewest single-element moves, in the order to perform them, which is what a list animation or a server update needs. A user who drags one row produces one move, however long the list. ``Permutation/swaps`` replays it as the fewest exchanges instead.

```swift
for move in history.moves {
    server.send(.move(from: move.from, to: move.to))
}
```

Going the other way, ``Permutation/init(_:)`` reads a pure reorder out of a `CollectionDifference`, and returns `nil` when the difference also inserts or removes elements.

```swift
let reorder: Permutation? = Permutation(newOrder.difference(from: oldOrder))
```

### Reorder large elements without copying them

``Arrangement`` is a fixed list of elements that can only be reordered. Its elements need not be `Hashable` or even `Equatable`, and they never move in memory, so sorting a list of large images costs the same as sorting a list of numbers. Because the stored order never changes, an arrangement always knows the ``Arrangement/permutation`` from its original order, and setting that property restores any saved order in one step.

```swift
var photos: Arrangement<Photo> = Arrangement(album)
photos.sort { $0.date < $1.date }
let curated: Permutation = photos.permutation  // save the order
photos.shuffle()                               // a slideshow
photos.permutation = curated                   // restore the saved order
photos.permutation = Permutation()             // back to the original order
```

### Try every order of a small collection

``Arrangement/permutations`` walks every order of an arrangement lazily, in rank order, without changing the arrangement, so a search can stop at the first match.

```swift
let guests: Arrangement<String> = ["Ann", "Bob", "Cy", "Dee"]
let plan = guests.permutations.first { $0.first == "Dee" && $0.last == "Ann" }
```

Each order has a place among all `n!` orders, its ``Permutation/rank``, which never overflows. ``Permutation/init(rank:)`` jumps to any place, and ``Permutation/advanced(by:)`` steps from one order to the next.

### Keep an ordered set of unique values

``PermutableSet`` holds unique `Hashable` elements in an order you control, with constant-time membership tests. It offers only the set operations whose result has a clear order: elements kept from the receiver stay in its order, and new elements follow in the order of the argument.

```swift
var tags: PermutableSet<String> = ["swift", "ios", "math"]
tags.formUnion(["math", "cs"])  // ["swift", "ios", "math", "cs"]
tags.subtract(["ios"])          // ["swift", "math", "cs"]
let alphabetical: Permutation = tags.sort()
```

### Sort a dictionary without separating keys from values

``PermutableDictionary`` is an ordered dictionary with constant-time lookup, insertion and removal by key. Every reorder moves whole entries, whether you sort the dictionary, its ``PermutableDictionary/keys`` or its ``PermutableDictionary/values``, so each key stays paired with its value. Reassigning values among keys that stay in place is a separate operation.

```swift
var scores: PermutableDictionary<String, Int> = ["ann": 3, "bob": 9, "cy": 5]
scores.keys.sort()                   // by key: ["ann": 3, "bob": 9, "cy": 5]
scores.values.sort()                 // by value: ["ann": 3, "cy": 5, "bob": 9]
scores.sort { $0.value > $1.value }  // any order: ["bob": 9, "cy": 5, "ann": 3]

var santas = PermutableDictionary(uniqueKeys: friends, values: friends)
santas.reassignValues(shuffling: .derangement)  // no one draws their own name
```

### Merge reorders made on two devices

A permutation stored beside a collection stays valid as the collection changes when you call ``Permutation/insert(at:)`` and ``Permutation/remove(at:)`` at the same offsets. ``Permutation/merging(with:from:by:)`` then combines the order changed on two devices. With ``Permutation/MergeStrategy/relativeOrder``, it keeps every pair of elements that either side reordered and never fails. <doc:Syncing-a-reordered-list-across-devices> walks through the whole design.

```swift
let merged: Permutation = local.merging(with: server, from: base, by: .relativeOrder)
```

### Inspect the structure of a reorder

A permutation is stored in Foata's single-line notation, its cycles written one after another, so it records only the offsets it moves. ``Permutation/cycles`` reads those cycles along with the properties that depend on them.

```swift
history.cycles              // standard cycle notation, such as (2 0)(5 3 4)
history.cycles.order        // how many times to repeat the reorder to restore the order
history.cycles.parity       // .even or .odd
history[0]                  // the offset where the element at offset 0 lands
```

### Make your own collection reorderable

To make a collection type of your own reorderable, conform it to ``PermutableCollection`` by implementing ``PermutableCollection/swapAt(_:_:)``. The collection then gets every reorder above, each returning its permutation. A collection that can move a whole cycle at once can also implement ``PermutableCollection/apply(_:)`` to make every reorder as fast as that one method.

```swift
extension Playlist: PermutableCollection {
    mutating func swapAt(_ i: Int, _ j: Int) {
        songs.swapAt(i, j)
    }
}
```

### Performance

Every collection in this package stores its elements in an array that reordering never changes, and reorders a table of 4-byte offsets instead. A sort, shuffle, reverse or rotate therefore moves offsets rather than elements, and leaves the hash index untouched, so the speedups grow with the size of the elements.

| Reorder | ``Arrangement`` vs `Array` | ``PermutableSet`` vs `OrderedSet` | ``IdentifiedSet`` vs `IdentifiedArray` |
| --- | ---: | ---: | ---: |
| Sort | 1.6× faster | 1.1× faster | 9.2× faster |
| Shuffle | 2.3× faster | 3.9× faster | 11× faster |
| Reverse | 2.8× faster | 9.8× faster | 15× faster |
| Rotate | 1.3× faster | 11× faster | 110× faster |
| Move one element | 2.0× faster | 2.4× slower | 187× faster |

Some reorders skip the elements entirely and work on the permutation's cycles. Repeating a shuffle 1,000 times on an `Array` of 16,384 records takes 444 ms. Raising the shuffle to the 1,000th power with ``Permutation/raised(to:)`` and applying it once takes 163 µs, about 2,700× faster.

Each figure is the median of 201 runs at 16,384 elements, in a release build on Apple silicon. ``Arrangement`` and ``IdentifiedSet`` hold a typical app model with a UUID id, an integer sort key and 64 bytes of other fields, and ``PermutableSet`` holds `Int` values. `OrderedSet` comes from swift-collections and `IdentifiedArray` from Point-Free's swift-identified-collections. The [benchmark results](https://github.com/JonathanStorey/swift-permutation/blob/main/Benchmarks/RESULTS.md) have the full tables, charts and the steps to reproduce them.

### Results from combinatorics and probability

The package's types make classic results about permutations a few lines of code each. The Examples package runs each one and explains the mathematics behind it.

- [Derangements](https://github.com/JonathanStorey/swift-permutation/blob/main/Examples/Docs/Derangements.md): When `n` coats are returned at random, the probability that no one receives their own tends to 1/e, about 36.8%, and barely changes between 10 guests and a million.
- [The 100 prisoners problem](https://github.com/JonathanStorey/swift-permutation/blob/main/Examples/Docs/HundredPrisoners.md): A strategy that follows cycles frees all 100 prisoners 31% of the time, when random guessing succeeds with probability about 10⁻³⁰.
- [Perfect shuffles](https://github.com/JonathanStorey/swift-permutation/blob/main/Examples/Docs/FaroShuffles.md): Eight out-faro shuffles restore a 52-card deck and in-faro shuffles need 52, each the least common multiple of the shuffle's cycle lengths.
- [The 15 puzzle](https://github.com/JonathanStorey/swift-permutation/blob/main/Examples/Docs/FifteenPuzzle.md): Every slide changes the parity of the arrangement, so half of all starting positions, including Sam Loyd's 14–15 swap, can't be solved.
- [Ulam's problem](https://github.com/JonathanStorey/swift-permutation/blob/main/Examples/Docs/UlamsProblem.md): The longest increasing run in a random permutation of `n` elements has length about 2√n, and its complement is the fewest moves that sort a list, which ``Permutation/moves`` uses.
- [Secret Santa](https://github.com/JonathanStorey/swift-permutation/blob/main/Examples/Docs/SecretSanta.md): A uniformly random derangement forms a single cycle through everyone with probability about e/n.
- [Pi from shuffles](https://github.com/JonathanStorey/swift-permutation/blob/main/Examples/Docs/PiFromShuffles.md): The probability that every cycle of a random permutation has even length equals the probability of an even split in coin flips, and Wallis's product turns it into an estimate of π.

## Topics

### Essentials

- <doc:Recording-and-undoing-reorders>
- ``Permutation``
- ``PermutableCollection``

### Collections

- ``Arrangement``
- ``IdentifiedSet``
- ``PermutableSet``
- ``PermutableDictionary``

### Unique elements

- ``UpsertableCollection``

### Synchronization

- <doc:Syncing-a-reordered-list-across-devices>
