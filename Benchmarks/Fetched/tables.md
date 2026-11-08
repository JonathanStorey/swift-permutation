### Arrangement vs Array

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| sort(by:) (2.4× slower) | Arrangement | 63 ns | 183 ns | 251 ns | 522 ns |
| | Array | 44 ns | 127 ns | 173 ns | 220 ns |
| shuffle() (1.9× faster) | Arrangement | 47 ns | 51 ns | 51 ns | 53 ns |
| | Array | 57 ns | 68 ns | 69 ns | 99 ns |
| reverse() (16.6× faster) | Arrangement | 5.19 ns | 0.57 ns | 0.44 ns | 0.46 ns |
| | Array | 7.81 ns | 6.71 ns | 7.47 ns | 7.64 ns |
| rotate by a third (1.1× faster) | Arrangement | 16 ns | 2.69 ns | 2.38 ns | 2.41 ns |
| | Array | 10 ns | 1.59 ns | 1.52 ns | 2.73 ns |
| move first to last (16.4× faster) | Arrangement | 5.19 ns | 0.24 ns | 0.13 ns | 0.17 ns |
| | Array | 5.19 ns | 1.50 ns | 1.70 ns | 2.75 ns |
| move every tenth to the front (10.8× faster) | Arrangement | 18 ns | 2.85 ns | 2.62 ns | 2.58 ns |
| | Array | 60 ns | 28 ns | 28 ns | 28 ns |
| partition by odd rank (1.2× faster) | Arrangement | 26 ns | 14 ns | 12 ns | 12 ns |
| | Array | 16 ns | 16 ns | 15 ns | 15 ns |

### PermutableSet vs swift-collections OrderedSet

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| init from array (1.3× faster) | PermutableSet | 120 ns | 42 ns | 42 ns | 59 ns |
| | OrderedSet | 42 ns | 51 ns | 52 ns | 75 ns |
| append one at a time (1.3× faster) | PermutableSet | 174 ns | 145 ns | 152 ns | 187 ns |
| | OrderedSet | 156 ns | 175 ns | 185 ns | 243 ns |
| successful contains (1.9× faster) | PermutableSet | 31 ns | 45 ns | 49 ns | 98 ns |
| | OrderedSet | 70 ns | 71 ns | 76 ns | 186 ns |
| iteration (1.7× slower) | PermutableSet | 18 ns | 15 ns | 15 ns | 15 ns |
| | OrderedSet | 10 ns | 8.46 ns | 8.50 ns | 8.51 ns |
| remove 1% one at a time (105.5× faster) | PermutableSet | 18 ns | 3.83 ns | 21 ns | 329 ns |
| | OrderedSet | 10 ns | 141 ns | 2.3 µs | – |
| sort (1.8× slower) | PermutableSet | 68 ns | 181 ns | 247 ns | 471 ns |
| | OrderedSet | 89 ns | 167 ns | 213 ns | 260 ns |
| shuffle (3.4× faster) | PermutableSet | 52 ns | 51 ns | 51 ns | 52 ns |
| | OrderedSet | 112 ns | 114 ns | 120 ns | 174 ns |
| reverse (71.2× faster) | PermutableSet | 7.81 ns | 0.53 ns | 0.43 ns | 0.42 ns |
| | OrderedSet | 26 ns | 23 ns | 27 ns | 30 ns |
| rotate by a third (19.8× faster) | PermutableSet | 21 ns | 2.65 ns | 2.55 ns | 2.52 ns |
| | OrderedSet | 60 ns | 43 ns | 46 ns | 50 ns |
| move first to last (16.5× faster) | PermutableSet | 5.19 ns | 0.20 ns | 0.14 ns | 0.15 ns |
| | OrderedSet | 16 ns | 1.99 ns | 1.82 ns | 2.54 ns |
| move every tenth to the front (28.1× faster) | PermutableSet | 18 ns | 2.89 ns | 2.61 ns | 2.59 ns |
| | OrderedSet | 94 ns | 65 ns | 68 ns | 73 ns |
| partition by odd rank (3.3× faster) | PermutableSet | 26 ns | 14 ns | 12 ns | 12 ns |
| | OrderedSet | 34 ns | 43 ns | 38 ns | 41 ns |
| union half-overlapping (1.2× faster) | PermutableSet | 130 ns | 106 ns | 108 ns | 128 ns |
| | OrderedSet | 94 ns | 102 ns | 108 ns | 158 ns |
| intersection half-overlapping (1.7× faster) | PermutableSet | 52 ns | 68 ns | 72 ns | 83 ns |
| | OrderedSet | 86 ns | 106 ns | 114 ns | 142 ns |
| subtracting half-overlapping (1.8× faster) | PermutableSet | 47 ns | 65 ns | 69 ns | 83 ns |
| | OrderedSet | 76 ns | 105 ns | 118 ns | 146 ns |

