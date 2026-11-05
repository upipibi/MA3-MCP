"""Second pass on the Q40 block: default 50 x 50 tiles (Aaron: "those are small ... default size").

Three rows of master-over-2x2 at 50 need 450 of height; the slot has 330. So each master moves to
the LEFT of its 2 x 2, centred on its height: a panel is 150 wide x 100 tall, three rows are 300.
Rows and left-right order still come from today's patch positions. The box label moves to the left
so it does not sit on the middle panel of the top row.
usage: q40_default_size.py plan <fixtures.json> <plan-v1.json> <plan-v2.json> [preview.png <layout.xml>] | run <plan-v2.json>"""
import json, os, sys
BOX = {"x": 180, "y": -270, "w": 780, "h": 330}
CELL, LABEL, GAP, PX_PER_M = 50, 14, 6, 43.5
def s16(v):
    v = int(v); return v - 65536 if v > 32767 else v
if sys.argv[1] == "plan":
    fx = json.load(open(sys.argv[2])); v1 = json.load(open(sys.argv[3]))
    index = {p["fixture"]: p["element"] for p in v1["elements"]}
    lines = sorted({round(f["y"], 1) for f in fx}, reverse=True); cx0 = BOX["x"] + BOX["w"] // 2; plan = []
    for row, ly in enumerate(lines):
        top = BOX["y"] + BOX["h"] - LABEL - row * (2 * CELL + GAP)
        for f in sorted((f for f in fx if round(f["y"], 1) == ly), key=lambda f: f["x"]):
            x0 = cx0 + round(PX_PER_M * f["x"]) - (3 * CELL) // 2; fid = str(f["fid"])
            plan.append({"element": index[fid], "fixture": fid, "x": x0, "y": top - CELL - CELL // 2, "w": CELL, "h": CELL})
            for inst, (cx, cy) in zip((1, 2, 3, 4), ((1, 1), (2, 1), (1, 2), (2, 2))):
                plan.append({"element": index[f"{fid}.{inst}"], "fixture": f"{fid}.{inst}", "x": x0 + cx * CELL, "y": top - cy * CELL, "w": CELL, "h": CELL})
    json.dump({"box": v1["box"], "elements": plan}, open(sys.argv[4], "w"), indent=0)
    def hit(a, b): return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]
    m = [(p["x"], p["y"], p["w"], p["h"]) for p in plan]
    print(len(plan), "elements | inside the box:", all(BOX["x"] <= a[0] and a[0] + a[2] <= BOX["x"] + BOX["w"] and BOX["y"] <= a[1] and a[1] + a[3] <= BOX["y"] + BOX["h"] for a in m),
          "| overlaps:", sum(1 for i in range(len(m)) for j in range(i) if hit(m[i], m[j])), "| x", min(a[0] for a in m), "..", max(a[0] + a[2] for a in m), "y", min(a[1] for a in m), "..", max(a[1] + a[3] for a in m))
    if len(sys.argv) > 6:
        import xml.etree.ElementTree as ET
        from PIL import Image, ImageDraw
        mine = {p["element"] for p in plan} | {v1["box"]["element"]}
        els = list(next(ET.fromstring(open(sys.argv[6]).read()).iter("Layout")).iter("Element"))
        sc = 1.0; x0, x1, y0, y1 = 150, 990, -560, 560
        im = Image.new("RGB", (int((x1 - x0) * sc), int((y1 - y0) * sc)), (20, 20, 24)); d = ImageDraw.Draw(im)
        def rect(x, y, w, h, col, label=""):
            if w < 2 or h < 2: return
            a, b = (x - x0) * sc, (y1 - y - h) * sc; d.rectangle([a, b, a + w * sc - 1, b + h * sc - 1], outline=col)
            if label: d.text((a + 3, b + 2), str(label), fill=col)
        for i, e in enumerate(els, 1):
            if i not in mine: rect(s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width") or 0), int(e.get("Height") or 0), (70, 70, 90), e.get("CustomTextText") or "")
        rect(BOX["x"], BOX["y"], BOX["w"], BOX["h"], (150, 120, 60), "Q40")
        for p in plan: rect(p["x"], p["y"], p["w"], p["h"], (255, 190, 60) if "." in p["fixture"] else (120, 220, 255), p["fixture"] if "." not in p["fixture"] else p["fixture"].split(".")[1])
        im.save(sys.argv[5])
else:
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))
    from mcp_call import call
    data = json.load(open(sys.argv[2])); plan, box = data["elements"], data["box"]; G = "q40-default-size"
    lo, hi = min(p["element"] for p in plan), max(p["element"] for p in plan)
    def kids():
        ok, r = call("ma3_children", {"address": "Layout 1", "offset": lo - 1, "limit": hi - lo + 2, "fields": ["OBJECT", "POSX", "POSY", "WIDTH", "HEIGHT", "CUSTOMTEXTTEXT", "CUSTOMTEXTALIGNMENTH"]})
        return {c["index"]: c["properties"] for c in r["children"]}
    got = kids()
    if any(got.get(p["element"], {}).get("OBJECT") != "Fixture " + p["fixture"] for p in plan) or got.get(box["element"], {}).get("CUSTOMTEXTTEXT") != "Q40":
        sys.exit("the Q40 elements are not where the plan expects them: re-plan")
    cmds = [f'Set Layout 1.{lo} Thru {hi} Property "Width" {CELL}', f'Set Layout 1.{lo} Thru {hi} Property "Height" {CELL}']
    for p in plan: cmds += [f'Set Layout 1.{p["element"]} Property "PosX" {p["x"]}', f'Set Layout 1.{p["element"]} Property "PosY" {p["y"]}']
    cmds += [f'Set Layout 1.{box["element"]} Property "CustomTextAlignmentH" "Left"']
    ok, r = call("ma3_commands", {"commands": cmds, "undo_group": G, "close_undo": True})
    bad = [(x["command"], x["result"]) for x in r.get("results", []) if x["result"] != "OK"] if ok else [r]
    if bad or not ok or r["sent"] != r["total"]: print("STOPPED:", bad[:3]); sys.exit(1)
    def s(v): return v - 65536 if v > 32767 else v
    got = kids()
    wrong = [p["element"] for p in plan if (s(got[p["element"]]["POSX"]), s(got[p["element"]]["POSY"]), got[p["element"]]["WIDTH"], got[p["element"]]["HEIGHT"]) != (p["x"], p["y"], CELL, CELL)]
    print(f"{len(cmds)} commands; {len(plan)} elements resized and placed; mismatches: {len(wrong)} {wrong[:3]} | label alignment: {got[box['element']].get('CUSTOMTEXTALIGNMENTH')}")
