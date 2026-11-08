# ``PermutableCollection``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

A collection that can reorder its elements, and reports every reorder as a permutation.

## Overview

`MutableCollection` asks a collection to accept any new element at any position. Sets, dictionaries and identified collections can't keep that promise without risking duplicates, so the standard library leaves them with no way to sort or shuffle in place. `PermutableCollection` asks only that two elements can trade places, which every ordered collection can do safely.

A conforming type implements two requirements, ``apply(_:)`` and ``swapAt(_:_:)``, and gets every reorder below in return. Each works in place, and each hands back the ``Permutation/Permutation`` it applied:

```swift
var songs: IdentifiedSet<Song> = playlist

let byTitle: Permutation = songs.sort { $0.title < $1.title }
let shuffled: Permutation = songs.shuffle()
let moved: Permutation = songs.move(fromOffsets: [4], toOffset: 0)  // ready for SwiftUI's onMove

songs.apply(moved.inverted)  // undo the drag
```

### Conforming to PermutableCollection

Implement ``swapAt(_:_:)`` so that it keeps every index valid. The default ``apply(_:)`` is built from it with the fewest possible swaps. A type that can move a whole cycle at once, such as one that reorders an index of its elements rather than the elements themselves, overrides ``apply(_:)`` as well, and every other reorder becomes as cheap as that one method. Because every reorder passes through ``apply(_:)``, overriding it also lets a type observe each one.

### Mutable collections

A conforming type that is also a `MutableCollection` keeps the standard library's in-place `sort()` and `reverse()`, which build no permutation. To get the permutation, ask for one by type, as in `let solved: Permutation = board.sort()`.

`Array` doesn't conform, but `apply(_:)` and `applying(_:)` work on any `MutableCollection` or `RangeReplaceableCollection`, so a permutation made from one collection reorders a plain array beside it.

## Topics

### Applying a Permutation

- ``apply(_:)``
- ``applying(_:)-3o9uc``
- ``swapAt(_:_:)``
- ``swap(_:_:)``

### Sorting

- ``sort()->_``
- ``sort(by:)->_``

### Shuffling

- ``shuffle(_:)``
- ``shuffle(_:using:)``

### Moving Elements

- ``move(from:to:)``
- ``move(fromOffsets:toOffset:)``
- ``rotate(toStartAt:)``
- ``reverse()->_``
- ``stablePartition(by:)``
