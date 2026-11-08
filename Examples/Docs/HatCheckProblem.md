# The hat-check problem

**Code:** [`HatCheckProblem.swift`](../Sources/FunFacts/HatCheckProblem.swift)

Some n gentlemen check their hats at a restaurant. The attendant loses the tickets and hands the hats back at random. What is the probability that **no one** gets his own hat?

Pierre Rémond de Montmort posed the question in 1708 as the *problème des rencontres*, the problem of coincidences, and Leonhard Euler returned to it in 1753. The answer is one of the most surprising in probability:

| Hats | Chance nobody gets their own |
| ---: | ---: |
| 3 | 0.333333… |
| 5 | 0.366666… |
| 10 | 0.367879… |
| 1,000,000 | 0.367879… |

It settles almost at once, and the limit is **1/e**, the reciprocal of Euler's number.

## Why the answer is e

A permutation that moves every element is a **derangement**. Inclusion–exclusion counts them: start with all n! orders, take away those that fix guest 1, guest 2, and so on, add back those that fix two guests, and continue. The share left is

```
D(n) / n! = 1 − 1/1! + 1/2! − 1/3! + … ± 1/n!
```

That is term for term the Taylor series for e^x at x = −1, cut off after n terms. So the answer isn't merely close to 1/e. It **is** the series for 1/e, and adding a guest just adds the next term. The factorials in the denominators shrink so fast that 10 guests already agree with 1/e to seven digits, and D(n) is always the whole number nearest n!/e.

Euler's number keeps appearing once you look:

- **Exactly k people get their own hat** with probability tending to e^(−1)/k!. That is the Poisson distribution with mean 1, so about 36.8% get none, 36.8% get exactly one, 18.4% get exactly two, and so on.
- **The expected number of matches is exactly 1** for every n, whether 2 guests or 2 million.
- **Redrawing until nobody matches** takes n!/D(n) attempts on average, which tends to e ≈ 2.718. A [Secret Santa](SecretSanta.md) hat needs about 2.7 draws before nobody holds their own name.

The count also obeys a short recurrence, D(n) = (n − 1)(D(n − 1) + D(n − 2)). Follow guest 1's hat to guest k. Either guest k ends up with guest 1's hat (a swap, leaving D(n − 2)), or doesn't (leaving D(n − 1)).

## In this package

A `Permutation` is stored in Foata's single-line notation, which lists **only the offsets that move**. So a permutation of n offsets is a derangement exactly when `cycles.movedCount == n`, read in O(1) with no extra pass. The example draws 200,000 random permutations of 20 hats and compares the share of derangements with the exact D(20)/20! and with 1/e. `Permutation.derangement(count:)` draws one uniformly when you need it.