### IdentifiedSet vs Point-Free IdentifiedArray

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| init from array (3.3× faster) | IdentifiedSet | 97 ns | 34 ns | 35 ns | 44 ns |
| | IdentifiedArray | 178 ns | 151 ns | 142 ns | 146 ns |
| append one at a time (2.1× faster) | IdentifiedSet | 154 ns | 145 ns | 137 ns | 158 ns |
| | IdentifiedArray | 263 ns | 310 ns | 322 ns | 333 ns |
| successful contains(id:) (1.3× slower) | IdentifiedSet | 31 ns | 44 ns | 43 ns | 89 ns |
| | IdentifiedArray | 55 ns | 60 ns | 63 ns | 70 ns |
| subscript(id:) read (1.2× faster) | IdentifiedSet | 52 ns | 61 ns | 61 ns | 158 ns |
| | IdentifiedArray | 76 ns | 83 ns | 86 ns | 188 ns |
| iteration (1.7× slower) | IdentifiedSet | 18 ns | 16 ns | 15 ns | 15 ns |
| | IdentifiedArray | 10 ns | 8.46 ns | 8.44 ns | 8.53 ns |
| remove(id:) 1% (99.7× faster) | IdentifiedSet | 13 ns | 3.58 ns | 21 ns | 333 ns |
| | IdentifiedArray | 16 ns | 104 ns | 2.1 µs | – |
| removeAll(where:) half (2.7× faster) | IdentifiedSet | 21 ns | 31 ns | 30 ns | 31 ns |
| | IdentifiedArray | 49 ns | 78 ns | 79 ns | 84 ns |
| reverse() (69.8× faster) | IdentifiedSet | 5.19 ns | 0.57 ns | 0.46 ns | 0.45 ns |
| | IdentifiedArray | 23 ns | 25 ns | 31 ns | 32 ns |
| shuffle() (3.6× faster) | IdentifiedSet | 52 ns | 50 ns | 53 ns | 53 ns |
| | IdentifiedArray | 107 ns | 118 ns | 120 ns | 189 ns |
| sort(by:) (2.9× faster) | IdentifiedSet | 65 ns | 181 ns | 250 ns | 473 ns |
| | IdentifiedArray | 461 ns | 917 ns | 1.1 µs | 1.4 µs |
| rotate by a third (81.0× faster) | IdentifiedSet | 18 ns | 2.69 ns | 2.37 ns | 2.40 ns |
| | IdentifiedArray | 159 ns | 189 ns | 190 ns | 194 ns |
| move first to last (797.9× faster) | IdentifiedSet | 5.25 ns | 0.20 ns | 0.13 ns | 0.16 ns |
| | IdentifiedArray | 125 ns | 125 ns | 125 ns | 127 ns |
| move every tenth to the front (366.9× faster) | IdentifiedSet | 18 ns | 2.85 ns | 2.63 ns | 2.68 ns |
| | IdentifiedArray | 89 ns | 505 ns | 706 ns | 982 ns |
| partition by odd rank (3.1× faster) | IdentifiedSet | 23 ns | 14 ns | 12 ns | 12 ns |
| | IdentifiedArray | 31 ns | 42 ns | 38 ns | 38 ns |

### PermutableDictionary vs swift-collections OrderedDictionary

| Operation | Type | 16 | 1,024 | 16,384 | 262,144 |
| --- | --- | ---: | ---: | ---: | ---: |
| init from keys and values (1.7× faster) | PermutableDictionary | 7.81 ns | 12 ns | 15 ns | 16 ns |
| | OrderedDictionary | 21 ns | 21 ns | 25 ns | 27 ns |
| subscript insert one at a time (1.1× faster) | PermutableDictionary | 122 ns | 122 ns | 124 ns | 143 ns |
| | OrderedDictionary | 130 ns | 141 ns | 146 ns | 161 ns |
| subscript lookup (2.5× slower) | PermutableDictionary | 34 ns | 35 ns | 39 ns | 144 ns |
| | OrderedDictionary | 16 ns | 21 ns | 27 ns | 57 ns |
| iteration (1.4× faster) | PermutableDictionary | 21 ns | 17 ns | 17 ns | 17 ns |
| | OrderedDictionary | 26 ns | 24 ns | 24 ns | 24 ns |
| removeValue(forKey:) 1% (55.3× faster) | PermutableDictionary | 16 ns | 4.31 ns | 21 ns | 324 ns |
| | OrderedDictionary | 13 ns | 46 ns | 1.2 µs | – |
| sort by key (8.9× faster) | PermutableDictionary | 26 ns | 66 ns | 103 ns | 135 ns |
| | OrderedDictionary | 422 ns | 806 ns | 981 ns | 1.2 µs |
| shuffle (2.9× faster) | PermutableDictionary | 49 ns | 50 ns | 51 ns | 52 ns |
| | OrderedDictionary | 94 ns | 96 ns | 102 ns | 152 ns |
| reverse (81.4× faster) | PermutableDictionary | 5.19 ns | 0.49 ns | 0.44 ns | 0.42 ns |
| | OrderedDictionary | 26 ns | 27 ns | 31 ns | 34 ns |
| rotate by a third (14.1× faster) | PermutableDictionary | 18 ns | 2.56 ns | 2.39 ns | 2.51 ns |
| | OrderedDictionary | 49 ns | 29 ns | 32 ns | 35 ns |
| move first to last (39.5× faster) | PermutableDictionary | 5.19 ns | 0.20 ns | 0.13 ns | 0.16 ns |
| | OrderedDictionary | 16 ns | 4.56 ns | 3.44 ns | 6.22 ns |
| move every tenth to the front (21.2× faster) | PermutableDictionary | 18 ns | 2.85 ns | 2.63 ns | 2.59 ns |
| | OrderedDictionary | 99 ns | 50 ns | 51 ns | 55 ns |
| partition by odd rank (2.7× faster) | PermutableDictionary | 26 ns | 14 ns | 13 ns | 12 ns |
| | OrderedDictionary | 29 ns | 32 ns | 33 ns | 33 ns |
| sort by value (6.0× faster) | PermutableDictionary | 60 ns | 86 ns | 133 ns | 198 ns |
| | OrderedDictionary | 380 ns | 804 ns | 985 ns | 1.2 µs |
| shuffle values among keys (2.0× faster) | PermutableDictionary | 60 ns | 56 ns | 56 ns | 58 ns |
| | OrderedDictionary | 65 ns | 73 ns | 75 ns | 118 ns |

