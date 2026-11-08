# ``IdentifiedSet``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

An ordered collection of identifiable elements with constant-time lookup, insertion and removal by id, built for SwiftUI lists.

## Overview

SwiftUI's `List` and `ForEach` misbehave when two rows share an id, and an `Array` of models can't prevent that. An identified set holds each id at most once, looks elements up by id in O(1), and reorders by moving offsets rather than elements, so reordering a list of large models is as cheap as reordering numbers.

```swift
var roster: IdentifiedSet<Player> = []
roster.append(ann)                    // false if the id is already there
roster.update(orAppend: changedBob)   // replace in place, or add
roster[id: ann.id]?.score += 1
roster.remove(atOffsets: offsets)     // ready for SwiftUI's onDelete
let moved: Permutation = roster.move(fromOffsets: source, toOffset: destination)  // and onMove
```

Every reorder returns the ``Permutation/Permutation`` it applied, which is what you need to undo the change or animate it.

### Bindings that follow the element

In SwiftUI, `$roster[id:]` gives a binding to one element, and `$roster.elements()` gives a binding to each. Both find their element by id rather than by position, so they keep pointing at the right element through every sort, shuffle and move.

```swift
List($roster.elements()) { $player in
    Stepper(player.name, value: $player.score)
}
```

### Adding and updating

An identified set is an ``UpsertableCollection``. ``append(_:)`` and ``insert(_:at:)`` refuse an id already present, ``replace(_:)`` swaps in a new version of an element in place, and `update(orAppend:)` does whichever fits for each element, so syncing a page of results from a server is one call. Creating a set from a sequence with repeated ids keeps the first by default. Pass ``Uniquing`` to keep the last or to combine them instead.

## Topics

### Creating an Identified Set

- ``init()``
- ``init(_:uniquingIDsWith:)``
- ``init(arrayLiteral:)``
- ``Uniquing``

### Finding Elements by ID

- ``subscript(id:)``
- ``contains(id:)``
- ``firstIndex(id:)``
- ``ids``

### Adding Elements

- ``append(_:)``
- ``append(contentsOf:)``
- ``insert(_:at:)``
- ``insert(contentsOf:at:)``
- ``reserveCapacity(_:)``

### Replacing and Updating

- ``replace(_:)``
- ``replace(at:with:)``
- ``update(orAppend:)-6j51e``
- ``update(orAppend:)-vozz``
- ``update(orInsert:at:)-68jh5``
- ``update(orInsert:at:)-qat7``

### Removing Elements

- ``remove(id:)``
- ``remove(ids:)``
- ``remove(at:)``
- ``remove(atOffsets:)``
- ``removeAll(where:)``
- ``removeAll()``
- ``filter(_:)``

### Reordering

- ``apply(_:)``
- ``swapAt(_:_:)``

### Accessing Elements

- ``subscript(_:)``
- ``startIndex``
- ``endIndex``
- ``makeIterator()``
- ``Iterator``

### Encoding and Decoding

- ``encode(to:)``
- ``init(from:)``
