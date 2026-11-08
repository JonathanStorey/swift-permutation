# The 100 prisoners problem

**Code:** [`HundredPrisoners.swift`](../Sources/FunFacts/HundredPrisoners.swift)

Anna Gál and Peter Bro Miltersen posed this puzzle in 2003, and it has since become a classic of recreational mathematics. A hundred prisoners, numbered 1 to 100, are offered a deal. A room holds 100 drawers, and each drawer hides one prisoner's number, shuffled at random. One at a time, each prisoner may open 50 drawers looking for their own number, and they may not communicate afterward. If **every** prisoner finds their number, all go free. If even one fails, none do.

Guessing at random, each prisoner succeeds half the time, so all 100 succeed with probability (1/2)^100, about 8 × 10^(−31). There is a strategy that wins about **31%** of the time.

## The strategy

Prisoner k opens drawer k first. If it holds number j, they open drawer j next, and so on. Each prisoner walks along the cycle of the drawer permutation that contains their own number, and that cycle is guaranteed to lead back to it. They succeed exactly when their cycle has 50 or fewer drawers.

So all prisoners succeed exactly when the permutation has **no cycle longer than 50**. A random permutation of 100 has a cycle of length L > 50 with probability exactly 1/L, and at most one such cycle can exist. That gives

```
P(freed) = 1 − (1/51 + 1/52 + … + 1/100) ≈ 1 − ln 2 ≈ 0.3118
```

The prisoners' choices are no longer independent. They all live or die by the same cycle structure. The ln 2 is the natural logarithm, the logarithm to base e, which turns up because the sum 1/51 + … + 1/100 approximates the area under 1/x from 50 to 100. The answer barely moves as the prison grows, and for any number of prisoners the strategy wins more than 30% of the time.

## In this package

`Permutation.cycles` reads the cycles straight off the Foata line in one pass, since every cycle starts at a new left-to-right maximum. The example draws 100,000 rooms and frees the prisoners when `cycleLengths.max()` is at most 50.
