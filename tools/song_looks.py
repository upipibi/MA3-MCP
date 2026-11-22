#!/usr/bin/env python3
"""What each cue of a song LOOKS like, with tracking applied: per fixture family the dimmer, colour,
position, zoom and phasers that are live in that cue, and what the cue itself changes.

usage: song_looks.py <export.xml> <fixtures.json> [--json out.json]
Reads an ma3_export of a sequence. Prints one block per cue that changes something; cues that store
nothing are listed as holds. The JSON form carries the full state per cue for cross-song statistics."""
import sys, json, re, collections, colorsys, pathlib
import xml.etree.ElementTree as ET

text = pathlib.Path(sys.argv[1]).read_text().lstrip("﻿")
fam = {}
def walk(r, parent_type, parent_name):
    t = r.get("fixture_type") or parent_type or "?"
    for key in ("id", "fid"):
        if r.get(key) is not None: fam[str(r[key])] = t
    for ch in r.get("children") or []: walk(ch, t, r.get("name"))
for r in json.load(open(sys.argv[2]))["rows"]: walk(r, None, None)
def family(fid):
    f = fam.get(fid) or fam.get(fid.split(".")[0]) or ("id " + fid.split(".")[0])
    return f.replace("### ", "")

def num(v):
    try: return float(str(v).lstrip("*"))
    except (TypeError, ValueError): return None
def preset_name(p):
    if not p: return None
    p = p.replace("&apos;", "'").replace("'", "")
    return p.split(".", 1)[1] if "." in p else p
def colour_name(r, g, b, w=0):
    if max(r, g, b, w) < 3: return "off"
    if w > 60 and max(r, g, b) < 40: return "white"
    h, s, v = colorsys.rgb_to_hsv(r / 100, g / 100, b / 100)
    if s < 0.18: return "white" if w > 20 or v > 0.5 else "dim white"
    h *= 360
    for lim, n in ((15, "red"), (40, "orange"), (65, "amber"), (90, "yellow"), (160, "green"), (195, "cyan"), (225, "light blue"), (255, "blue"), (285, "purple"), (330, "magenta"), (361, "red")):
        if h < lim: return n + (" pale" if s < 0.5 else "")
GROUPS = {"Dimmer": "dim", "ColorRGB_R": "col", "ColorRGB_G": "col", "ColorRGB_B": "col", "ColorRGB_W": "col", "ColorRGB_GY": "col", "Color1": "col", "COLORMIXER": "col",
          "Pan": "pos", "Tilt": "pos", "PanTiltDistance": "pos", "Zoom": "zoom", "Focus1": "zoom", "Shutter1": "strobe", "Gobo1": "gobo", "Gobo1Pos": "gobo"}

root = ET.fromstring(text)
seq = root.find(".//Sequence")
state = {}   # (fid, attr) -> value dict
cues = []
for cue in seq.findall("Cue"):
    name = cue.get("Name", ""); no = (cue.get("No") or "").strip()
    if name in ("OffCue", "CueZero"): continue
    part = cue.find("Part")
    changed = {}
    for pd in ([c for c in list(part) if c.tag == "PresetData"] if part is not None else []):
        for ph in pd.findall("Phaser"):
            fid, attr = ph.get("ID", "?"), ph.get("Attribute", "?")
            steps = ph.findall("Step")
            vals = [num(s.get("Absolute") if s.get("Absolute") is not None else s.get("AbsolutePhys")) for s in steps]
            v = {"vals": [x for x in vals if x is not None], "preset": preset_name(ph.get("AbsPreset")), "rel": preset_name(ph.get("RelPreset")),
                 "steps": len(steps), "speed": num(ph.get("Speed")), "master": ph.get("SpeedMaster"), "phase": num(ph.get("Phase")),
                 "release": ph.get("Release") is not None or (len(steps) == 0)}
            if any((st.get("Absolute") or "").startswith("Specials:Release") for st in steps): v["released"] = True
            changed[(fid, attr)] = v
    for k, v in changed.items():
        if v.get("released"): state.pop(k, None)      # a released value is no longer part of the look
        else: state[k] = v
    changed = {k: v for k, v in changed.items() if not v.get("released")} or ({} if not changed else {k: v for k, v in changed.items() if not v.get("released")})
    cues.append({"no": no, "name": name, "trigger": cue.get("TrigType") or (part.get("TrigType") if part is not None else None),
                 "fade": num(part.get("CueInFade")) if part is not None else None, "changed": dict(changed), "state": dict(state)})

