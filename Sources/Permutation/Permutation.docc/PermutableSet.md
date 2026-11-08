# ``PermutableSet``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

An ordered collection of unique hashable elements whose order changes without moving them.

## Overview

A permutable set keeps each element once, in an order you control, with O(1) membership checks and removals. The elements sit in storage that reordering never touches, so sorting, shuffling or moving rewrites only the order shown.

```swift
var tags: PermutableSet<String> = ["swift", "ios", "math"]
tags.append("swift")                 // false, already there
tags.formUnion(["math", "cs"])       // ["swift", "ios", "math", "cs"]
tags.subtract(["ios"])               // ["swift", "math", "cs"]
let alphabetical: Permutation = tags.sort()
```

### Set operations with a clear order

A permutable set offers only the set operations whose result has a clear order. The elements kept from the receiver stay in its order, and new elements follow in the order of the argument. Each operation accepts any sequence, so you can combine a permutable set with an array or a `Set`.

`PermutableSet` does not conform to `SetAlgebra`. Its `==` respects order, so `["a", "b"]` and `["b", "a"]` are different values, and that breaks the laws `SetAlgebra` assumes.

## Topics

### Creating a Permutable Set

- ``init()``
- ``init(_:)``
- ``init(arrayLiteral:)``

### Testing Membership

- ``contains(_:)``

### Adding Elements

- ``append(_:)``
- ``append(contentsOf:)``
- ``insert(_:at:)``
- ``insert(contentsOf:at:)``
- ``reserveCapacity(_:)``

### Replacing and Updating

- ``replace(_:)``
- ``replace(at:with:)``
- ``update(orAppend:)-1xy92``
- ``update(orAppend:)-3hqnd``
- ``update(orInsert:at:)-2cnh4``
- ``update(orInsert:at:)-8klv4``

### Removing Elements

- ``remove(_:)``
- ``remove(at:)``
- ``remove(atOffsets:)``
- ``removeAll(where:)``
- ``removeAll()``
- ``filter(_:)``

### Combining Sets

- ``union(_:)``
- ``formUnion(_:)``
- ``intersection(_:)``
- ``formIntersection(_:)``
- ``subtracting(_:)``
- ``subtract(_:)``
- ``symmetricDifference(_:)``
- ``formSymmetricDifference(_:)``

### Comparing Sets

- ``isSubset(of:)``
- ``isStrictSubset(of:)``
- ``isSuperset(of:)``
- ``isStrictSuperset(of:)``
- ``isDisjoint(with:)``

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
