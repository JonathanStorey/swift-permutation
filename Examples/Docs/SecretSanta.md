# Secret Santa and the one big chain

**Code:** [`SecretSanta.swift`](../Sources/FunFacts/SecretSanta.swift)

Ten friends put their names in a hat and draw again whenever someone pulls their own name, so every fair draw is a **derangement**. Now follow the gifts: Ava buys for someone, who buys for someone else, and so on until the chain comes back to Ava. Does the chain pass through all ten friends before it closes?

Only about **27% of the time**. Most draws split the party into two or more separate loops. The chance of one unbroken chain is close to **e/n**, so it shrinks as the group grows, even though the number of possible single chains grows enormously.

## Why

A draw is a permutation with no fixed points, and following the gifts traces one of its cycles. One chain through everyone is a single cycle of length n, and there are (n − 1)! of those, because you can list the chain starting from Ava and order the other n − 1 people any way you like.

The number of derangements is D(n) ≈ n!/e, from the [hat-check problem](Derangements.md). Dividing gives

  (n − 1)! / D(n) ≈ (n − 1)! · e / n! = **e/n**.

For ten people that's 0.2718, and the exact value, 362,880 / 1,334,961, agrees to four decimal places. The approximation is that good because D(n) is the nearest whole number to n!/e.

If your group wants one big chain, which makes for a nicer reveal, a fair hat draw rarely gives you one. Drawing a random **cyclic** shuffle does it every time, and every chain is equally likely.

## In this package

The example builds a `PermutableDictionary` that maps each giver to themselves, then calls `recipients.reassignValues(shuffling: .derangement)`. Reassigning the values hands the recipients around while every giver stays where they are, so the keys keep their order and no one draws their own name. It then follows the gifts with ordinary key lookups and counts how often the chain visits everyone, over 200,000 draws.

Shuffling `recipients.keys` or `recipients.values` instead would move whole entries, so every giver would keep the recipient they had. That distinction between moving entries and handing values around is what `PermutableDictionary` is built for.
