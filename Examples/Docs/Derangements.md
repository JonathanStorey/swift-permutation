# Derangements and the number e

**Code:** [`Derangements.swift`](../Sources/FunFacts/Derangements.swift)

At a dinner party, the coat check loses its tags and hands every guest a coat at random. What is the chance that nobody gets their own coat back?

With 3 guests the answer is 2/6. With 20 guests it is 0.367879… With a million guests it is still 0.367879… The answer stops depending on the number of guests almost at once, and the limit is **1/e**.

## Why

A permutation that moves every element is called a **derangement**. By inclusion–exclusion, the share of the n! arrangements that are derangements is

```
D(n) / n! = 1 − 1/1! + 1/2! − 1/3! + … ± 1/n!
```

That is the start of the series for e^(−1), and the factorials shrink so fast that by n = 10 the two agree to seven digits. The count obeys a short recurrence too, D(n) = (n − 1)(D(n − 1) + D(n − 2)). Take guest 1's coat and follow it to guest k. Either guest k ends up with guest 1's coat (a swap, leaving D(n − 2)), or they don't (leaving D(n − 1)).

## In this package

A `Permutation` is stored in Foata's single-line notation, which lists **only the offsets that move**. So a permutation of n offsets is a derangement exactly when `cycle.count == n`, with no extra pass. The example draws 200,000 random permutations of 20 and compares the share of derangements with the exact D(20)/20! and with 1/e. `Permutation.Shuffle.derangement` draws one uniformly when you need it.
