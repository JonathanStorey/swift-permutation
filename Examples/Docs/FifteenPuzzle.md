# The 15 puzzle and the parity of a permutation

**Code:** [`FifteenPuzzle.swift`](../Sources/FunFacts/FifteenPuzzle.swift)

In 1880 the 15 puzzle swept America, and Sam Loyd later claimed to have offered $1,000 to anyone who could solve one particular arrangement: the solved board with tiles 14 and 15 swapped. Nobody collected, because the position is impossible.

## Why

Every permutation is either **even** or **odd**, depending on whether it takes an even or odd number of swaps to build. No permutation is both. A cycle of length L takes L − 1 swaps, so the parity can be read from the cycle lengths alone.

Treat the blank as a 16th tile. Each slide swaps the blank with a neighbor, so every move flips the parity of the arrangement. Each move also changes the blank's taxicab distance from the bottom-right corner by exactly one. The two parities therefore flip together, and a board can only be solved when **the arrangement's parity matches the parity of the blank's distance from home**.

Loyd's board has the blank at home (distance 0, even) but the tiles one swap from solved (odd). It can never be solved. The same rule splits all 16! arrangements into two equal halves, and every board in the solvable half can in fact be solved.

## In this package

The example puts a board into a `PermutableSet` and sorts it. `sort()` returns the `Permutation` it applied, and `isEven` gives that permutation's parity from the Foata line, without counting inversions. Across 100,000 random boards, very close to half come out solvable.
