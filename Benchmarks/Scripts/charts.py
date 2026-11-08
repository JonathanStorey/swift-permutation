#!/usr/bin/env python3
"""Draws the benchmark charts from a swift-collections-benchmark results file.

Usage: python3 Scripts/charts.py results.json Charts

Every chart pairs one of this package's collections with the collection it replaces. The package's
collection is always a solid green line and the other is always a dashed red line, so the winner of each
panel reads at a glance. Each panel is one operation, plotting time per element (the fastest run divided
by the size) against size on log scales, and is labeled with the speedup at the largest size both finished.

It also draws speedups.png: one bar per reorder at 16,384 elements, green to the right of 1× where the
package's collection is faster and red to the left where it is slower.
"""

import json
import math
import os
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.lines import Line2D  # noqa: E402
from matplotlib.ticker import FuncFormatter, LogLocator  # noqa: E402
from matplotlib.transforms import blended_transform_factory  # noqa: E402

GREEN = "#1a8f4c"
RED = "#d1342f"
INK = "#1f2328"
MUTED = "#59636e"
GRID = "#d8dee4"
SUMMARY_SIZE = 16384


# (file stem, panel title prefix, our type, their type, [(panel title, our task suffix, their task suffix)])
PAIRS = [
    ("arrangement", "Arrangement", "Array", "Arrangement<Record>", "Array<Record>", {
        "reordering": [
            ("sort", "sort(by:)"), ("shuffle", "shuffle()"), ("reverse", "reverse()"),
            ("rotate by a third", "rotate by a third"), ("move first to last", "move first to last"),
        ],
    }),
    ("ordered-set", "PermutableSet", "OrderedSet", "PermutableSet<Int>", "OrderedSet<Int>", {
        "reordering": [
            ("sort", "sort"), ("shuffle", "shuffle"), ("reverse", "reverse"),
            ("rotate by a third", "rotate by a third"), ("move first to last", "move first to last"),
        ],
        "membership": [
            ("init from array", "init from array"), ("append one at a time", "append one at a time"),
            ("successful contains", "successful contains"), ("iteration", "iteration"),
            ("remove 1% one at a time", "remove 1% one at a time"),
        ],
        "algebra": [
            ("union", "union half-overlapping"), ("intersection", "intersection half-overlapping"),
            ("subtracting", "subtracting half-overlapping"),
        ],
    }),
    ("identified-array", "IdentifiedSet", "IdentifiedArray", "IdentifiedSet<Record>", "IdentifiedArray<Record>", {
        "reordering": [
            ("sort", "sort(by:)"), ("shuffle", "shuffle()"), ("reverse", "reverse()"),
            ("rotate by a third", "rotate by a third"), ("move first to last", "move first to last"),
        ],
        "membership": [
            ("init from array", "init from array"), ("append one at a time", "append one at a time"),
            ("contains(id:)", "successful contains(id:)"), ("subscript(id:)", "subscript(id:) read"),
            ("iteration", "iteration"), ("remove(id:) 1%", "remove(id:) 1%"),
            ("removeAll(where:) half", "removeAll(where:) half"),
        ],
    }),
    ("ordered-dictionary", "PermutableDictionary", "OrderedDictionary", "PermutableDictionary<Int, Int>", "OrderedDictionary<Int, Int>", {
        "reordering": [
            ("sort by key", "sort by key"), ("sort by value", "sort by value"), ("shuffle", "shuffle"),
            ("reverse", "reverse"), ("shuffle values among keys", "shuffle values among keys"),
        ],
        "membership": [
            ("init", "init from keys and values"), ("insert one at a time", "subscript insert one at a time"),
            ("lookup", "subscript lookup"), ("iteration", "iteration"),
            ("removeValue(forKey:) 1%", "removeValue(forKey:) 1%"),
        ],
    }),
]

TITLES = {"reordering": "Reordering", "membership": "Building, lookup and removal", "algebra": "Set operations"}


def seconds(sample):
    whole, attoseconds = sample
    return whole + attoseconds * 1e-18


def series(results, title):
    """Time per element at each measured size, from the fastest run at that size."""
    points = {}
    for size, samples in results.get(title, {}).items():
        if samples and int(size) > 0:
            points[int(size)] = min(seconds(sample) for sample in samples) / int(size)
    return dict(sorted(points.items()))


def duration(value, _position=None):
    nanoseconds = value * 1e9
    if nanoseconds >= 1000:
        return f"{nanoseconds / 1000:g} µs"
    if nanoseconds >= 1:
        return f"{nanoseconds:g} ns"
    return f"{nanoseconds * 1000:g} ps"


def count(value, _position=None):
    if value >= 1024 * 1024:
        return f"{value / (1024 * 1024):g}M"
    if value >= 1024:
        return f"{value / 1024:g}k"
    return f"{value:g}"


def speedup_label(factor):
    if 0.9 <= factor <= 1.1:
        return "about even", MUTED
    if factor > 1:
        return f"{factor:.1f}× faster" if factor < 10 else f"{factor:.0f}× faster", GREEN
    inverse = 1 / factor
    return (f"{inverse:.1f}× slower" if inverse < 10 else f"{inverse:.0f}× slower"), RED


def style(axes):
    axes.set_xscale("log", base=2)
    axes.set_yscale("log")
    axes.xaxis.set_major_locator(LogLocator(base=2, numticks=12))
    axes.xaxis.set_major_formatter(FuncFormatter(count))
    axes.yaxis.set_major_formatter(FuncFormatter(duration))
    axes.yaxis.set_minor_formatter(FuncFormatter(lambda *_: ""))
    axes.grid(True, which="major", color=GRID, linewidth=0.8)
    axes.grid(False, which="minor")
    for side in ("top", "right"):
        axes.spines[side].set_visible(False)
    for side in ("left", "bottom"):
        axes.spines[side].set_color(GRID)
    axes.tick_params(colors=MUTED, labelsize=8, length=0)


