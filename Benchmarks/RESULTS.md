# Benchmark results

These charts and tables compare the package's collections with the ones people most often reach for:

- **`Arrangement`** against `Array`, both holding a typical app model: a UUID id, an `Int` sort key and 64 bytes of other fields (`Record`).
- **`PermutableSet`** against [swift-collections](https://github.com/apple/swift-collections)' `OrderedSet`, both holding `Record`.
- **`PermutableDictionary`** against swift-collections' `OrderedDictionary`, both mapping `Int` keys to `Record` values.
- **`IdentifiedSet`** against [Point-Free's](https://github.com/pointfreeco/swift-identified-collections) `IdentifiedArray`, both holding `Record`.

Every figure is **time per element**: the fastest of three runs of the whole operation, divided by the number of elements. Lower is better.

Measured on 2026-11-08 on a GitHub `macos-latest` runner (Apple silicon), release build, with [swift-collections-benchmark](https://github.com/apple/swift-collections-benchmark). Absolute numbers will differ on your machine. The ratios are what to read.

## Summary

- **Reordering is where the design pays off.** Every reorder moves 4-byte offsets instead of 96-byte records and leaves the hash index alone. At 16k elements, reversing runs 17× faster than `Array` and 67–75× faster than `OrderedSet`, `OrderedDictionary` and `IdentifiedArray`. Sorting runs 2–2.4× faster than `Array` and `OrderedSet`, and 11–14× faster than `IdentifiedArray` and `OrderedDictionary`.
- **Discarding the result skips the permutation.** When a call ignores the `Permutation` it could return, the collection rewrites its offsets directly. Moving one element is now 12× faster than `Array` and `OrderedSet` and 970× faster than `IdentifiedArray`. Moving every tenth element to the front, as a multi-row drag in SwiftUI does, is 12–28× faster than rebuilding and 281× faster than `IdentifiedArray`.
- **Partitioning is faster and stable.** `stablePartition(by:)` keeps both groups in their original order and still runs 2.3–3× faster than the unstable `partition(by:)` of `OrderedSet`, `OrderedDictionary` and `IdentifiedArray`, and 1.2× faster than `Array`'s.
- **Removing one element at a time scales.** At 16k elements, removing by value, key or id is 57–100× faster than the competitors. At 256k, the competitors didn't finish inside the benchmark's time limit.
- **Lookups and inserts are mostly faster.** Building, appending and set operations run 1.1–3.4× faster. The exceptions are `contains(id:)`, 1.5× slower than `IdentifiedArray`, and dictionary lookup, which reads through one more table than `OrderedDictionary` and is 1.6–3× slower.
- **Iteration is the one steady cost for sets.** Each read goes through the offset table, so a `for` loop over a set is about 1.6× slower than `OrderedSet` and `IdentifiedArray`. Dictionary iteration is 1.4× faster than `OrderedDictionary`. Rotating an `Arrangement` is also slower than rebuilding an `Array` from two slices until about 256k elements.

## Charts

Each chart shows one operation with every collection that supports it. Each pair has its own color: the package's collection is the darker solid line and the collection it replaces is the lighter dashed line. The legend gives the speedup at the largest size both finished. Lines start at 16 elements, below which a call's fixed cost swamps the time per element.

![Reorder speedups at 16,384 elements](Charts/speedups.png)

### Reordering

![Sort](Charts/sort.png)

![Shuffle](Charts/shuffle.png)

![Reverse](Charts/reverse.png)

![Rotate by a third](Charts/rotate.png)

![Move first to last](Charts/move.png)

![Move every tenth to the front](Charts/move-many.png)

![Partition](Charts/partition.png)

### Building, lookup and removal

![Build from an array](Charts/init.png)

![Append one at a time](Charts/append.png)

![Look up every element](Charts/lookup.png)

![Remove 1% one at a time](Charts/remove.png)

![Iterate](Charts/iteration.png)

### Set operations

![Union, intersection and subtraction](Charts/set-operations.png)

## Tables

The note after each operation compares the two at the largest size both finished. The partition rows compare this package's stable partition with the other collections' unstable `partition(by:)`. In the removal rows, "1%" means 1% of the elements are removed one at a time in random order. Each removal in `OrderedSet` and `IdentifiedArray` shifts every later element. In `PermutableSet` and `IdentifiedSet`, the last stored element fills the hole and only a 4-byte offset shifts.

### Arrangement vs Array

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| sort(by:) (1.6× faster) | Arrangement | 44 ns | 67 ns | 111 ns | 174 ns |
| | Array | 60 ns | 189 ns | 221 ns | 276 ns |
| shuffle() (2.2× faster) | Arrangement | 52 ns | 55 ns | 52 ns | 57 ns |
| | Array | 65 ns | 78 ns | 76 ns | 124 ns |
| reverse() (16.9× faster) | Arrangement | 5.19 ns | 0.61 ns | 0.45 ns | 0.47 ns |
| | Array | 7.81 ns | 7.24 ns | 7.66 ns | 8.01 ns |
| rotate by a third (1.2× faster) | Arrangement | 18 ns | 2.89 ns | 2.44 ns | 2.54 ns |
| | Array | 13 ns | 1.67 ns | 1.53 ns | 3.02 ns |
| move first to last (18.8× faster) | Arrangement | 5.19 ns | 0.24 ns | 0.14 ns | 0.17 ns |
| | Array | 5.19 ns | 1.59 ns | 1.74 ns | 3.16 ns |
| move every tenth to the front (12.3× faster) | Arrangement | 18 ns | 2.97 ns | 2.67 ns | 2.73 ns |
| | Array | 70 ns | 35 ns | 32 ns | 34 ns |
| partition by odd rank (1.2× faster) | Arrangement | 29 ns | 15 ns | 14 ns | 14 ns |
| | Array | 18 ns | 17 ns | 18 ns | 18 ns |

### PermutableSet vs swift-collections OrderedSet

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| init from array (1.3× faster) | PermutableSet | 142 ns | 46 ns | 48 ns | 70 ns |
| | OrderedSet | 49 ns | 56 ns | 62 ns | 90 ns |
| append one at a time (1.1× faster) | PermutableSet | 198 ns | 167 ns | 170 ns | 225 ns |
| | OrderedSet | 182 ns | 199 ns | 205 ns | 256 ns |
| successful contains (1.8× faster) | PermutableSet | 34 ns | 52 ns | 56 ns | 117 ns |
| | OrderedSet | 70 ns | 80 ns | 104 ns | 209 ns |
| iteration (1.6× slower) | PermutableSet | 21 ns | 19 ns | 19 ns | 20 ns |
| | OrderedSet | 13 ns | 12 ns | 12 ns | 13 ns |
| remove 1% one at a time (99.3× faster) | PermutableSet | 16 ns | 4.39 ns | 23 ns | 350 ns |
| | OrderedSet | 16 ns | 104 ns | 2.3 µs | – |
| sort (1.8× faster) | PermutableSet | 47 ns | 77 ns | 118 ns | 175 ns |
| | OrderedSet | 99 ns | 234 ns | 279 ns | 317 ns |
| shuffle (3.4× faster) | PermutableSet | 52 ns | 54 ns | 55 ns | 55 ns |
| | OrderedSet | 112 ns | 132 ns | 143 ns | 185 ns |
| reverse (72.0× faster) | PermutableSet | 5.19 ns | 0.57 ns | 0.47 ns | 0.44 ns |
| | OrderedSet | 23 ns | 27 ns | 32 ns | 32 ns |
| rotate by a third (22.7× faster) | PermutableSet | 21 ns | 2.85 ns | 2.62 ns | 2.43 ns |
| | OrderedSet | 57 ns | 48 ns | 49 ns | 55 ns |
| move first to last (20.0× faster) | PermutableSet | 7.81 ns | 0.24 ns | 0.14 ns | 0.16 ns |
| | OrderedSet | 13 ns | 2.03 ns | 1.85 ns | 3.23 ns |
| move every tenth to the front (30.2× faster) | PermutableSet | 18 ns | 3.13 ns | 2.67 ns | 2.68 ns |
| | OrderedSet | 107 ns | 78 ns | 76 ns | 81 ns |
| partition by odd rank (3.2× faster) | PermutableSet | 29 ns | 15 ns | 15 ns | 15 ns |
| | OrderedSet | 36 ns | 41 ns | 43 ns | 46 ns |
| union half-overlapping (1.3× faster) | PermutableSet | 133 ns | 119 ns | 121 ns | 147 ns |
| | OrderedSet | 104 ns | 116 ns | 122 ns | 186 ns |
| intersection half-overlapping (1.7× faster) | PermutableSet | 57 ns | 74 ns | 77 ns | 94 ns |
| | OrderedSet | 88 ns | 122 ns | 132 ns | 155 ns |
| subtracting half-overlapping (1.7× faster) | PermutableSet | 52 ns | 75 ns | 76 ns | 93 ns |
| | OrderedSet | 99 ns | 123 ns | 133 ns | 159 ns |

### IdentifiedSet vs Point-Free IdentifiedArray

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| init from array (3.4× faster) | IdentifiedSet | 117 ns | 36 ns | 37 ns | 48 ns |
| | IdentifiedArray | 198 ns | 169 ns | 156 ns | 166 ns |
| append one at a time (2.0× faster) | IdentifiedSet | 177 ns | 151 ns | 151 ns | 177 ns |
| | IdentifiedArray | 294 ns | 370 ns | 348 ns | 350 ns |
| successful contains(id:) (1.5× slower) | IdentifiedSet | 34 ns | 42 ns | 46 ns | 110 ns |
| | IdentifiedArray | 57 ns | 66 ns | 66 ns | 75 ns |
| subscript(id:) read (about even) | IdentifiedSet | 55 ns | 60 ns | 67 ns | 157 ns |
| | IdentifiedArray | 86 ns | 90 ns | 94 ns | 168 ns |
| iteration (1.6× slower) | IdentifiedSet | 21 ns | 19 ns | 19 ns | 19 ns |
| | IdentifiedArray | 13 ns | 12 ns | 12 ns | 12 ns |
| remove(id:) 1% (86.5× faster) | IdentifiedSet | 13 ns | 3.62 ns | 22 ns | 344 ns |
| | IdentifiedArray | 16 ns | 114 ns | 1.9 µs | – |
| removeAll(where:) half (2.6× faster) | IdentifiedSet | 21 ns | 32 ns | 33 ns | 36 ns |
| | IdentifiedArray | 68 ns | 89 ns | 89 ns | 95 ns |
| reverse() (74.3× faster) | IdentifiedSet | 7.81 ns | 0.57 ns | 0.47 ns | 0.48 ns |
| | IdentifiedArray | 26 ns | 29 ns | 35 ns | 36 ns |
| shuffle() (3.9× faster) | IdentifiedSet | 52 ns | 54 ns | 54 ns | 55 ns |
| | IdentifiedArray | 128 ns | 133 ns | 133 ns | 212 ns |
| sort(by:) (10.0× faster) | IdentifiedSet | 47 ns | 66 ns | 117 ns | 164 ns |
| | IdentifiedArray | 526 ns | 1.2 µs | 1.4 µs | 1.6 µs |
| rotate by a third (87.5× faster) | IdentifiedSet | 21 ns | 2.81 ns | 2.57 ns | 2.47 ns |
| | IdentifiedArray | 180 ns | 210 ns | 210 ns | 216 ns |
| move first to last (876.6× faster) | IdentifiedSet | 5.25 ns | 0.24 ns | 0.14 ns | 0.16 ns |
| | IdentifiedArray | 146 ns | 140 ns | 138 ns | 140 ns |
| move every tenth to the front (356.0× faster) | IdentifiedSet | 18 ns | 2.93 ns | 2.75 ns | 2.86 ns |
| | IdentifiedArray | 96 ns | 509 ns | 773 ns | 1.0 µs |
| partition by odd rank (3.0× faster) | IdentifiedSet | 26 ns | 15 ns | 14 ns | 15 ns |
| | IdentifiedArray | 36 ns | 40 ns | 42 ns | 44 ns |

### PermutableDictionary vs swift-collections OrderedDictionary

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| init from keys and values (1.6× faster) | PermutableDictionary | 7.81 ns | 13 ns | 15 ns | 18 ns |
| | OrderedDictionary | 21 ns | 21 ns | 25 ns | 29 ns |
| subscript insert one at a time (1.2× faster) | PermutableDictionary | 141 ns | 156 ns | 141 ns | 156 ns |
| | OrderedDictionary | 146 ns | 164 ns | 165 ns | 180 ns |
| subscript lookup (3.0× slower) | PermutableDictionary | 34 ns | 42 ns | 43 ns | 158 ns |
| | OrderedDictionary | 21 ns | 21 ns | 28 ns | 53 ns |
| iteration (1.4× faster) | PermutableDictionary | 29 ns | 24 ns | 23 ns | 24 ns |
| | OrderedDictionary | 36 ns | 34 ns | 33 ns | 34 ns |
| removeValue(forKey:) 1% (57.1× faster) | PermutableDictionary | 16 ns | 4.60 ns | 22 ns | 350 ns |
| | OrderedDictionary | 13 ns | 59 ns | 1.3 µs | – |
| sort by key (12.9× faster) | PermutableDictionary | 34 ns | 53 ns | 82 ns | 113 ns |
| | OrderedDictionary | 560 ns | 984 ns | 1.2 µs | 1.5 µs |
| shuffle (3.0× faster) | PermutableDictionary | 50 ns | 54 ns | 52 ns | 54 ns |
| | OrderedDictionary | 99 ns | 108 ns | 109 ns | 164 ns |
| reverse (84.0× faster) | PermutableDictionary | 5.25 ns | 0.53 ns | 0.46 ns | 0.44 ns |
| | OrderedDictionary | 29 ns | 31 ns | 34 ns | 37 ns |
| rotate by a third (15.4× faster) | PermutableDictionary | 21 ns | 2.77 ns | 2.47 ns | 2.52 ns |
| | OrderedDictionary | 52 ns | 32 ns | 32 ns | 39 ns |
| move first to last (50.6× faster) | PermutableDictionary | 5.19 ns | 0.20 ns | 0.14 ns | 0.14 ns |
| | OrderedDictionary | 21 ns | 4.44 ns | 3.58 ns | 6.98 ns |
| move every tenth to the front (23.3× faster) | PermutableDictionary | 18 ns | 3.05 ns | 2.73 ns | 2.67 ns |
| | OrderedDictionary | 120 ns | 57 ns | 58 ns | 62 ns |
| partition by odd rank (2.5× faster) | PermutableDictionary | 29 ns | 16 ns | 15 ns | 15 ns |
| | OrderedDictionary | 29 ns | 35 ns | 34 ns | 38 ns |
| sort by value (6.5× faster) | PermutableDictionary | 73 ns | 94 ns | 141 ns | 214 ns |
| | OrderedDictionary | 435 ns | 991 ns | 1.2 µs | 1.4 µs |
| shuffle values among keys (2.3× faster) | PermutableDictionary | 68 ns | 60 ns | 58 ns | 61 ns |
| | OrderedDictionary | 83 ns | 89 ns | 87 ns | 141 ns |

### Median times for one reorder

These medians come from an earlier run, before reorders that discard their result skipped building the permutation, so they understate the single move in particular. Measured with `swift run -c release PermutationComparisons`, which reports the median of 201 runs of the whole operation at 16,384 elements rather than time per element. `Arrangement` and `IdentifiedSet` hold `Record` values, `PermutableSet` holds `Int` values, and each pair receives the same random generator for shuffles. Every competitor uses its own API where it has one. `Array` and `OrderedSet` have no rotate, so they rebuild from two slices, and `OrderedSet` moves an element by removing and appending it. `IdentifiedArray` moves and rotates through `move(fromOffsets:toOffset:)`.

| Reorder | Arrangement | Array | PermutableSet | OrderedSet | IdentifiedSet | IdentifiedArray |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sort | 2.2 ms | 3.4 ms (1.6×) | 1.1 ms | 1.3 ms (1.1×) | 2.2 ms | 20.0 ms (9.2×) |
| Shuffle | 126 µs | 290 µs (2.3×) | 126 µs | 492 µs (3.9×) | 141 µs | 1.5 ms (11×) |
| Reverse | 62 µs | 173 µs (2.8×) | 41 µs | 399 µs (9.8×) | 44 µs | 645 µs (15×) |
| Move first to last | 16 µs | 32 µs (2.0×) | 17 µs | 7 µs (0.4×) | 17 µs | 3.2 ms (187×) |
| Rotate by a third | 27 µs | 35 µs (1.3×) | 38 µs | 430 µs (11×) | 42 µs | 4.6 ms (110×) |

Each ratio is the competitor's time divided by the permutable collection's time, so a ratio above 1 means the permutable collection is faster.

The same run also times one result of the cycle arithmetic directly. Applying a shuffle 1,000 times to an `Array` of 16,384 records takes 444 ms. Raising the shuffle to the 1,000th power with `raised(to:)` and applying it once to an `Arrangement` takes 163 µs, about 2,700× faster, because the power splits each cycle in one pass whatever the exponent.

## Reproducing

Start the **Benchmarks** workflow from the Actions tab. It uploads `results.json`, the charts and the tables as an artifact. Or run locally:

```sh
cd Benchmarks
swift run -c release PermutationBenchmarks run results.json --cycles 3 --max-size 256k
python3 Scripts/charts.py results.json Charts
python3 Scripts/tables.py results.json
```

`Scripts/charts.py` needs matplotlib (`pip install matplotlib`). The median comparison above comes from `swift run -c release PermutationComparisons`.
