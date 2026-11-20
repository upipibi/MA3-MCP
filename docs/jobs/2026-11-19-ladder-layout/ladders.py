"""Draw the ladder LEDs (650 pixels on the platform) in Layout 1 (2026-11-19).

Aaron: "Similar to how the ring LEDs are shown in the layout, I need all the 'ladder' LEDs, which are
really attached to the legs of a platform and the platform part of the platform, laid out in the
layout viewer. We are tight on space ... I'm thinking dimmers move to make space under the
infinibars and tornado?"

The shape comes from the groups he built the same evening (selection grids, read fresh):
701-706 = one leg each, 709 `Curve` = 100 in a line, 710 `Platform Top` = two lines of 89 lying on the
same grid cells. Everything is drawn as a front view in the strip under `Infini Bars` and `Tornado`
(x -960..-120, y -540..-360): the two top lines, six legs hanging under them, the curve along the
bottom. What his groups do not place is parked, not guessed into the shape: ladder 11 as a flat
2 x 25 strip, and the 11 LEDs each top line skips as a small U under the place where it skips.
The 14 dimmer tiles move to one row in the empty band of the `Key` box, his left-to-right order kept.

usage: ladders.py plan <groups.json> <fixtures.json> <layout.xml> <plan.json> [preview.png]
       ladders.py run <plan.json> [after.xml]"""
import json, os, sys
import xml.etree.ElementTree as ET

BOX = {"x": -960, "y": -540, "w": 840, "h": 180, "text": "Ladder LEDs"}
C = 9                       # top lines, legs, parked cells
CURVE_C, CURVE_SAG = 8, 24  # the curve: 100 cells of 8, ends 24 higher than the middle
TOP_X0 = -940               # grid x 0 of group 710; 89 cells of 9 end at -139
TOP_REAR_Y, TOP_FRONT_Y = -395, -404
LEG_TOP = -406              # legs hang from here: 10 rows of 9 down to -496
LEG_COLS, LEG_ROWS = 5, 10
LEG_X = {"Front Left": -940, "Rear Left": -890, "Center Left": -587, "Center Right": -537, "Right Rear": -234, "Right Front": -184}
PARK11 = {"x": -476, "y": -451, "cols": 25}                                  # ladder 11: two rows of 25
DIM_ROW = {"x": 210, "y": -470, "order_rows": True}                          # dimmer tiles, 50 x 50, one row
DIM_BOX = {"x": 205, "y": -475, "w": 710, "h": 60}

def s16(v):
    v = int(v or 0); return v - 65536 if v > 32767 else v

def snake(k, cols):                      # LED k of a string folded into rows of `cols`, first LED top-left
    r, c = divmod(k, cols)
    return (c if r % 2 == 0 else cols - 1 - c), r

