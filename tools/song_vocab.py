#!/usr/bin/env python3
"""A song's look vocabulary: the distinct looks it uses (full state after tracking), each printed once
with the cues that show it, so repeated sections collapse. Input: the --json files of song_looks.py.
usage: song_vocab.py <looks.json> [...]"""
import sys, json
ORDER = ("dim", "col", "pos", "zoom", "strobe", "phasers")
for path in sys.argv[1:]:
    d = json.load(open(path)); looks, order = {}, []
    for c in d["cues"]:
        key = json.dumps(c["state"], sort_keys=True)
        if key not in looks: looks[key] = {"cues": [], "state": c["state"]}; order.append(key)
        looks[key]["cues"].append("%s %s%s" % (c["no"], c["name"], "" if c["changes"] else " (hold)"))
    print("\n# %s: %d cues, %d distinct looks" % (d["title"], len(d["cues"]), len(order)))
    print("fades: " + ", ".join("%s %g" % (c["no"], c["fade"] or 0) for c in d["cues"]))
    prev = {}
    for i, key in enumerate(order):
        L = looks[key]
        print("LOOK %s  <- %s" % (chr(65 + i) if i < 26 else "Z%d" % i, "; ".join(L["cues"])))
        for f, row in sorted(L["state"].items()):
            line = " | ".join("%s: %s" % (k, row[k]) for k in ORDER if k in row)
            if prev.get(f) == line: continue          # unchanged against the previous distinct look
            print("    %-24s ×%-3d %s" % (f[:24], row["n"], line[:210]))
            prev[f] = line
