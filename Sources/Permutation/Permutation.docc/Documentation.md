# ``Permutation``

Reorder Swift collections and get back the reorder itself as a value you can undo, store, compose and merge.

## Overview

A sort, a shuffle or a drag-and-drop move is a *permutation*: a rule that says where each element goes. The standard library performs these reorders and forgets them. This package keeps them as a ``Permutation/Permutation`` value, so you can invert it to undo, fold several into one, replay one as the fewest moves for an animation or a sync, or apply it to a second collection so the two stay in step.

The reordering itself rests on ``PermutableCollection``, a protocol that asks only that a collection can swap two of its elements. Unlike `MutableCollection`, it never asks a collection to accept an arbitrary new element, so sets, dictionaries and identified collections can reorder freely without breaking their rules.

```swift
import Permutation

var players: IdentifiedSet<Player> = [ann, bob, cy]

let ranking: Permutation = players.sort { $0.score > $1.score }  // reorders, returns what it did
players.apply(ranking.inverted)                                   // undo in one call
```

## Topics

### Essentials

- ``Permutation/Permutation``

### Collections

- ``Arrangement``
- ``IdentifiedSet``
- ``PermutableSet``
- ``PermutableDictionary``

### Protocols

- ``PermutableCollection``
- ``UpsertableCollection``
