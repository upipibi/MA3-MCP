"""Arrange the Tornado ring sections in Layout 1 against their ring masters (2026-11-05).

Aaron dropped in 24 ring masters (`<fid>.1` = [LED Array], 50 x 50, two rows of 12) and the 960
ring sections (`<fid>.2.<head>.<led>`, 8 LEDs on each of 5 heads), which landed in one long line.
Masters are not moved or resized. Each bar's five heads become five tiny rings (3 x 3 cells of
10 x 10 with the centre empty, LED 1 top-left then clockwise) stacked in a 30 x 150 column centred
on the 50-wide master: below the master for the lower row, above it for the upper row, head 1 on top.
usage: rings.py plan <layout.xml> <plan.json> [preview.png] | rings.py run <plan.json> [first-bar-only]"""
import json, os, re, sys
import xml.etree.ElementTree as ET
CELL, RING = 10, 30
SPOT = [(0, 2), (1, 2), (2, 2), (2, 1), (2, 0), (1, 0), (0, 0), (0, 1)]   # (col, row from bottom), clockwise from top-left
def s16(v):
    v = int(v); return v - 65536 if v > 32767 else v
if sys.argv[1] == "plan":
    els = list(next(ET.fromstring(open(sys.argv[2]).read()).iter("Layout")).iter("Element"))
    masters, plan = {}, []
    rows = sorted({s16(e.get("PosY")) for e in els if ".Fixtures.Tornado" in e.get("Object", "") and e.get("FixtureID").count(".") == 1})
    assert len(rows) == 2, rows
    for i, e in enumerate(els, 1):
        if ".Fixtures.Tornado" not in e.get("Object", ""): continue
        fid = e.get("FixtureID"); p = fid.split(".")
        if len(p) == 2: masters[p[0]] = (s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width")), int(e.get("Height")))
    for i, e in enumerate(els, 1):
        if ".Fixtures.Tornado" not in e.get("Object", ""): continue
        fid = e.get("FixtureID"); p = fid.split(".")
        if len(p) != 4: continue
        mx, my, mw, mh = masters[p[0]]; head, led = int(p[2]), int(p[3])
        x0 = mx + (mw - RING) // 2
        y0 = (my - RING * head) if my == rows[0] else (my + mh + RING * (5 - head))   # lower row hangs below, upper row stacks above
        col, row = SPOT[led - 1]
        plan.append({"element": i, "fixture": fid, "x": x0 + col * CELL, "y": y0 + row * CELL, "w": CELL, "h": CELL})
    json.dump({"masters": masters, "sections": plan}, open(sys.argv[3], "w"))
    xs = [p["x"] for p in plan]; ys = [p["y"] for p in plan]
    print(len(masters), "masters,", len(plan), "sections; footprint x", min(xs), "..", max(xs) + CELL, "y", min(ys), "..", max(ys) + CELL)
    cells = {(p["x"], p["y"]) for p in plan}; print("distinct cells:", len(cells))
    others = [(s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width") or 0), int(e.get("Height") or 0)) for e in els if ".Fixtures.Tornado" not in e.get("Object", "")]
    box = (min(xs), min(ys), max(xs) + CELL - min(xs), max(ys) + CELL - min(ys))
    print("overlaps with non-Tornado elements:", sum(1 for o in others if o[0] < box[0] + box[2] and box[0] < o[0] + o[2] and o[1] < box[1] + box[3] and box[1] < o[1] + o[3]))
    if len(sys.argv) > 4:
        from PIL import Image, ImageDraw
        sc = 2.4; x_min, x_max, y_min, y_max = min(xs) - 40, max(xs) + 50, min(ys) - 30, max(ys) + 40
        im = Image.new("RGB", (int((x_max - x_min) * sc), int((y_max - y_min) * sc)), (20, 20, 24)); d = ImageDraw.Draw(im)
        def rect(x, y, w, h, col, label=""):
            a, b = (x - x_min) * sc, (y_max - y - h) * sc
            d.rectangle([a, b, a + w * sc - 1, b + h * sc - 1], outline=col)
            if label: d.text((a + 4, b + 4), label, fill=col)
        for f, (mx, my, mw, mh) in masters.items(): rect(mx, my, mw, mh, (90, 200, 255), f)
        for p in plan: rect(p["x"], p["y"], CELL, CELL, (255, 190, 60))
        im.save(sys.argv[4])
else:
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))
    from mcp_call import call
    G = "tornado-rings-layout"
    plan = json.load(open(sys.argv[2]))["sections"]
    if len(sys.argv) > 3: plan = [p for p in plan if p["fixture"].startswith(plan[0]["fixture"].split(".")[0] + ".")]
    def send(cmds, close=False):
        for i in range(0, len(cmds), 200):
            last = close and i + 200 >= len(cmds)
            ok, r = call("ma3_commands", {"commands": cmds[i:i + 200], "undo_group": G, **({"close_undo": True} if last else {})})
            bad = [(x["command"], x["result"]) for x in r.get("results", []) if x["result"] != "OK"] if ok else [r]
            if bad or not ok or r["sent"] != r["total"]: print("STOPPED:", bad[:3]); sys.exit(1)
    lo, hi = min(p["element"] for p in plan), max(p["element"] for p in plan)
    send([f'Set Layout 1.{lo} Thru {hi} Property "Width" {CELL}', f'Set Layout 1.{lo} Thru {hi} Property "Height" {CELL}',
          f'Set Layout 1.{lo} Thru {hi} Property "VisibilityObjectName" "Hidden"', f'Set Layout 1.{lo} Thru {hi} Property "VisibilityBar" "Hidden"'])
    cmds = []
    for p in plan: cmds += [f'Set Layout 1.{p["element"]} Property "PosX" {p["x"]}', f'Set Layout 1.{p["element"]} Property "PosY" {p["y"]}']
    send(cmds, close=len(sys.argv) <= 3)
    wrong, off = [], lo - 1; got = {}
    while off < hi:
        ok, r = call("ma3_children", {"address": "Layout 1", "offset": off, "limit": 200, "fields": ["OBJECT", "POSX", "POSY", "WIDTH", "HEIGHT", "VISIBILITYOBJECTNAME", "VISIBILITYBAR"]})
        for c in r["children"]: got[c["index"]] = c["properties"]
        off += 200
    def s(v): return v - 65536 if v > 32767 else v
    for p in plan:
        q = got.get(p["element"], {})
        if (q.get("OBJECT"), s(q.get("POSX", 0)), s(q.get("POSY", 0)), q.get("WIDTH"), q.get("HEIGHT"), q.get("VISIBILITYOBJECTNAME"), q.get("VISIBILITYBAR")) != ("Fixture " + p["fixture"], p["x"], p["y"], CELL, CELL, False, False):
            wrong.append((p["element"], q))
    print(f"placed {len(plan)} sections ({len(cmds) + 4} commands); mismatches: {len(wrong)} {wrong[:2]}")
