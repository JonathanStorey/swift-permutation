### Arrangement vs Array

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| sort(by:) (2.8× slower) | Arrangement | 52 ns | 212 ns | 287 ns | 605 ns |
| | Array | 34 ns | 141 ns | 176 ns | 216 ns |
| shuffle() (1.9× faster) | Arrangement | 47 ns | 54 ns | 53 ns | 53 ns |
| | Array | 60 ns | 70 ns | 71 ns | 99 ns |
| reverse() (16.8× faster) | Arrangement | 5.19 ns | 0.57 ns | 0.46 ns | 0.46 ns |
| | Array | 10 ns | 7.49 ns | 7.65 ns | 7.73 ns |
| rotate by a third (1.2× faster) | Arrangement | 16 ns | 2.97 ns | 2.38 ns | 2.41 ns |
| | Array | 10 ns | 1.75 ns | 1.58 ns | 2.77 ns |
| move first to last (18.4× faster) | Arrangement | 5.19 ns | 0.24 ns | 0.14 ns | 0.18 ns |
| | Array | 5.19 ns | 1.63 ns | 1.76 ns | 3.36 ns |
| move every tenth to the front (10.4× faster) | Arrangement | 16 ns | 3.05 ns | 2.71 ns | 2.58 ns |
| | Array | 57 ns | 28 ns | 25 ns | 27 ns |
| partition by odd rank (1.2× faster) | Arrangement | 23 ns | 13 ns | 12 ns | 13 ns |
| | Array | 13 ns | 14 ns | 14 ns | 15 ns |

### PermutableSet vs swift-collections OrderedSet

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| init from array (1.3× faster) | PermutableSet | 109 ns | 37 ns | 44 ns | 56 ns |
| | OrderedSet | 42 ns | 49 ns | 58 ns | 74 ns |
| append one at a time (1.2× faster) | PermutableSet | 154 ns | 150 ns | 148 ns | 178 ns |
| | OrderedSet | 141 ns | 178 ns | 191 ns | 215 ns |
| successful contains (1.9× faster) | PermutableSet | 29 ns | 43 ns | 49 ns | 90 ns |
| | OrderedSet | 60 ns | 69 ns | 134 ns | 173 ns |
| iteration (1.3× slower) | PermutableSet | 16 ns | 13 ns | 13 ns | 12 ns |
| | OrderedSet | 10 ns | 9.44 ns | 9.42 ns | 9.10 ns |
| remove 1% one at a time (98.9× faster) | PermutableSet | 18 ns | 4.15 ns | 23 ns | 320 ns |
| | OrderedSet | 26 ns | 125 ns | 2.2 µs | – |
| sort (1.8× slower) | PermutableSet | 52 ns | 194 ns | 272 ns | 453 ns |
| | OrderedSet | 70 ns | 181 ns | 229 ns | 257 ns |
| shuffle (3.0× faster) | PermutableSet | 47 ns | 54 ns | 54 ns | 52 ns |
| | OrderedSet | 96 ns | 114 ns | 121 ns | 159 ns |
| reverse (67.8× faster) | PermutableSet | 5.19 ns | 0.57 ns | 0.46 ns | 0.42 ns |
| | OrderedSet | 21 ns | 24 ns | 29 ns | 29 ns |
| rotate by a third (20.8× faster) | PermutableSet | 16 ns | 2.93 ns | 2.49 ns | 2.33 ns |
| | OrderedSet | 49 ns | 44 ns | 46 ns | 49 ns |
| move first to last (20.8× faster) | PermutableSet | 5.19 ns | 0.20 ns | 0.14 ns | 0.13 ns |
| | OrderedSet | 13 ns | 1.95 ns | 1.84 ns | 2.63 ns |
| move every tenth to the front (26.7× faster) | PermutableSet | 16 ns | 3.05 ns | 2.72 ns | 2.60 ns |
| | OrderedSet | 91 ns | 65 ns | 64 ns | 69 ns |
| partition by odd rank (4.0× faster) | PermutableSet | 23 ns | 13 ns | 12 ns | 13 ns |
| | OrderedSet | 39 ns | 38 ns | 39 ns | 53 ns |
| union half-overlapping (1.2× faster) | PermutableSet | 128 ns | 105 ns | 105 ns | 162 ns |
| | OrderedSet | 128 ns | 104 ns | 109 ns | 194 ns |
| intersection half-overlapping (1.4× faster) | PermutableSet | 47 ns | 65 ns | 69 ns | 96 ns |
| | OrderedSet | 76 ns | 102 ns | 131 ns | 138 ns |
| subtracting half-overlapping (1.8× faster) | PermutableSet | 42 ns | 64 ns | 68 ns | 77 ns |
| | OrderedSet | 70 ns | 106 ns | 130 ns | 137 ns |

