"""Build the Q40 block in Layout 1 (2026-11-05).

Look taken from the old show (Christmas 2025, Layout 1): each panel is a master tile centred over a
2 x 2 of its four instances (Instance2 top-left, 3 top-right, 4 bottom-left, 5 bottom-right), in a
labelled box. The old arrangement (rows of 2 / 3 / 6) was last year's rig; today's eleven panels
hang in three lines (3 / 4 / 4), so rows and left-right spacing come from today's patch positions:
upstage line on top, like the rest of the layout (key light at the bottom), x proportional to POSX.
Sized to the one free slot of the default layout area: x 180..960, y -270..60.
usage: q40.py plan <fixtures.json> <layout.xml> <plan.json> [preview.png] | q40.py run <plan.json>"""
import json, os, sys
import xml.etree.ElementTree as ET
BOX = {"x": 180, "y": -270, "w": 780, "h": 330, "text": "Q40"}
CELL, GAP, TOP_MARGIN, PX_PER_M = 30, 10, 25, 48
def s16(v):
    v = int(v); return v - 65536 if v > 32767 else v
if sys.argv[1] == "plan":
    fx = json.load(open(sys.argv[2]))                      # [{fid, x, y, z}]
    lines = sorted({round(f["y"], 1) for f in fx}, reverse=True)       # upstage (largest Y) first
    cx0 = BOX["x"] + BOX["w"] // 2; plan = []
    for row, ly in enumerate(lines):
        top = BOX["y"] + BOX["h"] - TOP_MARGIN - row * (3 * CELL + GAP)
        for f in sorted((f for f in fx if round(f["y"], 1) == ly), key=lambda f: f["x"]):
            cx = cx0 + round(PX_PER_M * f["x"]); fid = str(f["fid"])
            plan.append({"fixture": fid, "x": cx - CELL // 2, "y": top - CELL, "w": CELL, "h": CELL, "row": row})
            for inst, (dx, dy) in zip((1, 2, 3, 4), ((-CELL, 2 * CELL), (0, 2 * CELL), (-CELL, 3 * CELL), (0, 3 * CELL))):
                plan.append({"fixture": f"{fid}.{inst}", "x": cx + dx, "y": top - dy, "w": CELL, "h": CELL, "row": row})
    els = list(next(ET.fromstring(open(sys.argv[3]).read()).iter("Layout")).iter("Element"))
    first = len(els) + 1
    for i, p in enumerate(plan): p["element"] = first + i
    box = dict(BOX, element=first + len(plan))
    json.dump({"box": box, "elements": plan, "rows": lines}, open(sys.argv[4], "w"), indent=0)
    def hit(a, b): return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]
    mine = [(p["x"], p["y"], p["w"], p["h"]) for p in plan]
    others = [(e.get("FixtureID") or e.get("CustomTextText"), s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width") or 0), int(e.get("Height") or 0)) for e in els]
    inside = all(BOX["x"] <= m[0] and m[0] + m[2] <= BOX["x"] + BOX["w"] and BOX["y"] <= m[1] and m[1] + m[3] <= BOX["y"] + BOX["h"] for m in mine)
    print(len(plan), "elements from index", first, "| rows (upstage first):", [(ly, [f["fid"] for f in sorted((f for f in fx if round(f["y"], 1) == ly), key=lambda f: f["x"])]) for ly in lines])
    print("all inside the box:", inside, "| cells overlapping each other:", sum(1 for i in range(len(mine)) for j in range(i) if hit(mine[i], mine[j])),
          "| existing elements under the box:", [o[0] for o in others if hit(o[1:], (BOX["x"], BOX["y"], BOX["w"], BOX["h"])) and o[3] > 1][:6])
    if len(sys.argv) > 5:
        from PIL import Image, ImageDraw
        sc = 0.8; x0, x1, y0, y1 = -1000, 1000, -580, 580
        im = Image.new("RGB", (int((x1 - x0) * sc), int((y1 - y0) * sc)), (20, 20, 24)); d = ImageDraw.Draw(im)
        def rect(x, y, w, h, col, label="", width=1):
            if w * sc < 2 or h * sc < 2: return
            a, b = (x - x0) * sc, (y1 - y - h) * sc; d.rectangle([a, b, a + w * sc - 1, b + h * sc - 1], outline=col, width=width)
            if label: d.text((a + 3, b + 2), str(label), fill=col)
        rect(-960, -540, 1920, 1080, (200, 60, 60), "", 2)
        for name, x, y, w, h in others: rect(x, y, w, h, (70, 70, 90), name if w > 150 else "")
        rect(BOX["x"], BOX["y"], BOX["w"], BOX["h"], (150, 120, 60), "Q40 (new)")
        for p in plan: rect(p["x"], p["y"], p["w"], p["h"], (255, 190, 60) if "." in p["fixture"] else (120, 220, 255), "" if "." in p["fixture"] else p["fixture"])
        im.save(sys.argv[5])
else:
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))
    from mcp_call import call
    data = json.load(open(sys.argv[2])); plan, box = data["elements"], data["box"]; G = "q40-layout"
    def send(cmds, close=False):
        for i in range(0, len(cmds), 200):
            ok, r = call("ma3_commands", {"commands": cmds[i:i + 200], "undo_group": G, **({"close_undo": True} if close and i + 200 >= len(cmds) else {})})
            bad = [(x["command"], x["result"]) for x in r.get("results", []) if x["result"] != "OK"] if ok else [r]
            if bad or not ok or r["sent"] != r["total"]: print("STOPPED:", bad[:3]); sys.exit(1)
    def kids(lo, n):
        ok, r = call("ma3_children", {"address": "Layout 1", "offset": lo - 1, "limit": n, "fields": ["OBJECT", "POSX", "POSY", "WIDTH", "HEIGHT", "CUSTOMTEXTTEXT", "VISIBILITYOBJECTNAME", "VISIBILITYBORDER"]})
        return {c["index"]: c["properties"] for c in r["children"]}
    ok, o = call("ma3_object", {"address": "Layout 1"})
    if o["child_count"] != plan[0]["element"] - 1: sys.exit(f"layout has {o['child_count']} elements, plan expects {plan[0]['element'] - 1}: re-plan")
    send([f'Assign Fixture {p["fixture"]} At Layout 1' for p in plan])
    lo, hi = plan[0]["element"], plan[-1]["element"]; got = kids(lo, len(plan))
    wrongobj = [p["element"] for p in plan if got.get(p["element"], {}).get("OBJECT") != "Fixture " + p["fixture"]]
    if wrongobj: sys.exit(f"elements did not land in plan order: {wrongobj[:5]}")
    cmds = [f'Set Layout 1.{lo} Thru {hi} Property "Width" {CELL}', f'Set Layout 1.{lo} Thru {hi} Property "Height" {CELL}']
    for p in plan: cmds += [f'Set Layout 1.{p["element"]} Property "PosX" {p["x"]}', f'Set Layout 1.{p["element"]} Property "PosY" {p["y"]}']
    b = box["element"]
    cmds += [f"Store Layout 1.{b}", f'Set Layout 1.{b} Property "PosX" {box["x"]}', f'Set Layout 1.{b} Property "PosY" {box["y"]}', f'Set Layout 1.{b} Property "Width" {box["w"]}', f'Set Layout 1.{b} Property "Height" {box["h"]}',
             f'Set Layout 1.{b} Property "CustomTextText" "{box["text"]}"', f'Set Layout 1.{b} Property "CustomTextAlignmentV" "Top"', f'Set Layout 1.{b} Property "VisibilityObjectName" "Hidden"',
             f'Set Layout 1.{b} Property "PaddingLeft" 2', f'Set Layout 1.{b} Property "PaddingRight" 2', f'Set Layout 1.{b} Property "PaddingTop" 2', f'Set Layout 1.{b} Property "PaddingBottom" 2']
    send(cmds, close=True)
    def s(v): return v - 65536 if v > 32767 else v
    got = kids(lo, len(plan) + 1)
    wrong = [p["element"] for p in plan if (got[p["element"]]["OBJECT"], s(got[p["element"]]["POSX"]), s(got[p["element"]]["POSY"]), got[p["element"]]["WIDTH"], got[p["element"]]["HEIGHT"]) != ("Fixture " + p["fixture"], p["x"], p["y"], CELL, CELL)]
    q = got[b]; boxok = (s(q["POSX"]), s(q["POSY"]), q["WIDTH"], q["HEIGHT"], q.get("CUSTOMTEXTTEXT"), q["VISIBILITYOBJECTNAME"], q["VISIBILITYBORDER"]) == (box["x"], box["y"], box["w"], box["h"], box["text"], False, True)
    print(f"{len(plan)} elements added and placed; mismatches: {len(wrong)} {wrong[:3]} | box ok: {boxok}")
