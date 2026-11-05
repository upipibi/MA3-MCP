"""Build the Portman element plan for today's Layout 1 from the old show's Layout 1.

Old show (Christmas 2025): fixtures 1401-1406, two columns x three rows, each Portman drawn as two
7-cell hexes with its master tile above. Today: 1201-1206; per the Capture plot the left tower is
1201, 1202, 1203 top to bottom and the right tower 1204, 1205, 1206. Layout Y points up.
usage: plan_portmans.py <old-layout.xml> <current-layout.xml> <out.json> <preview.png>"""
import json, re, sys
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw
old_xml, cur_xml, out_json, out_png = sys.argv[1:5]
SHIFT_X, SHIFT_Y = 250, 0
MAP = {"1405": "1201", "1403": "1202", "1401": "1203", "1406": "1204", "1404": "1205", "1402": "1206"}
def s16(v):
    v = int(v); return v - 65536 if v > 32767 else v
lay = next(ET.fromstring(open(old_xml).read()).iter("Layout"))
plan = []
for e in lay.iter("Element"):
    if ".Fixtures.Portmans" not in e.get("Object", ""): continue
    fid = e.get("FixtureID"); base, _, inst = fid.partition(".")
    new = MAP[base] + ("." + inst if inst else "")
    plan.append({"fixture": new, "old": fid, "x": s16(e.get("PosX")) + SHIFT_X, "y": s16(e.get("PosY")) + SHIFT_Y,
                 "w": int(e.get("Width")), "h": int(e.get("Height"))})
plan.sort(key=lambda p: (int(p["fixture"].split(".")[0]), int(p["fixture"].split(".")[1]) if "." in p["fixture"] else 0))
box = {"text": "Portmans", "x": -950 + SHIFT_X, "y": -70 + SHIFT_Y, "w": 750, "h": 610}
cur = []
for e in next(ET.fromstring(open(cur_xml).read()).iter("Layout")).iter("Element"):
    cur.append((s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width") or 0), int(e.get("Height") or 0),
                e.get("CustomTextText") or "", e.get("FixtureID") or ""))
def hit(a, b): return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]
clashes = [c for c in cur if hit((box["x"], box["y"], box["w"], box["h"]), c)]
json.dump({"shift": [SHIFT_X, SHIFT_Y], "map_old_to_new": MAP, "box": box, "elements": plan}, open(out_json, "w"), indent=1)
print(len(plan), "elements; box", box, "; clashes with existing elements:", len(clashes), clashes[:5])
xmin, xmax, ymin, ymax = -1150, 1050, -600, 620
sc = 1600 / (xmax - xmin); W, H = 1600, int((ymax - ymin) * sc)
im = Image.new("RGB", (W, H), (20, 20, 24)); d = ImageDraw.Draw(im)
def rect(x, y, w, h, col, label=""):
    x0, y0 = (x - xmin) * sc, (ymax - y - h) * sc
    d.rectangle([x0, y0, x0 + w * sc, y0 + h * sc], outline=col)
    if label: d.text((x0 + 3, y0 + 2), label, fill=col)
for x, y, w, h, txt, fid in cur:
    rect(x, y, w, h, (95, 95, 115), txt or (fid if "." not in fid and w >= 40 else ""))
rect(box["x"], box["y"], box["w"], box["h"], (150, 120, 60), "Portmans (new)")
for p in plan:
    rect(p["x"], p["y"], p["w"], p["h"], (255, 190, 60), p["fixture"] if "." not in p["fixture"] else p["fixture"].split(".")[1])
im.save(out_png)
