"""Arrange the Tornado yoke sections in Layout 1 under their yoke masters (2026-11-05).

Same picture as the ring block after Aaron re-spaced it: masters in two rows 200 apart, each
master's five parts in a 30-wide column hanging below it, head 1 nearest the master. A yoke
section (`<fid>.2.<head>`) is one 30 x 30 cell, the footprint of one ring. To make room the upper
row of yoke masters (`<fid>.2`) moves up so the rows are 200 apart; x and size are not touched.
usage: yokes.py plan <layout.xml> <plan.json> [preview.png] | yokes.py run <plan.json>"""
import json, os, sys
import xml.etree.ElementTree as ET
CELL, PITCH = 30, 200
def s16(v):
    v = int(v); return v - 65536 if v > 32767 else v
if sys.argv[1] == "plan":
    els = list(next(ET.fromstring(open(sys.argv[2]).read()).iter("Layout")).iter("Element"))
    T = [(i, e.get("FixtureID").split("."), s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width")), int(e.get("Height"))) for i, e in enumerate(els, 1) if ".Fixtures.Tornado" in e.get("Object", "")]
    masters = {p[0]: {"element": i, "x": x, "y": y, "w": w, "h": h} for i, p, x, y, w, h in T if len(p) == 2 and p[1] == "2"}
    rows = sorted({m["y"] for m in masters.values()}); assert len(rows) == 2, rows
    moves = []
    for f, m in masters.items():
        if m["y"] == rows[1]:
            m["new_y"] = rows[0] + PITCH; moves.append({"element": m["element"], "fixture": f + ".2", "x": m["x"], "y": m["new_y"]})
        else: m["new_y"] = m["y"]
    plan = []
    for i, p, x, y, w, h in T:
        if len(p) != 3: continue
        m = masters[p[0]]; head = int(p[2])
        plan.append({"element": i, "fixture": ".".join(p), "x": m["x"] + (m["w"] - CELL) // 2, "y": m["new_y"] - CELL * head, "w": CELL, "h": CELL})
    json.dump({"masters": masters, "master_moves": moves, "sections": plan}, open(sys.argv[3], "w"))
    boxes = [(p["x"], p["y"], CELL, CELL) for p in plan] + [(m["x"], m["new_y"], m["w"], m["h"]) for m in masters.values()]
    mine = {p["element"] for p in plan} | {m["element"] for m in masters.values()}
    others = [(i, e.get("FixtureID") or e.get("CustomTextText"), s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width") or 0), int(e.get("Height") or 0)) for i, e in enumerate(els, 1) if i not in mine]
    hits = [o for o in others if any(o[2] < b[0] + b[2] and b[0] < o[2] + o[4] and o[3] < b[1] + b[3] and b[1] < o[3] + o[5] for b in boxes)]
    print(len(masters), "masters (", len(moves), "move up by", rows[0] + PITCH - rows[1], "),", len(plan), "sections | footprint x", min(b[0] for b in boxes), "..", max(b[0] + b[2] for b in boxes), "y", min(b[1] for b in boxes), "..", max(b[1] + b[3] for b in boxes))
    print("distinct section cells:", len({(p["x"], p["y"]) for p in plan}), "| overlaps with other elements:", len(hits), hits[:5])
    if len(sys.argv) > 4:
        from PIL import Image, ImageDraw
        sc = 2.4; x0, x1 = min(b[0] for b in boxes) - 40, max(b[0] + b[2] for b in boxes) + 40; y0, y1 = min(b[1] for b in boxes) - 30, max(b[1] + b[3] for b in boxes) + 30
        im = Image.new("RGB", (int((x1 - x0) * sc), int((y1 - y0) * sc)), (20, 20, 24)); d = ImageDraw.Draw(im)
        def rect(x, y, w, h, col, label=""):
            a, b = (x - x0) * sc, (y1 - y - h) * sc; d.rectangle([a, b, a + w * sc - 1, b + h * sc - 1], outline=col)
            if label: d.text((a + 4, b + 4), label, fill=col)
        for f, m in masters.items(): rect(m["x"], m["new_y"], m["w"], m["h"], (90, 200, 255), f)
        for p in plan: rect(p["x"], p["y"], CELL, CELL, (255, 190, 60), p["fixture"].split(".")[2])
        im.save(sys.argv[4])
else:
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))
    from mcp_call import call
    G = "tornado-yokes-layout"; data = json.load(open(sys.argv[2])); plan, moves = data["sections"], data["master_moves"]
    lo, hi = min(p["element"] for p in plan), max(p["element"] for p in plan)
    cmds = [f'Set Layout 1.{m["element"]} Property "PosY" {m["y"]}' for m in moves]
    cmds += [f'Set Layout 1.{lo} Thru {hi} Property "Width" {CELL}', f'Set Layout 1.{lo} Thru {hi} Property "Height" {CELL}',
             f'Set Layout 1.{lo} Thru {hi} Property "VisibilityObjectName" "Hidden"', f'Set Layout 1.{lo} Thru {hi} Property "VisibilityBar" "Hidden"']
    for p in plan: cmds += [f'Set Layout 1.{p["element"]} Property "PosX" {p["x"]}', f'Set Layout 1.{p["element"]} Property "PosY" {p["y"]}']
    for i in range(0, len(cmds), 200):
        ok, r = call("ma3_commands", {"commands": cmds[i:i + 200], "undo_group": G, **({"close_undo": True} if i + 200 >= len(cmds) else {})})
        bad = [(x["command"], x["result"]) for x in r.get("results", []) if x["result"] != "OK"] if ok else [r]
        if bad or not ok or r["sent"] != r["total"]: print("STOPPED:", bad[:3]); sys.exit(1)
    got, off = {}, min(lo, min(m["element"] for m in moves)) - 1
    while off < hi:
        ok, r = call("ma3_children", {"address": "Layout 1", "offset": off, "limit": 200, "fields": ["OBJECT", "POSX", "POSY", "WIDTH", "HEIGHT", "VISIBILITYOBJECTNAME", "VISIBILITYBAR"]})
        for c in r["children"]: got[c["index"]] = c["properties"]
        off += 200
    def s(v): return v - 65536 if v > 32767 else v
    wrong = [p["element"] for p in plan if (got[p["element"]].get("OBJECT"), s(got[p["element"]]["POSX"]), s(got[p["element"]]["POSY"]), got[p["element"]]["WIDTH"], got[p["element"]]["HEIGHT"], got[p["element"]]["VISIBILITYOBJECTNAME"], got[p["element"]]["VISIBILITYBAR"]) != ("Fixture " + p["fixture"], p["x"], p["y"], CELL, CELL, False, False)]
    wrong += [m["element"] for m in moves if (got[m["element"]].get("OBJECT"), s(got[m["element"]]["POSX"]), s(got[m["element"]]["POSY"]), got[m["element"]]["WIDTH"]) != ("Fixture " + m["fixture"], m["x"], m["y"], 50)]
    print(f"{len(cmds)} commands; {len(plan)} sections placed, {len(moves)} masters moved; mismatches: {len(wrong)} {wrong[:3]}")
