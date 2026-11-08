# ``UpsertableCollection``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

An ordered collection that holds each element at most once, with one vocabulary for adding, replacing and removing.

## Overview

A collection that refuses duplicates needs more care than `append` and `insert`. Adding an element that is already present must fail, replacing must find the matching element, and a batch must not leave half its elements behind. `UpsertableCollection` gives that care one consistent vocabulary:

- `append` and `insert` add only what is new and report whether they did. The batch forms are all or nothing: they add every element, or none when any is already present or repeats within the batch.
- `replace` changes only what is already present, in place.
- `update` replaces what is present and adds what is new, so it is the call for syncing from a server. In a batch, when an element repeats, the later one wins.
- `remove` deletes by position.

```swift
var roster: IdentifiedSet<Player> = []
roster.append(ann)                   // true
roster.append(ann)                   // false, already there
roster.update(orAppend: changedBob)  // replace in place, or add
roster.update(orAppend: fetched)     // a whole page of results, in order
```

### Conforming to UpsertableCollection

A conforming type decides what makes two elements the same, such as a shared id, and supplies three operations: ``insert(_:at:)``, which refuses a duplicate, ``replace(_:)``, which swaps in a new version of an element already present, and ``remove(at:)``. Every other operation has a default built from those three, which a type may override with a faster version that keeps the same meaning.

Positions use the collection's own `Index`. The defaults count positions as offsets from `startIndex`, which is O(1) in a random-access collection.

## Topics

### Adding Elements

- ``append(_:)``
- ``append(contentsOf:)``
- ``insert(_:at:)``
- ``insert(contentsOf:at:)``

### Replacing and Updating

- ``replace(_:)``
- ``update(orAppend:)-2f6hq``
- ``update(orAppend:)-57vho``
- ``update(orInsert:at:)-7z57s``
- ``update(orInsert:at:)-5q7o7``

### Removing Elements

- ``remove(at:)``
- ``remove(atOffsets:)``
- ``removeAll(where:)``
