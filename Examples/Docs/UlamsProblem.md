# Ulam's problem: the longest increasing subsequence

**Code:** [`UlamsProblem.swift`](../Sources/FunFacts/UlamsProblem.swift)

Shuffle the numbers 1 to n and look for the longest run of them, not necessarily adjacent, that appears in increasing order. How long is it?

Stanisław Ulam asked this in 1961 and ran early computer simulations. The answer is **about 2√n**. A shuffled deck of 52 cards hides an increasing run of about 11 to 12, and a million shuffled numbers hide one of about 1,980.

## Why it is deep

Vershik–Kerov and Logan–Shepp proved in 1977 that the average divided by √n tends to exactly 2. In 1999 Baik, Deift and Johansson went further: the fluctuations around 2√n follow the **Tracy–Widom distribution**, the same law that describes the largest eigenvalue of a large random matrix. Patience sorting, Young tableaux and random matrix theory all meet in one card game.

The convergence is slow, because the leading correction is about −1.77 n^(1/6). That's why the ratio printed by the example creeps up toward 2 instead of landing on it.

## Why it matters for sorting

If you can only reorder a list by picking up one element and putting it elsewhere, the fewest moves that sort it is **n minus the longest increasing subsequence**. The elements on that subsequence never need to move, and every other element needs exactly one move.

## In this package

`Permutation.forEachMove` uses exactly this to replay a reorder with the fewest single-element moves. It finds a longest increasing subsequence by patience sorting in O(n log n) and moves everything else once. The example shuffles an `Arrangement` of 100, 10,000 and 1,000,000 cards, sorts it, and keeps the permutation `sort()` returns. Counting that permutation's moves gives the fewest single-card moves that sort the hand, and n − moves is the longest increasing run, which it reports against 2√n.
