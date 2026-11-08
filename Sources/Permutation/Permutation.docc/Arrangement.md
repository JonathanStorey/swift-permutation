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
photos.permutation                 // every reorder so far, folded into one
photos.permutation.cycles.isEmpty  // false: the reorders haven't cancelled out
```

### Track and restore the order

Because the stored order never changes, an arrangement always knows the single ``permutation`` that takes its original order to the order shown. Its cycles are empty exactly when the elements are back in their original order.

Setting ``permutation`` shows the original elements in the new permutation's order, whatever came before, so any saved order comes back in one step:

```swift
let curated: Permutation = photos.permutation      // save the order the user arranged
photos.shuffle()                                   // a slideshow
photos.permutation = curated                       // restore the arranged order
photos.permutation = Permutation()                 // back to import order
photos.permutation = Permutation(sorting: album.map(\.date))  // date order, computed from the original order
```

An arrangement encodes its elements in their original order along with its permutation, so decoding restores the history as well as the order.

### Walk every order

``permutations`` walks every order of the elements lazily, starting from the original order, without touching the arrangement. The `k`-th order has `permutation == Permutation(rank: k)`.

```swift
let seats: Arrangement<String> = ["Ann", "Bob", "Cy"]
for order in seats.permutations {
    print(Array(order))  // ["Ann", "Bob", "Cy"] first, then the other five orders
}
```

Because the walk is lazy, a search can stop at the first match:

```swift
let guests: Arrangement<String> = ["Ann", "Bob", "Cy", "Dee"]
let plan = guests.permutations.first { $0.first == "Dee" && $0.last == "Ann" }
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
