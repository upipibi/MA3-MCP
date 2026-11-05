"""Scale the Portman elements of Layout 1 so the block fits the default layout area (2026-11-05).

The default area is the layout's 1920 x 1080 canvas centred on the origin (x -960..960, y -540..540;
Aaron's Infini Bars and Tornado boxes are fitted to its top and left edges). He re-arranged the
Portmans (each fixture: master, then its two hexes stacked below) and the block ran below y -540.
Every Portman element is scaled by SCALE about the block's top-left corner: positions and sizes.
usage: resize.py plan <layout.xml> <plan.json> [preview.png] | resize.py run <plan.json>"""
import json, os, sys
import xml.etree.ElementTree as ET
SCALE = 0.9
def s16(v):
    v = int(v); return v - 65536 if v > 32767 else v
if sys.argv[1] == "plan":
    els = list(next(ET.fromstring(open(sys.argv[2]).read()).iter("Layout")).iter("Element"))
    P = [(i, e.get("FixtureID"), s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width")), int(e.get("Height"))) for i, e in enumerate(els, 1) if ".Fixtures.Portmans" in e.get("Object", "")]
    ax, ay = min(p[2] for p in P), max(p[3] + p[5] for p in P)             # top-left corner of the block (Y points up)
    plan = []
    for i, fid, x, y, w, h in P:
        nw, nh = round(w * SCALE), round(h * SCALE)
        top = ay + round((y + h - ay) * SCALE)                              # scale the top edge, then hang the box from it
        plan.append({"element": i, "fixture": fid, "x": ax + round((x - ax) * SCALE), "y": top - nh, "w": nw, "h": nh, "old": [x, y, w, h]})
    json.dump({"anchor": [ax, ay], "scale": SCALE, "elements": plan}, open(sys.argv[3], "w"))
    ob = (min(p[2] for p in P), min(p[3] for p in P), max(p[2] + p[4] for p in P), max(p[3] + p[5] for p in P))
    nb = (min(p["x"] for p in plan), min(p["y"] for p in plan), max(p["x"] + p["w"] for p in plan), max(p["y"] + p["h"] for p in plan))
    print(len(plan), "elements | block before x", ob[0], "..", ob[2], "y", ob[1], "..", ob[3], "| after x", nb[0], "..", nb[2], "y", nb[1], "..", nb[3], "| inside the default area:", nb[0] >= -960 and nb[2] <= 960 and nb[1] >= -540 and nb[3] <= 540)
    boxes = [(p["x"], p["y"], p["w"], p["h"]) for p in plan]
    def hit(a, b): return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]
    print("portman cells overlapping each other:", sum(1 for i in range(len(boxes)) for j in range(i) if hit(boxes[i], boxes[j])), "(before:", sum(1 for i in range(len(P)) for j in range(i) if hit(P[i][2:], P[j][2:])), ")")
    mine = {p["element"] for p in plan}
    others = [(i, e.get("FixtureID") or e.get("CustomTextText"), s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width") or 0), int(e.get("Height") or 0)) for i, e in enumerate(els, 1) if i not in mine]
    print("overlaps with other elements after:", [o[:2] for o in others if any(hit(o[2:], b) for b in boxes)][:6], "| before:", [o[:2] for o in others if any(hit(o[2:], p[2:]) for p in P)][:6])
    if len(sys.argv) > 4:
        from PIL import Image, ImageDraw
        sc = 0.75; x0, x1, y0, y1 = -1000, 1000, -580, 580
        im = Image.new("RGB", (int((x1 - x0) * sc), int((y1 - y0) * sc)), (20, 20, 24)); d = ImageDraw.Draw(im)
        def rect(x, y, w, h, col, label="", width=1):
            if w * sc < 2 or h * sc < 2: return
            a, b = (x - x0) * sc, (y1 - y - h) * sc; d.rectangle([a, b, a + w * sc - 1, b + h * sc - 1], outline=col, width=width)
            if label: d.text((a + 3, b + 2), label, fill=col)
        rect(-960, -540, 1920, 1080, (200, 60, 60), "default layout area 1920 x 1080", 2)
        for i, name, x, y, w, h in others: rect(x, y, w, h, (70, 70, 90), name if w > 200 else "")
        for i, fid, x, y, w, h in P: rect(x, y, w, h, (90, 70, 40))
        for p in plan: rect(p["x"], p["y"], p["w"], p["h"], (255, 190, 60), p["fixture"] if "." not in p["fixture"] else "")
        im.save(sys.argv[4])
else:
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))
    from mcp_call import call
    plan = json.load(open(sys.argv[2]))["elements"]; G = "portman-resize"
    cmds = []
    for p in plan: cmds += [f'Set Layout 1.{p["element"]} Property "Width" {p["w"]}', f'Set Layout 1.{p["element"]} Property "Height" {p["h"]}', f'Set Layout 1.{p["element"]} Property "PosX" {p["x"]}', f'Set Layout 1.{p["element"]} Property "PosY" {p["y"]}']
    for i in range(0, len(cmds), 200):
        ok, r = call("ma3_commands", {"commands": cmds[i:i + 200], "undo_group": G, **({"close_undo": True} if i + 200 >= len(cmds) else {})})
        bad = [(x["command"], x["result"]) for x in r.get("results", []) if x["result"] != "OK"] if ok else [r]
        if bad or not ok or r["sent"] != r["total"]: print("STOPPED:", bad[:3]); sys.exit(1)
    lo, hi = min(p["element"] for p in plan), max(p["element"] for p in plan)
    ok, r = call("ma3_children", {"address": "Layout 1", "offset": lo - 1, "limit": hi - lo + 1, "fields": ["OBJECT", "POSX", "POSY", "WIDTH", "HEIGHT"]})
    got = {c["index"]: c["properties"] for c in r["children"]}
    def s(v): return v - 65536 if v > 32767 else v
    wrong = [p["element"] for p in plan if (got[p["element"]]["OBJECT"], s(got[p["element"]]["POSX"]), s(got[p["element"]]["POSY"]), got[p["element"]]["WIDTH"], got[p["element"]]["HEIGHT"]) != ("Fixture " + p["fixture"], p["x"], p["y"], p["w"], p["h"])]
    print(f"{len(cmds)} commands; {len(plan)} elements resized; mismatches: {len(wrong)} {wrong[:3]}")
