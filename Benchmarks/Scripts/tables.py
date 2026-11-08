#!/usr/bin/env python3
"""Prints Markdown tables comparing paired benchmark tasks from a swift-collections-benchmark results file.

Usage: python3 Scripts/tables.py results.json

Each cell is the fastest of the measured runs, divided by the input size, so it reads as time per element.
The note after each operation says how many times faster the first type is than the second, at the largest size both finished.
"""

import json
import sys

SIZES = [16, 1024, 16384, 262144]

PAIRS = [
    ("Arrangement vs Array", "Arrangement<Record>", "Array<Record>", [
        "sort(by:)",
        "shuffle()",
        "reverse()",
        "rotate by a third",
        "move first to last",
        "move every tenth to the front",
        "partition by odd rank",
    ]),
    ("PermutableSet vs swift-collections OrderedSet", "PermutableSet<Record>", "OrderedSet<Record>", [
        "init from array",
        "append one at a time",
        "successful contains",
        "iteration",
        "remove 1% one at a time",
        "sort",
        "shuffle",
        "reverse",
        "rotate by a third",
        "move first to last",
        "move every tenth to the front",
        "partition by odd rank",
        "union half-overlapping",
        "intersection half-overlapping",
        "subtracting half-overlapping",
    ]),
    ("IdentifiedSet vs Point-Free IdentifiedArray", "IdentifiedSet<Record>", "IdentifiedArray<Record>", [
        "init from array",
        "append one at a time",
        "successful contains(id:)",
        "subscript(id:) read",
        "iteration",
        "remove(id:) 1%",
        "removeAll(where:) half",
        "reverse()",
        "shuffle()",
        "sort(by:)",
        "rotate by a third",
        "move first to last",
        "move every tenth to the front",
        "partition by odd rank",
    ]),
    ("PermutableDictionary vs swift-collections OrderedDictionary", "PermutableDictionary<Int, Record>", "OrderedDictionary<Int, Record>", [
        "init from keys and values",
        "subscript insert one at a time",
        "subscript lookup",
        "iteration",
        "removeValue(forKey:) 1%",
        "sort by key",
        "shuffle",
        "reverse",
        "rotate by a third",
        "move first to last",
        "move every tenth to the front",
        "partition by odd rank",
        "sort by value",
        "shuffle values among keys",
    ]),
]


def seconds(sample):
    whole, attoseconds = sample
    return whole + attoseconds * 1e-18


def per_element(results, title, size):
    samples = results.get(title, {}).get(str(size))
    if not samples:
        return None
    return min(seconds(sample) for sample in samples) / size


def label(value):
    if value is None:
        return "–"
    nanoseconds = value * 1e9
    if nanoseconds >= 1000:
        return f"{nanoseconds / 1000:.1f} µs"
    if nanoseconds >= 10:
        return f"{nanoseconds:.0f} ns"
    return f"{nanoseconds:.2f} ns"


def main(path):
    with open(path) as file:
        data = json.load(file)
    results = {task["title"]: task["results"] for task in data["tasks"]}
    for heading, ours, theirs, operations in PAIRS:
        print(f"### {heading}\n")
        columns = " | ".join(f"{size:,}" for size in SIZES)
        print(f"| Operation | Type | {columns} |")
        print("| --- | --- | " + " | ".join("---:" for _ in SIZES) + " |")
        for operation in operations:
            ours_row = [per_element(results, f"{ours} {operation}", size) for size in SIZES]
            theirs_row = [per_element(results, f"{theirs} {operation}", size) for size in SIZES]
            ratio = ""
            both = [(o, t) for o, t in zip(ours_row, theirs_row) if o and t]
            if both:
                factor = both[-1][1] / both[-1][0]
                if 0.9 <= factor <= 1.1:
                    ratio = " (about even)"
                elif factor > 1:
                    ratio = f" ({factor:.1f}× faster)"
                else:
                    ratio = f" ({1 / factor:.1f}× slower)"
            print(f"| {operation}{ratio} | {ours.split('<')[0]} | " + " | ".join(label(value) for value in ours_row) + " |")
            print(f"| | {theirs.split('<')[0]} | " + " | ".join(label(value) for value in theirs_row) + " |")
        print()


if __name__ == "__main__":
    main(sys.argv[1])