def build(groups, fixtures, layout_xml):
    sf2fid, ladders = {}, {}             # ladders: name -> [fid of LED 1..50]
    def walk(n):
        kids = n.get("children") or []
        if kids and not any(k.get("children") for k in kids) and n["name"].startswith("Ladder"):
            ladders[n["name"]] = [k["fid"] for k in kids]
        for k in kids: sf2fid[k["sf_index"]] = k["fid"]; walk(k)
    for r in fixtures["rows"]: walk(r)
    G = {g["name"].strip(): g for g in groups["rows"]}
    cells, used = [], set()
    def put(fid, x, y, size, part):
        assert fid not in used, fid
        used.add(fid); cells.append({"fixture": str(fid), "x": x, "y": y, "w": size, "h": size, "part": part})
    # legs: his groups 701-706, LED order = his grid x
    for name, x0 in LEG_X.items():
        m = sorted(G[name]["member_details"], key=lambda a: a["x"]); assert len(m) == 50, (name, len(m))
        for k, a in enumerate(m):
            c, r = snake(k, LEG_COLS); put(sf2fid[a["sf_index"]], x0 + C * c, LEG_TOP - C * (r + 1), C, name)
    # platform top: group 710, two strings pairs on the same grid cells; the lower sub-fixture numbers = rear line
    top = G["Platform Top"]["member_details"]; split = sorted(a["sf_index"] for a in top)[len(top) // 2]
    for a in top:
        rear = a["sf_index"] < split
        put(sf2fid[a["sf_index"]], TOP_X0 + C * a["x"], TOP_REAR_Y if rear else TOP_FRONT_Y, C, "Top rear" if rear else "Top front")
    # the LEDs each top line skips: a U under the skip (front line directly under it, rear line three columns right)
    topfids = {sf2fid[a["sf_index"]]: a["x"] for a in top}
    for lad, col_shift, part in (("Ladder13", 3, "Skipped rear"), ("Ladder 8", 0, "Skipped front")):
        leds = ladders[lad]; skipped = [f for f in leds if f not in topfids]; assert len(skipped) == 11, (lad, len(skipped))
        before = topfids[leds[leds.index(skipped[0]) - 1]]                  # grid x of the last LED before the skip
        for j, f in enumerate(skipped):
            col, row = (before + col_shift, j) if j < 6 else (before + col_shift - 1, 10 - j)
            put(f, TOP_X0 + C * col, LEG_TOP - C * (row + 1), C, part)
    # curve: group 709, a shallow arc
    cur = sorted(G["Curve"]["member_details"], key=lambda a: a["x"]); n = len(cur); assert n == 100
    for a in cur:
        t = (a["x"] - (n - 1) / 2) / ((n - 1) / 2)
        put(sf2fid[a["sf_index"]], TOP_X0 + CURVE_C * a["x"], BOX["y"] + 4 + round(CURVE_SAG * t * t), CURVE_C, "Curve")
    # ladder 11: not in any of his place groups
    for k, f in enumerate(ladders["Ladder 11"]):
        c, r = snake(k, PARK11["cols"]); put(f, PARK11["x"] + C * c, PARK11["y"] - C * r, C, "Ladder 11 (parked)")
    allfids = {f for v in ladders.values() for f in v}
    assert used == allfids and len(used) == 650, (len(used), len(allfids))
    # existing layout
    els = list(next(ET.fromstring(layout_xml).iter("Layout")).iter("Element"))
    first = len(els) + 1
    for i, c in enumerate(cells): c["element"] = first + i
    box = dict(BOX, element=first + len(cells))
    dims = [(i, e) for i, e in enumerate(els, 1) if ".Fixtures.Stage Dimmers." in e.get("Object", "")]
    dbox = [i for i, e in enumerate(els, 1) if e.get("Object", "").endswith("Groups.Dimmers")]
    assert len(dims) == 14 and len(dbox) == 1, (len(dims), dbox)
    order = sorted(dims, key=lambda p: (-s16(p[1].get("PosY")), s16(p[1].get("PosX"))))     # his upper row left to right, then the lower row
    tiles = [{"element": i, "fixture": e.get("FixtureID"), "x": DIM_ROW["x"] + 50 * n, "y": DIM_ROW["y"], "from": [s16(e.get("PosX")), s16(e.get("PosY"))]} for n, (i, e) in enumerate(order)]
    return {"count_before": len(els), "cells": cells, "box": box, "dimmer_tiles": tiles, "dimmer_box": dict(DIM_BOX, element=dbox[0])}, els

def hit(a, b): return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]

