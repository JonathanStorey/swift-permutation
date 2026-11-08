#!/usr/bin/env python3
"""Draws the benchmark charts from a swift-collections-benchmark results file.

Usage: python3 Scripts/charts.py results.json Charts

Each chart is one operation, with every collection that has it on the same graph: Arrangement and Array,
PermutableSet and OrderedSet, PermutableDictionary and OrderedDictionary, IdentifiedSet and IdentifiedArray.
Each pair has its own hue. The package's collection is the darker solid line and the collection it replaces
the lighter dashed line, and the legend gives the speedup at the largest size both finished. Every line plots
time per element (the fastest run divided by the size) against size on log scales.

It also draws speedups.png: one bar per reorder and pair at 16,384 elements, green to the right of 1×
where the package's collection is faster and red to the left where it is slower.
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

# Below 16 elements a single call's fixed cost swamps the time per element, so the lines start there.
SMALLEST = 16

# One hue per pair, in the order of PAIRS: a dark shade for the package's collection, a light one for the other.
HUES = [
    ("#1a7f37", "#8fd19e"),
    ("#0b5cad", "#8cc4f5"),
    ("#8250df", "#c9b3f5"),
    ("#bc4c00", "#f5b98c"),
]


# Each pair: the package's collection, the collection it replaces, and their task title prefixes.
PAIRS = [
    ("Arrangement", "Array", "Arrangement<Record>", "Array<Record>"),
    ("PermutableSet", "OrderedSet", "PermutableSet<Record>", "OrderedSet<Record>"),
    ("PermutableDictionary", "OrderedDictionary", "PermutableDictionary<Int, Record>", "OrderedDictionary<Int, Record>"),
    ("IdentifiedSet", "IdentifiedArray", "IdentifiedSet<Record>", "IdentifiedArray<Record>"),
]

# Each operation: file stem, chart title, whether it is a reorder, and the task suffix for each pair that has it.
OPERATIONS = [
    ("sort", "Sort", True, {"Arrangement": "sort(by:)", "PermutableSet": "sort", "PermutableDictionary": "sort by key", "IdentifiedSet": "sort(by:)"}),
    ("shuffle", "Shuffle", True, {"Arrangement": "shuffle()", "PermutableSet": "shuffle", "PermutableDictionary": "shuffle", "IdentifiedSet": "shuffle()"}),
    ("reverse", "Reverse", True, {"Arrangement": "reverse()", "PermutableSet": "reverse", "PermutableDictionary": "reverse", "IdentifiedSet": "reverse()"}),
    ("rotate", "Rotate by a third", True, {name: "rotate by a third" for name, *_ in PAIRS}),
    ("move", "Move first to last", True, {name: "move first to last" for name, *_ in PAIRS}),
    ("move-many", "Move every tenth to the front", True, {name: "move every tenth to the front" for name, *_ in PAIRS}),
    ("partition", "Partition (stable here, unstable in the others)", True, {name: "partition by odd rank" for name, *_ in PAIRS}),
    ("init", "Build from an array", False, {"PermutableSet": "init from array", "PermutableDictionary": "init from keys and values", "IdentifiedSet": "init from array"}),
    ("append", "Append one at a time", False, {"PermutableSet": "append one at a time", "PermutableDictionary": "subscript insert one at a time", "IdentifiedSet": "append one at a time"}),
    ("lookup", "Look up every element", False, {"PermutableSet": "successful contains", "PermutableDictionary": "subscript lookup", "IdentifiedSet": "subscript(id:) read"}),
    ("remove", "Remove 1% one at a time", False, {"PermutableSet": "remove 1% one at a time", "PermutableDictionary": "removeValue(forKey:) 1%", "IdentifiedSet": "remove(id:) 1%"}),
    ("iteration", "Iterate", False, {"PermutableSet": "iteration", "PermutableDictionary": "iteration", "IdentifiedSet": "iteration"}),
    ("set-operations", "Union, intersection and subtraction", False, {}),
]


def seconds(sample):
    whole, attoseconds = sample
    return whole + attoseconds * 1e-18


def series(results, title):
    """Time per element at each measured power-of-two size from SMALLEST up, from the fastest run at that size."""
    points = {}
    for size, samples in results.get(title, {}).items():
        if samples and int(size) >= SMALLEST and int(size) & (int(size) - 1) == 0:
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
    axes.yaxis.set_major_locator(LogLocator(base=10, subs=(1.0, 2.0, 5.0), numticks=12))
    axes.yaxis.set_major_formatter(FuncFormatter(duration))
    axes.yaxis.set_minor_formatter(FuncFormatter(lambda *_: ""))
    axes.grid(True, which="major", color=GRID, linewidth=0.8)
    axes.grid(False, which="minor")
    for side in ("top", "right"):
        axes.spines[side].set_visible(False)
    for side in ("left", "bottom"):
        axes.spines[side].set_color(GRID)
    axes.tick_params(colors=MUTED, labelsize=8, length=0)


def draw_panel(axes, title, ours, theirs):
    style(axes)
    axes.plot(list(theirs), list(theirs.values()), color=RED, linewidth=2, linestyle=(0, (5, 3)))
    axes.plot(list(ours), list(ours.values()), color=GREEN, linewidth=2.6)
    axes.set_title(title, loc="left", fontsize=10.5, color=INK, fontweight="bold", pad=18)
    shared = [size for size in ours if size in theirs]
    if shared:
        text, color = speedup_label(theirs[shared[-1]] / ours[shared[-1]])
        axes.text(0, 1.02, f"{text} at {count(shared[-1])}", transform=axes.transAxes, fontsize=9,
                  color=color, fontweight="bold", va="bottom")


def figure_for(panels, heading, path, legend_names):
    columns = min(4, len(panels))
    rows = math.ceil(len(panels) / columns)
    figure, grid = plt.subplots(rows, columns, figsize=(3.9 * columns, 3.1 * rows + 0.9), squeeze=False)
    for axes in grid.flat[len(panels):]:
        axes.set_visible(False)
    for axes, (title, ours, theirs) in zip(grid.flat, panels):
        draw_panel(axes, title, ours, theirs)
    legend = [Line2D([0], [0], color=GREEN, linewidth=2.6, label=legend_names[0]),
              Line2D([0], [0], color=RED, linewidth=2, linestyle=(0, (5, 3)), label=legend_names[1])]
    figure.legend(handles=legend, loc="upper right", ncol=2, frameon=False, fontsize=10)
    figure.suptitle(heading, x=0.01, ha="left", fontsize=13, color=INK, fontweight="bold")
    figure.text(0.01, 0.005, "Time per element from 16 elements up, log scales. Lower is better.", fontsize=8, color=MUTED)
    figure.tight_layout(rect=(0, 0.02, 1, 0.93))
    figure.savefig(path, dpi=160, facecolor="white")
    plt.close(figure)


def operation_chart(results, stem, heading, tasks, directory):
    """One graph for the operation with every collection on it. Each pair shares a hue: the package's
    collection is the darker solid line and the collection it replaces the lighter dashed line."""
    figure, axes = plt.subplots(figsize=(9, 5.6))
    style(axes)
    handles = []
    for (ours_name, theirs_name, ours_type, theirs_type), (dark, light) in zip(PAIRS, HUES):
        suffix = tasks.get(ours_name)
        if not suffix:
            continue
        ours = series(results, f"{ours_type} {suffix}")
        theirs = series(results, f"{theirs_type} {suffix}")
        if not (ours and theirs):
            continue
        axes.plot(list(theirs), list(theirs.values()), color=light, linewidth=2, linestyle=(0, (5, 3)))
        axes.plot(list(ours), list(ours.values()), color=dark, linewidth=2.6)
        shared = [size for size in ours if size in theirs]
        note = ""
        if shared:
            text, _ = speedup_label(theirs[shared[-1]] / ours[shared[-1]])
            note = f"  ({text} at {count(shared[-1])})"
        handles.append(Line2D([0], [0], color=dark, linewidth=2.6, label=f"{ours_name}{note}"))
        handles.append(Line2D([0], [0], color=light, linewidth=2, linestyle=(0, (5, 3)), label=theirs_name))
    if not handles:
        plt.close(figure)
        return
    axes.legend(handles=handles, loc="upper left", bbox_to_anchor=(1.01, 1), frameon=False, fontsize=9)
    axes.set_title(heading, loc="left", fontsize=13, color=INK, fontweight="bold", pad=10)
    figure.text(0.01, 0.01, "Time per element from 16 elements up, log scales. Lower is better. Solid lines are this package's "
                "collections, dashed lines the collections they replace.", fontsize=8, color=MUTED)
    figure.tight_layout(rect=(0, 0.03, 1, 1))
    figure.savefig(os.path.join(directory, f"{stem}.png"), dpi=160, facecolor="white")
    plt.close(figure)


def set_operations_chart(results, directory):
    panels = []
    for title in ("union", "intersection", "subtracting"):
        ours = series(results, f"PermutableSet<Record> {title} half-overlapping")
        theirs = series(results, f"OrderedSet<Record> {title} half-overlapping")
        if ours and theirs:
            panels.append((f"{title}, half overlapping", ours, theirs))
    if panels:
        figure_for(panels, "Set operations", os.path.join(directory, "set-operations.png"),
                   ("PermutableSet", "OrderedSet"))


def speedups(results, path):
    bars = []
    for _stem, heading, is_reorder, tasks in OPERATIONS:
        if not is_reorder:
            continue
        for ours_name, theirs_name, ours_type, theirs_type in PAIRS:
            suffix = tasks.get(ours_name)
            ours = series(results, f"{ours_type} {suffix}").get(SUMMARY_SIZE) if suffix else None
            theirs = series(results, f"{theirs_type} {suffix}").get(SUMMARY_SIZE) if suffix else None
            if ours and theirs:
                bars.append((heading, f"{ours_name} vs {theirs_name}", theirs / ours))
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
    for stem, heading, _is_reorder, tasks in OPERATIONS:
        if stem == "set-operations":
            set_operations_chart(results, directory)
        else:
            operation_chart(results, stem, heading, tasks, directory)
    speedups(results, os.path.join(directory, "speedups.png"))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
