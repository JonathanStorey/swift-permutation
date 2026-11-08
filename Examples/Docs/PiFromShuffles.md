# Wallis's product from shuffled cards

**Code:** [`PiFromShuffles.swift`](../Sources/FunFacts/PiFromShuffles.swift)

Shuffle 20 cards, then follow where each card went: card A landed where card B was, B landed where C was, and so on, until you come back to A. That loop is a **cycle**, and every shuffle splits the deck into cycles. A card that didn't move is a cycle of length 1.

Now ask: how often are **all** the cycles of even length? For 20 cards, about 17.6% of the time. And that number hides π. Count enough shuffles and you can read π off the result:

  π ≈ 1 / ((n + ¼) · p²)

where 2n is the number of cards and p is the share of shuffles whose cycles are all even. A million shuffles of 20 cards gives π to about two decimal places.

## Why

The number of shuffles of 2n cards whose cycles are all even turns out to be a perfect square, (1 · 3 · 5 ⋯ (2n − 1))². Dividing by the (2n)! possible shuffles leaves

  p = (1/2) · (3/4) · (5/6) ⋯ ((2n − 1)/(2n)),

which is also the chance of getting exactly n heads in 2n coin flips. That product is the reciprocal of a piece of **Wallis's product** from 1656, the first infinite formula for π, and it shrinks like 1/√(πn). The extra ¼ is a correction that makes the formula accurate even for small decks.

So a question about shuffled cards, a question about coin flips, and the area of a circle all have the same answer. Like Buffon's needle, this is a way to estimate π by experiment, but here no geometry is involved, just a deck of cards.

## In this package

Each `Permutation.random(count: 20)` stores its cycles one after another on a single line, and that line leaves out any card that stayed put. So the test is two quick reads: the line must hold all 20 cards, so there is no cycle of length 1, and every cycle in `cycles` must have even length. No card is ever moved to answer it.
