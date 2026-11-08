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

### Replacing an equal element

``replace(_:)`` swaps in an element that is equal to one already present, keeping its position. This matters only when equal elements can still be told apart, such as a type whose `==` compares an identifier but not its other properties:

```swift
struct Tag: Hashable {
    let name: String
    var color: String
    static func == (lhs: Tag, rhs: Tag) -> Bool { lhs.name == rhs.name }
    func hash(into hasher: inout Hasher) { hasher.combine(name) }
}

var tags: PermutableSet<Tag> = [Tag(name: "swift", color: "orange")]
tags.replace(Tag(name: "swift", color: "red"))  // equal by name: takes the old tag's place and returns it
tags.replace(Tag(name: "ios", color: "blue"))   // nil: no equal tag, so nothing changes
tags.update(orAppend: Tag(name: "ios", color: "blue"))  // replaces when equal, otherwise appends
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
