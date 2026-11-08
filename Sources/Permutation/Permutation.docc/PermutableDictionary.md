# ``PermutableDictionary``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

An ordered dictionary whose entries can be reordered without moving a key or a value in memory, and whose values can be reassigned among keys that stay in place.

## Overview

A permutable dictionary keeps its entries in an order you control, with O(1) lookup, insertion and removal by key. Its ``keys`` are an ``Arrangement``. Every reorder moves whole entries, whether you sort the dictionary, its keys or its values, so each key stays paired with its value.

```swift
var scores: PermutableDictionary<String, Int> = ["ann": 3, "bob": 9, "cy": 5]
scores.keys.sort()                   // by key: ["ann": 3, "bob": 9, "cy": 5]
scores.values.sort()                 // by value: ["ann": 3, "cy": 5, "bob": 9]
scores.sort { $0.value > $1.value }  // any order: ["bob": 9, "cy": 5, "ann": 3]
scores["dee", default: 0] += 1       // edits in place, appending when new
```

### Reordering, reassigning and editing

A permutable dictionary distinguishes three kinds of change, each with its own API:

- **Reordering** the dictionary, its ``keys`` or its ``values`` moves whole entries. Sorting the values keeps tied keys in their current order.
- **Reassigning** with ``reassignValues(_:)`` hands the values around while every key stays put.
- **Editing** through a key or through `values[position]` changes a value in place.

```swift
var santas = PermutableDictionary(uniqueKeys: friends, values: friends)
santas.reassignValues(shuffling: .derangement)  // keys stay put: a fair Secret Santa
```

Neither reordering nor reassigning copies a key or a value, because both live in storage that reordering never touches. Both return the ``Permutation`` they applied, so you can undo either kind of change by applying its inverse.

## Topics

### Creating a permutable dictionary

- ``init()``
- ``init(uniqueKeysWithValues:)``
- ``init(uniqueKeys:values:)``
- ``init(dictionaryLiteral:)``

### Accessing keys and values

- ``subscript(_:)->Value?``
- ``subscript(_:default:)``
- ``contains(key:)``
- ``index(forKey:)``
- ``keys``
- ``values``
- ``Keys``
- ``Values``
- ``Element``

### Adding and updating

- ``updateValue(_:forKey:)``
- ``updateValue(_:forKey:insertingAt:)``
- ``reserveCapacity(_:)``

### Removing entries

- ``removeValue(forKey:)``
- ``remove(atOffsets:)``
- ``removeAll(where:)``
- ``removeAll()``
- ``filter(_:)``

### Transforming values

- ``mapValues(_:)``

### Reordering entries

- ``apply(_:)``
- ``swapAt(_:_:)``

### Reassigning values

- ``reassignValues(_:)``
- ``reassignValues(shuffling:)``
- ``reassignValues(shuffling:using:)``

### Iterating

- ``startIndex``
- ``endIndex``
- ``makeIterator()``
- ``Iterator``

### Encoding and decoding

- ``encode(to:)``
- ``init(from:)``