def summarise(values):
    """values: {(fid, attr): v} -> {family: {'n':…, 'dim':…, 'col':…, 'pos':…, 'zoom':…, 'phasers':[…]}}"""
    per = collections.defaultdict(lambda: collections.defaultdict(dict))
    for (fid, attr), v in values.items(): per[family(fid)][fid][attr] = v
    out = {}
    for f, fixtures in per.items():
        row = {"n": len(fixtures)}
        dims, cols, poss, zooms, phasers, strobe = collections.Counter(), collections.Counter(), collections.Counter(), collections.Counter(), collections.Counter(), collections.Counter()
        for fid, attrs in fixtures.items():
            d = attrs.get("Dimmer")
            if d:
                if d["steps"] > 1: phasers["Dimmer %s steps %s%s" % (d["steps"], "-".join("%g" % x for x in d["vals"]), (" " + d["master"]) if d["master"] and d["master"] != "None" else "")] += 1
                label = ("preset " + d["preset"]) if d["preset"] else ("%g" % d["vals"][0] if d["vals"] else "?")
                dims[label if d["steps"] <= 1 else "phaser" + ((" on preset " + d["preset"]) if d["preset"] else "")] += 1
            rgb = [attrs.get("ColorRGB_" + c) for c in "RGB"]
            if all(rgb) and all(x["vals"] for x in rgb):
                w = attrs.get("ColorRGB_W"); wv = w["vals"][0] if w and w["vals"] else 0
                r, g, b = (x["vals"][0] for x in rgb)
                cols["%s (%d %d %d%s)" % (colour_name(r, g, b, wv), round(r), round(g), round(b), " w%d" % round(wv) if wv else "")] += 1
                if any(x["steps"] > 1 for x in rgb): phasers["Colour %s steps" % max(x["steps"] for x in rgb)] += 1
            for a in ("Pan", "Tilt"):
                p = attrs.get(a)
                if p:
                    poss[("preset " + p["preset"]) if p["preset"] else "values"] += 0.5
                    if p["steps"] > 1 or p["rel"]: phasers["%s %s%s" % (a, ("rel " + p["rel"]) if p["rel"] else "%d steps" % p["steps"], "")] += 1
            z = attrs.get("Zoom")
            if z:
                zooms[("preset " + z["preset"]) if z["preset"] else ("%g" % z["vals"][0] if z["vals"] else "?")] += 1
                if z["steps"] > 1: phasers["Zoom %d steps %s" % (z["steps"], "-".join("%g" % x for x in z["vals"]))] += 1
            s = attrs.get("Shutter1")
            if s and s["vals"]: strobe["%g" % s["vals"][0]] += 1
        def top(c, n=3): return ", ".join("%s ×%d" % (k, round(v)) for k, v in c.most_common(n)) if c else None
        row.update({"dim": top(dims), "col": top(cols), "pos": top(poss), "zoom": top(zooms), "phasers": top(phasers, 4), "strobe": top(strobe)})
        out[f] = {k: v for k, v in row.items() if v}
    return out

title = seq.get("Name")
print("# " + title)
holds = []
js = {"title": title, "cues": []}
for c in cues:
    ch = summarise(c["changed"]); st = summarise(c["state"])
    js["cues"].append({"no": c["no"], "name": c["name"], "fade": c["fade"], "changes": ch, "state": st})
    if not ch: holds.append("%s %s" % (c["no"], c["name"])); continue
    if holds: print("  (holds: " + "; ".join(holds) + ")"); holds = []
    print("## %s %s  fade %g" % (c["no"], c["name"], c["fade"] or 0))
    for f, row in sorted(ch.items()):
        print("  %-28s ×%-3d %s" % (f, row["n"], " | ".join("%s: %s" % (k, row[k]) for k in ("dim", "col", "pos", "zoom", "strobe", "phasers") if k in row)))
if holds: print("  (holds: " + "; ".join(holds) + ")")
if "--json" in sys.argv: json.dump(js, open(sys.argv[sys.argv.index("--json") + 1], "w"))