def panel_grid(results, ours_name, theirs_name, ours_type, theirs_type, panels, heading, path):
    drawn = [(title, series(results, f"{ours_type} {ours}"), series(results, f"{theirs_type} {theirs}"))
             for title, ours, theirs in ((t, s, s) for t, s in panels)]
    drawn = [entry for entry in drawn if entry[1] and entry[2]]
    if not drawn:
        return
    columns = min(3, len(drawn))
    rows = math.ceil(len(drawn) / columns)
    figure, grid = plt.subplots(rows, columns, figsize=(4.2 * columns, 3.1 * rows + 0.9), squeeze=False)
    for axes in grid.flat[len(drawn):]:
        axes.set_visible(False)
    for axes, (title, ours, theirs) in zip(grid.flat, drawn):
        style(axes)
        axes.plot(list(theirs), list(theirs.values()), color=RED, linewidth=2, linestyle=(0, (5, 3)))
        axes.plot(list(ours), list(ours.values()), color=GREEN, linewidth=2.6)
        shared = [size for size in ours if size in theirs]
        axes.set_title(title, loc="left", fontsize=11, color=INK, fontweight="bold", pad=18)
        if shared:
            text, color = speedup_label(theirs[shared[-1]] / ours[shared[-1]])
            axes.text(0, 1.02, f"{text} at {count(shared[-1])}", transform=axes.transAxes, fontsize=9,
                      color=color, fontweight="bold", va="bottom")
    legend = [Line2D([0], [0], color=GREEN, linewidth=2.6, label=ours_name),
              Line2D([0], [0], color=RED, linewidth=2, linestyle=(0, (5, 3)), label=theirs_name)]
    figure.legend(handles=legend, loc="upper right", ncol=2, frameon=False, fontsize=10)
    figure.suptitle(f"{heading}: {ours_name} and {theirs_name}", x=0.01, ha="left", fontsize=13,
                    color=INK, fontweight="bold")
    figure.text(0.01, 0.005, "Time per element, log scales. Lower is better.", fontsize=8, color=MUTED)
    figure.tight_layout(rect=(0, 0.02, 1, 0.94))
    figure.savefig(path, dpi=160, facecolor="white")
    plt.close(figure)


def speedups(results, path):
    bars = []
    for _stem, ours_name, theirs_name, ours_type, theirs_type, groups in PAIRS:
        for title, suffix in groups.get("reordering", []):
            ours = series(results, f"{ours_type} {suffix}").get(SUMMARY_SIZE)
            theirs = series(results, f"{theirs_type} {suffix}").get(SUMMARY_SIZE)
            if ours and theirs:
                bars.append((f"{ours_name} vs {theirs_name}", title, theirs / ours))
    if not bars:
        return
    figure, axes = plt.subplots(figsize=(9, 0.34 * len(bars) + 1.6))
    labels = []
    positions = []
    position = 0
    previous = None
    for group, title, factor in bars:
        if group != previous:
            if previous is not None:
                position += 0.5
            axes.text(0.005, position, group, transform=blended_transform_factory(axes.transAxes, axes.transData),
                      fontsize=10, fontweight="bold", color=INK, ha="left", va="center", zorder=5,
                      bbox={"facecolor": "white", "edgecolor": "none", "pad": 2})
            position += 1
            previous = group
        color = GREEN if factor >= 1 else RED
        axes.barh(position, math.log10(factor), left=0, height=0.68, color=color)
        text, _ = speedup_label(factor)
        offset = 0.04 if factor >= 1 else -0.04
        axes.text(math.log10(factor) + offset, position, text, va="center", fontsize=8.5, color=color,
                  ha="left" if factor >= 1 else "right", fontweight="bold")
        labels.append(title)
        positions.append(position)
        position += 1
    axes.set_yticks(positions, labels, fontsize=9, color=INK)
    axes.invert_yaxis()
    low = min(0, min(math.log10(f) for _, _, f in bars)) - 0.45
    high = max(math.log10(f) for _, _, f in bars) + 0.55
    axes.set_xlim(low, high)
    ticks = [t for t in range(math.floor(low), math.ceil(high) + 1)]
    axes.set_xticks(ticks, [f"{10 ** t:g}×" for t in ticks], fontsize=8, color=MUTED)
    axes.axvline(0, color=INK, linewidth=1)
    axes.grid(True, axis="x", color=GRID, linewidth=0.8)
    axes.set_axisbelow(True)
    for side in ("top", "right", "left"):
        axes.spines[side].set_visible(False)
    axes.spines["bottom"].set_color(GRID)
    axes.tick_params(length=0)
    axes.set_title(f"Reorder speedups at {SUMMARY_SIZE:,} elements", loc="left", fontsize=13, color=INK,
                   fontweight="bold", pad=22)
    axes.text(0, 1.005, "How many times faster each package collection is than the one it replaces (log scale).",
              transform=axes.transAxes, fontsize=8.5, color=MUTED)
    figure.tight_layout()
    figure.savefig(path, dpi=160, facecolor="white")
    plt.close(figure)


def main(source, directory):
    with open(source) as file:
        data = json.load(file)
    results = {task["title"]: task["results"] for task in data["tasks"]}
    os.makedirs(directory, exist_ok=True)
    for stem, ours_name, theirs_name, ours_type, theirs_type, groups in PAIRS:
        for group, panels in groups.items():
            panel_grid(results, ours_name, theirs_name, ours_type, theirs_type, panels, TITLES[group],
                       os.path.join(directory, f"{stem}-{group}.png"))
    speedups(results, os.path.join(directory, "speedups.png"))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
