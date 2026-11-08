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