### IdentifiedSet vs Point-Free IdentifiedArray

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| init from array (3.2× faster) | IdentifiedSet | 79 ns | 36 ns | 37 ns | 42 ns |
| | IdentifiedArray | 171 ns | 151 ns | 144 ns | 136 ns |
| append one at a time (2.2× faster) | IdentifiedSet | 130 ns | 138 ns | 143 ns | 146 ns |
| | IdentifiedArray | 255 ns | 343 ns | 334 ns | 318 ns |
| successful contains(id:) (1.2× slower) | IdentifiedSet | 29 ns | 39 ns | 43 ns | 85 ns |
| | IdentifiedArray | 47 ns | 58 ns | 66 ns | 69 ns |
| subscript(id:) read (1.2× faster) | IdentifiedSet | 49 ns | 54 ns | 72 ns | 134 ns |
| | IdentifiedArray | 70 ns | 81 ns | 85 ns | 161 ns |
| iteration (1.4× slower) | IdentifiedSet | 18 ns | 13 ns | 13 ns | 12 ns |
| | IdentifiedArray | 10 ns | 9.07 ns | 8.95 ns | 8.58 ns |
| remove(id:) 1% (84.4× faster) | IdentifiedSet | 13 ns | 4.15 ns | 22 ns | 321 ns |
| | IdentifiedArray | 18 ns | 126 ns | 1.8 µs | – |
| removeAll(where:) half (2.5× faster) | IdentifiedSet | 16 ns | 31 ns | 30 ns | 31 ns |
| | IdentifiedArray | 52 ns | 81 ns | 79 ns | 80 ns |
| reverse() (68.1× faster) | IdentifiedSet | 7.81 ns | 0.57 ns | 0.47 ns | 0.47 ns |
| | IdentifiedArray | 26 ns | 28 ns | 34 ns | 32 ns |
| shuffle() (3.2× faster) | IdentifiedSet | 60 ns | 55 ns | 55 ns | 53 ns |
| | IdentifiedArray | 104 ns | 126 ns | 117 ns | 171 ns |
| sort(by:) (2.9× faster) | IdentifiedSet | 60 ns | 199 ns | 282 ns | 452 ns |
| | IdentifiedArray | 372 ns | 926 ns | 1.1 µs | 1.3 µs |
| rotate by a third (78.2× faster) | IdentifiedSet | 16 ns | 2.85 ns | 2.62 ns | 2.38 ns |
| | IdentifiedArray | 156 ns | 208 ns | 190 ns | 186 ns |
| move first to last (757.6× faster) | IdentifiedSet | 5.19 ns | 0.24 ns | 0.14 ns | 0.16 ns |
| | IdentifiedArray | 115 ns | 133 ns | 124 ns | 121 ns |
| move every tenth to the front (402.5× faster) | IdentifiedSet | 16 ns | 3.05 ns | 2.63 ns | 2.65 ns |
| | IdentifiedArray | 89 ns | 488 ns | 680 ns | 1.1 µs |
| partition by odd rank (3.4× faster) | IdentifiedSet | 23 ns | 13 ns | 12 ns | 14 ns |
| | IdentifiedArray | 31 ns | 37 ns | 35 ns | 47 ns |

### PermutableDictionary vs swift-collections OrderedDictionary

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| init from keys and values (1.6× faster) | PermutableDictionary | 7.81 ns | 13 ns | 15 ns | 20 ns |
| | OrderedDictionary | 21 ns | 20 ns | 25 ns | 31 ns |
| subscript insert one at a time (1.2× faster) | PermutableDictionary | 117 ns | 126 ns | 117 ns | 127 ns |
| | OrderedDictionary | 128 ns | 149 ns | 144 ns | 158 ns |
| subscript lookup (2.7× slower) | PermutableDictionary | 29 ns | 36 ns | 38 ns | 141 ns |
| | OrderedDictionary | 18 ns | 22 ns | 27 ns | 52 ns |
| iteration (1.5× faster) | PermutableDictionary | 18 ns | 16 ns | 15 ns | 15 ns |
| | OrderedDictionary | 23 ns | 22 ns | 21 ns | 21 ns |
| removeValue(forKey:) 1% (51.2× faster) | PermutableDictionary | 7.81 ns | 4.44 ns | 23 ns | 327 ns |
| | OrderedDictionary | 10 ns | 48 ns | 1.2 µs | – |
| sort by key (10.2× faster) | PermutableDictionary | 16 ns | 50 ns | 78 ns | 109 ns |
| | OrderedDictionary | 393 ns | 764 ns | 918 ns | 1.1 µs |
| shuffle (3.6× faster) | PermutableDictionary | 49 ns | 54 ns | 52 ns | 54 ns |
| | OrderedDictionary | 86 ns | 98 ns | 94 ns | 194 ns |
| reverse (77.7× faster) | PermutableDictionary | 5.19 ns | 0.53 ns | 0.43 ns | 0.47 ns |
| | OrderedDictionary | 26 ns | 29 ns | 30 ns | 37 ns |
| rotate by a third (15.8× faster) | PermutableDictionary | 18 ns | 2.77 ns | 2.39 ns | 2.55 ns |
| | OrderedDictionary | 50 ns | 32 ns | 32 ns | 40 ns |
| move first to last (46.6× faster) | PermutableDictionary | 5.19 ns | 0.20 ns | 0.14 ns | 0.15 ns |
| | OrderedDictionary | 18 ns | 4.68 ns | 3.57 ns | 7.15 ns |
| move every tenth to the front (20.2× faster) | PermutableDictionary | 16 ns | 3.09 ns | 2.63 ns | 2.58 ns |
| | OrderedDictionary | 99 ns | 52 ns | 47 ns | 52 ns |
| partition by odd rank (3.0× faster) | PermutableDictionary | 23 ns | 14 ns | 13 ns | 15 ns |
| | OrderedDictionary | 31 ns | 30 ns | 30 ns | 44 ns |
| sort by value (4.6× faster) | PermutableDictionary | 60 ns | 94 ns | 140 ns | 255 ns |
| | OrderedDictionary | 341 ns | 776 ns | 892 ns | 1.2 µs |
| shuffle values among keys (2.7× faster) | PermutableDictionary | 63 ns | 61 ns | 56 ns | 70 ns |
| | OrderedDictionary | 63 ns | 74 ns | 76 ns | 189 ns |

