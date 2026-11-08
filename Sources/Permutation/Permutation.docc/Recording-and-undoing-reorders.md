# Recording and undoing reorders

Keep the permutation that each sort, shuffle and move returns, and use it to undo, combine, replay and repeat reorders.

## Overview

Every reorder of a ``PermutableCollection`` returns the ``Permutation/Permutation`` it applied. The examples below use an ``IdentifiedSet`` of tasks, but they work the same way with any collection in this package.

### Record a reorder

Assign the result of a reorder to keep its permutation. The collection is reordered in place either way.

```swift
var tasks: IdentifiedSet<Task> = loadTasks()

let byDate: Permutation = tasks.sort { $0.due < $1.due }
let byPriority: Permutation = tasks.sort { $0.priority > $1.priority }
let moved: Permutation = tasks.move(fromOffsets: [3], toOffset: 0)
```

### Undo a reorder

The ``Permutation/Permutation/inverted`` permutation returns every element to where it was before the reorder.

```swift
tasks.apply(moved.inverted)  // undoes the move
```

### Combine reorders

``Permutation/Permutation/followed(by:)`` composes two permutations into one that has the effect of applying the first and then the second. Fold an edit history into a single permutation to undo all of it in one step.

```swift
let history: Permutation = byDate.followed(by: byPriority)
tasks.apply(history.inverted)  // undoes both sorts
```

### Apply a reorder to another collection

A permutation describes positions, not elements, so it reorders any collection with at least ``Permutation/Permutation/minimumCount`` elements. Compute a permutation from one collection and apply it to a parallel one so the two stay aligned.

```swift
let order: Permutation = Permutation(sorting: scores, by: >)
let rankedScores: [Int] = scores.applying(order)
let rankedNames: [String] = names.applying(order)
```

### Replay a reorder as moves

``Permutation/Permutation/moves`` returns the fewest single-element moves that produce the permutation, in the order to perform them. Use them to animate a list or to send a reorder to a server. ``Permutation/Permutation/swaps`` returns the fewest exchanges instead.

```swift
for move in history.moves {
    server.send(.move(from: move.from, to: move.to))
}
```

### Save a reorder

`Permutation` conforms to `Codable`. It encodes only the offsets it moves, so a permutation that moves two rows of a long list encodes as two numbers.

```swift
let data: Data = try JSONEncoder().encode(history)
let restored: Permutation = try JSONDecoder().decode(Permutation.self, from: data)
```
