# ``Arrangement``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

A fixed list of elements that can only be reordered, and remembers how far it has moved from its starting order.

## Overview

An arrangement never adds, removes or overwrites an element, which is exactly the guarantee `MutableCollection` can't make. The elements need not be `Hashable` or even `Equatable`. They stay where they were stored, and every reorder rewrites only the order shown, so sorting a list of large photos costs the same as sorting a list of numbers.

```swift
var photos: Arrangement<Photo> = Arrangement(album)
photos.sort { $0.date < $1.date }
photos.shuffle()
photos.permutation                  // every reorder so far, folded into one
photos.isInOriginalOrder            // false
photos.permutation = Permutation()  // back to the original order in one step
```

### Track the reorder history

Because the stored order never changes, an arrangement always knows the single ``permutation`` that takes its original order to the order shown. Setting it restores any saved order at once, and ``isInOriginalOrder`` reports whether the reorders have cancelled out. An arrangement encodes its elements in their original order along with that permutation, so decoding restores the history as well as the order.

### Walk every order

``permutations`` walks every order of the elements lazily, starting from the original order, without touching the arrangement. The `k`-th order shown has `permutation == Permutation(rank: k)`, and a search can stop at the first match:

```swift
let seats: Arrangement<String> = ["Ann", "Bob", "Cy", "Dee"]
let plan = seats.permutations.first { $0.first == "Dee" && $0.last == "Ann" }
```

The number of orders grows as `n!`, so a full walk is practical only for about a dozen elements.

### Dictionary keys

A ``PermutableDictionary`` hands out its keys as an arrangement, so sorting or shuffling `dictionary.keys` reorders the whole entries.

## Topics

### Creating an Arrangement

- ``init()``
- ``init(_:)``
- ``init(arrayLiteral:)``

### Reordering

- ``apply(_:)``
- ``swapAt(_:_:)``

### Tracking the Reorder History

- ``permutation``
- ``isInOriginalOrder``

### Walking Every Order

- ``permutations``
- ``Permutations``

### Accessing Elements

- ``subscript(_:)``
- ``startIndex``
- ``endIndex``
- ``makeIterator()``
- ``Iterator``

### Encoding and Decoding

- ``encode(to:)``
- ``init(from:)``
