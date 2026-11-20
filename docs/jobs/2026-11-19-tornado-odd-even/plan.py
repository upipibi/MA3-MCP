#!/usr/bin/env python3
"""Plan for groups 608 / 609: every other yoke of group 606 `Yoke Sections`, in Aaron's own X order.
Grid: one row per Tornado row (y 0 = bars 1101-1112, y 1 = bars 1113-1124), 30 yokes across, so a
phase range along X gives each Tornado row its own full chase.
usage: plan.py <fixtures-tornado.json> <groups-600-before.json> <plan.json>"""
import json, sys
fx = json.load(open(sys.argv[1])); gr = json.load(open(sys.argv[2]))
sf = {}
def walk(n, top):
    sf[n.get("sf_index")] = {"id": n.get("id"), "bar": top}
    for c in n.get("children", []): walk(c, top)
def find(n):
    if n.get("fid") and 1101 <= n["fid"] <= 1124: walk(n, n["fid"]); return
    for c in n.get("children", []): find(c)
for r in fx["rows"]: find(r)
g606 = next(g for g in gr["rows"] if g["no"] == 606)
order = sorted(g606["member_details"], key=lambda m: m["x"])
assert len(order) == 120 and [m["x"] for m in order] == list(range(120))
assert all(g["no"] not in (608, 609) for g in gr["rows"]), "608/609 must be empty"
plan = {}
for no, name, parity in ((608, "Yoke Sections Odd", 0), (609, "Yoke Sections Even", 1)):
    members = []
    for m in order:
        if m["x"] % 2 != parity: continue
        row = 0 if m["x"] < 60 else 1
        col = ((m["x"] - 60 * row) - parity) // 2
        members.append({"id": sf[m["sf_index"]]["id"], "sf_index": m["sf_index"], "x": col, "y": row, "from_x": m["x"]})
    assert len(members) == 60 and sorted((k["y"], k["x"]) for k in members) == [(y, x) for y in (0, 1) for x in range(30)]
    cmds = ["ClearSelection"]
    for k in members: cmds += [f"Grid {k['x']}/{k['y']}", f"Fixture {k['id']}"]
    cmds += [f'Store Group {no} "{name}"', "ClearSelection"]
    plan[str(no)] = {"name": name, "members": members, "commands": cmds}
json.dump(plan, open(sys.argv[3], "w"), indent=1)
for no, p in plan.items():
    print(no, p["name"], len(p["members"]), "members,", len(p["commands"]), "commands")
    print("  row 0:", " ".join(k["id"] for k in p["members"] if k["y"] == 0)[:230])
    print("  row 1 starts:", [k["id"] for k in p["members"] if k["y"] == 1][:4])
    print("  first commands:", p["commands"][:5], "... last:", p["commands"][-2:])
