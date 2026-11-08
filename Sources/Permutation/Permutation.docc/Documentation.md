# ``Permutation``

Reorder collections and keep each reorder as a value you can undo, combine, replay, store and merge.

## Overview

A sort, a shuffle or a drag-and-drop move is a *permutation*: a rule that says where each element of a collection goes. The standard library performs these reorders and discards the rule. This package keeps it. Every reorder returns a ``Permutation``, a value type you can invert to undo the reorder, compose with other reorders, replay as the fewest moves for an animation or a sync, apply to a second collection, encode, and merge with a reorder made on another device.

Reordering rests on ``PermutableCollection``, a protocol that requires only that a collection can exchange two of its elements. `MutableCollection` requires a collection to accept any element at any position, a guarantee that sets, dictionaries and collections of identifiable elements can't make without risking duplicates. Because ``PermutableCollection`` never overwrites an element, those collections can sort, shuffle and move their elements in place.

The package provides four collections that conform to ``PermutableCollection``. Each stores its elements in an array that reordering never changes and reorders a separate table of offsets instead, so the cost of a reorder doesn't depend on the size of the elements.

- ``Arrangement`` is a fixed list of elements that can only be reordered, and that always knows the permutation from its original order.
- ``IdentifiedSet`` holds `Identifiable` elements with constant-time lookup by id, for SwiftUI lists.
- ``PermutableSet`` holds unique `Hashable` elements in an order you control.
- ``PermutableDictionary`` is an ordered dictionary whose reorders move whole entries.

```swift
import Permutation

var players: IdentifiedSet<Player> = [ann, bob, cy]

let ranking: Permutation = players.sort { $0.score > $1.score }  // reorders, returns what it did
players.apply(ranking.inverted)                                   // undoes the reorder
```

## Topics

### Essentials

- <doc:Recording-and-undoing-reorders>
- ``Permutation/Permutation``
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