if sys.argv[1] == "plan":
    xml = open(sys.argv[4]).read()
    plan, els = build(json.load(open(sys.argv[2])), json.load(open(sys.argv[3])), xml)
    json.dump(plan, open(sys.argv[5], "w"), indent=0)
    cells = plan["cells"]; mine = [(c["x"], c["y"], c["w"], c["h"]) for c in cells]
    moved = {t["element"] for t in plan["dimmer_tiles"]} | {plan["dimmer_box"]["element"]}
    others = [(i, e.get("FixtureID") or e.get("CustomTextText") or "", s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width") or 0), int(e.get("Height") or 0)) for i, e in enumerate(els, 1)]
    stay = [o for o in others if o[0] not in moved]
    B = (BOX["x"], BOX["y"], BOX["w"], BOX["h"])
    parts = {}
    for c in cells: parts[c["part"]] = parts.get(c["part"], 0) + 1
    print(len(cells), "cells from element", cells[0]["element"], "| parts:", parts)
    print("all inside the box:", all(B[0] <= m[0] and m[0] + m[2] <= B[0] + B[2] and B[1] <= m[1] and m[1] + m[3] <= B[1] + B[3] for m in mine),
          "| cells overlapping each other:", sum(1 for i in range(len(mine)) for j in range(i) if hit(mine[i], mine[j])),
          "| elements that stay and sit under the new box:", [o[:2] for o in stay if o[4] > 1 and hit(o[2:], B)])
    row = [(t["x"], t["y"], 50, 50) for t in plan["dimmer_tiles"]]
    print("dimmer row x", row[0][0], "..", row[-1][0] + 50, "y", row[0][1], "..", row[0][1] + 50, "| order:", [t["fixture"] for t in plan["dimmer_tiles"]],
          "| tiles it would cover:", [o[:2] for o in stay if o[4] <= 60 and o[4] > 1 and any(hit(o[2:], r) for r in row)])
    if len(sys.argv) > 6:
        from PIL import Image, ImageDraw
        def draw(path, sc, x0, x1, y0, y1, names):
            im = Image.new("RGB", (int((x1 - x0) * sc), int((y1 - y0) * sc)), (20, 20, 24)); d = ImageDraw.Draw(im)
            def rect(x, y, w, h, col, label="", fill=None):
                if w * sc < 2 or h * sc < 2: return
                a, b = (x - x0) * sc, (y1 - y - h) * sc; d.rectangle([a, b, a + w * sc - 1, b + h * sc - 1], outline=col, fill=fill)
                if label: d.text((a + 3, b + 2), str(label), fill=col)
            for i, name, x, y, w, h in stay: rect(x, y, w, h, (70, 70, 90), name if w > 150 else "")
            rect(*B, (150, 120, 60), BOX["text"])
            col = {"Top rear": (255, 190, 60), "Top front": (255, 120, 60), "Curve": (120, 220, 255), "Ladder 11 (parked)": (150, 150, 150), "Skipped rear": (150, 150, 150), "Skipped front": (110, 110, 110)}
            for c in cells: rect(c["x"], c["y"], c["w"], c["h"], (20, 20, 24), fill=col.get(c["part"], (120, 230, 120)))
            if names:
                for name, x in LEG_X.items(): d.text(((x - x0) * sc, (y1 - LEG_TOP + 92) * sc), name.replace(" ", "\n"), fill=(230, 230, 230))
            db = plan["dimmer_box"]; rect(db["x"], db["y"], db["w"], db["h"], (150, 120, 60), "")
            for t in plan["dimmer_tiles"]: rect(t["x"], t["y"], 50, 50, (255, 255, 255), t["fixture"] if sc > 1 else "")
            im.save(path)
        draw(sys.argv[6], 0.8, -1000, 1000, -580, 580, False)
        draw(sys.argv[6].replace(".png", "-strip.png"), 2.0, -970, -110, -545, -350, False)
else:
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))
    from mcp_call import call
    plan = json.load(open(sys.argv[2])); cells, box, tiles, dbox = plan["cells"], plan["box"], plan["dimmer_tiles"], plan["dimmer_box"]
    G = "ladder-layout"
    def send(cmds, close=False):
        for i in range(0, len(cmds), 200):
            ok, r = call("ma3_commands", {"commands": cmds[i:i + 200], "undo_group": G, **({"close_undo": True} if close and i + 200 >= len(cmds) else {})})
            bad = [(x["command"], x["result"]) for x in r.get("results", []) if x["result"] != "OK"] if ok else [r]
            if bad or not ok or r["sent"] != r["total"]: print("STOPPED:", bad[:3]); sys.exit(1)
    FIELDS = ["OBJECT", "POSX", "POSY", "WIDTH", "HEIGHT", "CUSTOMTEXTTEXT", "CUSTOMTEXTALIGNMENTV", "VISIBILITYOBJECTNAME", "VISIBILITYBAR", "VISIBILITYBORDER"]
    def kids(lo, n):
        out, off = {}, lo - 1
        while off < lo - 1 + n:
            ok, r = call("ma3_children", {"address": "Layout 1", "offset": off, "limit": min(200, lo - 1 + n - off), "fields": FIELDS})
            for c in r["children"]: out[c["index"]] = c["properties"]
            off += 200
        return out
    def s(v): return v - 65536 if v > 32767 else v
    ok, o = call("ma3_object", {"address": "Layout 1"})
    if o["child_count"] != plan["count_before"]: sys.exit(f"layout has {o['child_count']} elements, plan expects {plan['count_before']}: re-plan")
    # the dimmer tiles must still be where the plan read them (he edits between jobs)
    lo_d, hi_d = min(t["element"] for t in tiles), max(t["element"] for t in tiles); got = kids(lo_d, hi_d - lo_d + 1)
    stale = [t["element"] for t in tiles if (got[t["element"]]["OBJECT"], s(got[t["element"]]["POSX"]), s(got[t["element"]]["POSY"])) != ("Fixture " + t["fixture"], t["from"][0], t["from"][1])]
    if stale: sys.exit(f"dimmer tiles changed since the plan: {stale}: re-plan")
    send([f'Assign Fixture {c["fixture"]} At Layout 1' for c in cells])
    lo, hi = cells[0]["element"], cells[-1]["element"]; got = kids(lo, len(cells))
    wrongobj = [c["element"] for c in cells if got.get(c["element"], {}).get("OBJECT") != "Fixture " + c["fixture"]]
    if wrongobj: sys.exit(f"elements did not land in plan order: {wrongobj[:5]} (undo group {G} is still open)")
    cmds = [f'Set Layout 1.{lo} Thru {hi} Property "VisibilityObjectName" "Hidden"', f'Set Layout 1.{lo} Thru {hi} Property "VisibilityBar" "Hidden"']
    runs = []                                                # consecutive elements of one size share a ranged command
    for c in cells:
        if runs and runs[-1][2] == c["w"] and runs[-1][1] == c["element"] - 1: runs[-1][1] = c["element"]
        else: runs.append([c["element"], c["element"], c["w"]])
    for a, b, w in runs: cmds += [f'Set Layout 1.{a} Thru {b} Property "Width" {w}', f'Set Layout 1.{a} Thru {b} Property "Height" {w}']
    for c in cells: cmds += [f'Set Layout 1.{c["element"]} Property "PosX" {c["x"]}', f'Set Layout 1.{c["element"]} Property "PosY" {c["y"]}']
    b = box["element"]
    cmds += [f"Store Layout 1.{b}", f'Set Layout 1.{b} Property "PosX" {box["x"]}', f'Set Layout 1.{b} Property "PosY" {box["y"]}', f'Set Layout 1.{b} Property "Width" {box["w"]}', f'Set Layout 1.{b} Property "Height" {box["h"]}',
             f'Set Layout 1.{b} Property "CustomTextText" "{box["text"]}"', f'Set Layout 1.{b} Property "CustomTextAlignmentV" "Top"', f'Set Layout 1.{b} Property "CustomTextAlignmentH" "Left"', f'Set Layout 1.{b} Property "VisibilityObjectName" "Hidden"',
             f'Set Layout 1.{b} Property "PaddingLeft" 2', f'Set Layout 1.{b} Property "PaddingRight" 2', f'Set Layout 1.{b} Property "PaddingTop" 2', f'Set Layout 1.{b} Property "PaddingBottom" 2']
    for t in tiles: cmds += [f'Set Layout 1.{t["element"]} Property "PosX" {t["x"]}', f'Set Layout 1.{t["element"]} Property "PosY" {t["y"]}']
    d = dbox["element"]
    cmds += [f'Set Layout 1.{d} Property "PosX" {dbox["x"]}', f'Set Layout 1.{d} Property "PosY" {dbox["y"]}', f'Set Layout 1.{d} Property "Width" {dbox["w"]}', f'Set Layout 1.{d} Property "Height" {dbox["h"]}']
    send(cmds)
    # the label of the dimmer box no longer fits inside it: put it above the box. If the console refuses the value, the label stays where it was.
    ok, r = call("ma3_commands", {"commands": [f'Set Layout 1.{d} Property "CustomTextAlignmentV" "Above"'], "undo_group": G, "close_undo": True})
    print("dimmer label above the box:", [x["result"] for x in r.get("results", [])] if ok else r)
    got = kids(lo, len(cells) + 1)
    wrong = [c["element"] for c in cells if (got[c["element"]]["OBJECT"], s(got[c["element"]]["POSX"]), s(got[c["element"]]["POSY"]), got[c["element"]]["WIDTH"], got[c["element"]]["HEIGHT"], got[c["element"]]["VISIBILITYOBJECTNAME"], got[c["element"]]["VISIBILITYBAR"]) != ("Fixture " + c["fixture"], c["x"], c["y"], c["w"], c["h"], False, False)]
    q = got[b]; boxok = (s(q["POSX"]), s(q["POSY"]), q["WIDTH"], q["HEIGHT"], q.get("CUSTOMTEXTTEXT"), q["VISIBILITYBORDER"]) == (box["x"], box["y"], box["w"], box["h"], box["text"], True)
    got = kids(min(d, lo_d), max(d, hi_d) - min(d, lo_d) + 1)
    twrong = [t["element"] for t in tiles if (s(got[t["element"]]["POSX"]), s(got[t["element"]]["POSY"]), got[t["element"]]["WIDTH"]) != (t["x"], t["y"], 50)]
    q = got[d]; dok = (s(q["POSX"]), s(q["POSY"]), q["WIDTH"], q["HEIGHT"]) == (dbox["x"], dbox["y"], dbox["w"], dbox["h"])
    print(f"{len(cells)} cells added and placed ({len(cmds) + len(cells) + 1} commands); mismatches: {len(wrong)} {wrong[:3]} | box ok: {boxok} | dimmer tiles wrong: {twrong} | dimmer box ok: {dok}, label {q.get('CUSTOMTEXTALIGNMENTV')}")
    if len(sys.argv) > 3:
        ok, r = call("ma3_export", {"address": "Layout 1"})
        open(sys.argv[3], "w").write(r["xml"]); print("fresh export saved:", sys.argv[3])
