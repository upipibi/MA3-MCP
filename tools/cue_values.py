#!/usr/bin/env python3
"""Summarise what each cue of an exported sequence (ma3_export XML) actually does.

usage: cue_values.py <export.xml> [fixtures.json]
Per cue: fade/transition, then per fixture family and attribute the value (absolute range,
preset name, or phaser). Referenced presets embedded as dependencies are ignored.
"""
import sys, json, re, collections, pathlib
import xml.etree.ElementTree as ET

xml_path = pathlib.Path(sys.argv[1])
fx_path = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else None
text = xml_path.read_text()
text = text.lstrip("﻿")
# a truncated export: cut back to the last complete </Cue>
if not text.rstrip().endswith("</GMA3>"):
    cut = text.rfind("</Cue>")
    text = text[:cut + 6] + "\n</Sequence></GMA3>"
    truncated = True
else:
    truncated = False
root = ET.fromstring(text)

# fixture id -> family (fixture type) from the show's fixture dump
fam = {}
if fx_path and fx_path.exists():
    def walk(r, parent_type):
        t = r.get("fixture_type") or parent_type or "?"
        if r.get("id") is not None: fam[str(r["id"])] = t
        for ch in r.get("children") or []: walk(ch, t)
    for r in json.load(open(fx_path))["rows"]: walk(r, None)
def family(fid):
    if fid in fam: return fam[fid]
    base = fid.split(".")[0]
    return fam.get(base, "id " + base)

def short_preset(p):
    if not p: return None
    p = p.replace("&apos;", "'").replace("'", "")
    return p.split(".", 1)[1] if "." in p else p

def fmt_vals(vals):
    nums = []
    for v in vals:
        try: nums.append(float(v))
        except (TypeError, ValueError): pass
    if nums and len(nums) == len(vals):
        lo, hi = min(nums), max(nums)
        return f"{lo:g}" if lo == hi else f"{lo:g}–{hi:g}"
    return "/".join(sorted(set(str(v) for v in vals)))[:40]

out = []
seq = root.find(".//Sequence")
title = seq.get("Name") if seq is not None else root.find(".//Preset").get("Name")
out.append(f"### Cue values: {title}" + (" (export truncated; partial)" if truncated else ""))
attr_use, preset_use, fam_use = collections.Counter(), collections.Counter(), collections.Counter()
containers = root.findall(".//Cue") if seq is not None else [root.find(".//Preset")]
for cue in containers:
    no = (cue.get("No") or "").strip()
    name = cue.get("Name", "")
    for part in ([cue] if cue.tag == "Preset" else cue.findall("Part")):
        fade = part.get("CueInFade"); trans = part.get("Transition")
        # PresetData that is a direct child of this part (not inside DependencyExport)
        pdata = [c for c in list(part) if c.tag == "PresetData"]
        rows = collections.defaultdict(lambda: {"ids": set(), "abs": [], "presets": set(), "phaser": 0, "rel": 0})
        for pd in pdata:
            for ph in pd.findall("Phaser"):
                fid = ph.get("ID", "?"); attr = ph.get("Attribute", "?")
                key = (family(fid), attr)
                r = rows[key]; r["ids"].add(fid)
                ap = short_preset(ph.get("AbsPreset")); rp = short_preset(ph.get("RelPreset"))
                if ap: r["presets"].add(ap); preset_use[ap] += 1
                if rp: r["presets"].add("rel " + rp); preset_use[rp] += 1
                steps = ph.findall("Step")
                if len(steps) > 1: r["phaser"] = max(r["phaser"], len(steps))
                for st in steps:
                    if st.get("Absolute") is not None: r["abs"].append(st.get("Absolute"))
                    elif st.get("AbsolutePhys") is not None: r["abs"].append(st.get("AbsolutePhys"))
                    elif st.get("RelativePhys") is not None or st.get("Relative") is not None: r["rel"] += 1
                attr_use[attr] += 1
        if not rows:
            out.append(f"- **{no} {name}** fade {fade} {trans or ''}: (no values)"); continue
        byfam = collections.defaultdict(list)
        for (f, attr), r in sorted(rows.items()):
            bits = []
            if r["presets"]: bits.append("preset " + ", ".join(sorted(r["presets"])))
            if r["abs"] and not r["presets"]: bits.append(fmt_vals(r["abs"]))
            if r["phaser"] > 1: bits.append(f"phaser {r['phaser']} steps")
            if r["rel"]: bits.append("relative")
            byfam[f].append((attr, " ".join(bits), len(r["ids"])))
        line = f"- **{no} {name}** fade {fade} {trans or ''}: "
        parts = []
        for f, items in byfam.items():
            n = max(i[2] for i in items); fam_use[f] += 1
            parts.append(f"{f} ×{n} [" + "; ".join(f"{a} {b}".strip() for a, b, _ in items) + "]")
        out.append(line + " | ".join(parts))
out.append("")
out.append("Attributes used: " + ", ".join(f"{a} {n}" for a, n in attr_use.most_common(25)))
out.append("Presets referenced: " + ", ".join(f"{p} {n}" for p, n in preset_use.most_common(25)))
out.append("Families touched (cues): " + ", ".join(f"{f} {n}" for f, n in fam_use.most_common()))
print("\n".join(out))
