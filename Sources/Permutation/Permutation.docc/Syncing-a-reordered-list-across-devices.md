# Syncing a reordered list across devices

Store the user's order as a permutation beside the items, and merge orders changed on two devices without a conflict.

## Overview

A synced list often stores its items in a stable order, such as by creation time, and stores the user's custom order separately. A ``Permutation/Permutation`` is a compact way to store that order: it records only the items the user moved, encodes as an array of integers, and merges with the same order changed on another device.

### Store the order beside the items

Keep the items in a stable storage order that reordering never changes, and keep the permutation that takes that order to the order the user sees.

```swift
struct TaskList: Codable {
    var items: [Task]         // in creation order, never reordered
    var order: Permutation    // the user's custom order
}

let shown: [Task] = list.items.applying(list.order)
```

To let the user reorder the list, show it through an ``Arrangement`` and read its ``Arrangement/permutation`` back after each change.

```swift
var arrangement: Arrangement<Task> = Arrangement(list.items)
arrangement.permutation = list.order
arrangement.move(fromOffsets: source, toOffset: destination)
list.order = arrangement.permutation
```

### Keep the permutation aligned with the items

When an item is inserted into or removed from storage, change the permutation at the same offset so every other item keeps its place. ``Permutation/Permutation/insert(at:)`` adds an offset that stays in place, and ``Permutation/Permutation/remove(at:)`` removes an offset from the order.

```swift
list.items.insert(newTask, at: 7)
list.order.insert(at: 7)

list.items.remove(at: 2)
list.order.remove(at: 2)
```

### Merge orders changed on two devices

A three-way merge needs three versions of the order: the base, which is the last version both devices agreed on, the local version and the server version. Before merging, apply every insertion and removal from either side to all three permutations, so the same offset refers to the same item in each.

Then merge with ``Permutation/Permutation/MergeStrategy/relativeOrder``. The merge keeps every pair of items that either side reordered since the base, and gives up only pairs that neither side changed. It never fails, gives the same result from either side, and runs in O(n log n).

```swift
let merged: Permutation = local.merging(with: server, from: base, by: .relativeOrder)
```

``Permutation/Permutation/merging(with:from:)`` is the strict alternative. It returns `nil` when both sides moved the same offset in different ways, so you can resolve the conflict yourself.

### Send only what changed

After a merge, the permutation that takes the server's order to the merged order describes exactly what the server is missing. Its ``Permutation/Permutation/moves`` are the fewest single-item moves to send.

```swift
let change: Permutation = server.inverted.followed(by: merged)
for move in change.moves {
    upload(.move(from: move.from, to: move.to))
}
```
