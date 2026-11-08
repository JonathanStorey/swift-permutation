# ``Permutation/Permutation``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

A reorder held as a value: where each element of a collection goes.

## Overview

Every reorder in this package, whether a sort, a shuffle, a reverse or a move, hands back a `Permutation` describing what it did. `Permutation` is a value type that conforms to `Hashable`, `Codable` and `Sendable`, so you can store it in a property, compare it, encode it to disk or send it over the network, and act on it after the fact.

```swift
var tasks: IdentifiedSet<Task> = loadTasks()

let byDate: Permutation = tasks.sort { $0.due < $1.due }
let byPriority: Permutation = tasks.sort { $0.priority > $1.priority }

let both: Permutation = byDate.followed(by: byPriority)  // two reorders folded into one
tasks.apply(both.inverted)                               // undo both in one step
```

### Undo, combine and repeat

``inverted`` returns the permutation that puts every element back, so undo is a single call. ``followed(by:)`` folds a string of reorders into one, so an edit history of any length collapses to one value. ``raised(to:)`` repeats a reorder any number of times, including a negative number, in one pass over its cycles however large the exponent.

### Build one without touching the collection

To reorder without mutating, build the permutation first and apply it wherever you like. A parallel array follows along:

```swift
let order: Permutation = Permutation(sorting: scores, by: >)
let rankedScores: [Int] = scores.applying(order)
let rankedNames: [String] = names.applying(order)
```

``random(count:)`` and the other shuffle styles, along with ``init(reversing:)``, do the same for shuffles and reversals. ``init(_:)`` reads a pure reorder back out of a `CollectionDifference`, returning `nil` when the difference also inserts or removes elements.

### Replay a reorder

``moves`` replays a permutation as the fewest single-element moves, which is what a list animation or a remote sync wants. A user who drags one row produces one move, however long the list. ``swaps`` replays it as the fewest exchanges.

```swift
for move in both.moves {
    server.send(.move(from: move.from, to: move.to))
}
```

### Keep a stored permutation in step

A permutation stored beside a collection must change when the collection does. ``insert(at:)``, ``remove(at:)`` and ``replaceSubrange(_:withCount:)`` keep it valid as elements arrive and leave: an inserted offset stays in place, and a removed one leaves its cycle.

### Merge reorders made on two devices

``merging(with:from:)`` combines two reorders of the same base, returning `nil` when both sides moved the same offset in different ways. ``merging(with:from:by:)`` never fails. With ``MergeStrategy/relativeOrder``, it keeps every pair of elements either side reordered and gives up only pairs neither side touched, in O(n log n).

```swift
// Apply every insertion and removal to base, local and server first.
let synced: Permutation = local.merging(with: server, from: base, by: .relativeOrder)
```

### Count through every order

Every permutation of `n` elements has a place among all `n!` of them, its ``rank``, which never overflows. ``init(rank:)`` jumps straight to any place, ``advanced(by:)`` steps from one to the next, and ``permutations(count:)`` walks them all lazily, so a search can stop at the first match.

### How it is stored

A permutation is stored in Foata's single-line notation: its cycles written one after another, each starting at its largest offset, in increasing order of those offsets. Offsets it doesn't mention stay put, so one permutation applies to any collection at least ``minimumCount`` long, and moving two rows of a list of a million stores two numbers. ``cycles`` reads the cycles straight off that line, along with their ``Cycles/order``, ``Cycles/parity`` and whether the permutation is an ``Cycles/isInvolution``.

## Topics

### Creating a Permutation

- ``init()``
- ``init(cycles:)``
- ``init(sorting:)``
- ``init(sorting:by:)``
- ``init(reversing:)``
- ``init(_:)``

### Creating a Shuffle

- ``random(count:)``
- ``random(count:using:)``
- ``cyclic(count:)``
- ``cyclic(count:using:)``
- ``derangement(count:)``
- ``derangement(count:using:)``
- ``riffle(count:)``
- ``riffle(count:using:)``
- ``outFaro(count:)``
- ``inFaro(count:)``
- ``Shuffle``
- ``shuffle(_:)``
- ``shuffle(_:using:)``
- ``shuffled(_:)``
- ``shuffled(_:using:)``

### Inspecting a Permutation

- ``subscript(_:)``
- ``minimumCount``
- ``cycles``
- ``Cycles``
- ``Parity``

### Combining Permutations

- ``inverted``
- ``followed(by:)``
- ``raise(to:)``
- ``raised(to:)``
- ``swapping(_:_:)``

### Replaying a Permutation

- ``moves``
- ``Move``
- ``Moves``
- ``swaps``
- ``Swap``
- ``Swaps``

### Merging Permutations

- ``merging(with:)``
- ``merging(with:from:)``
- ``merging(with:by:)``
- ``merging(with:from:by:)``
- ``MergeStrategy``

### Following a Changing Collection

- ``insert(at:)``
- ``insert(count:at:)``
- ``remove(at:)``
- ``removeSubrange(_:)``
- ``replaceSubrange(_:withCount:)``

### Ranking and Stepping

- ``rank``
- ``init(rank:)``
- ``Rank``
- ``advanced(by:)``
- ``advance(by:)``
- ``distance(to:)``
- ``permutations(count:)``
- ``Permutations``

### Describing a Permutation

- ``description``
- ``debugDescription``
