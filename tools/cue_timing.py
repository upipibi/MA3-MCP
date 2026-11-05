#!/usr/bin/env python3
"""Cue timing table from an ma3_dump {depth:2} of a sequence, saved as JSON ({"text": ...}).
usage: cue_timing.py <dump.json>   -> Markdown table on stdout (cue numbers shown as the console shows them)."""
import json, sys, re
t = json.load(open(sys.argv[1]))["text"]
parts, cur, seqname = {}, None, ""
for ln in t.split("\n"):
    m = re.match(r'^(\s*)(Sequence \d+(?:\.\S+)?) "(.*)" \((\w+)\)$', ln)
    if m:
        cur = m.group(2); parts[cur] = {"name": m.group(3), "cls": m.group(4), "props": {}}
        if m.group(4) == "Sequence": seqname = f"{m.group(2)} {m.group(3)}"
        continue
    m2 = re.match(r'^\s+(\w+) = (.*)$', ln)
    if m2 and cur: parts[cur]["props"][m2.group(1)] = m2.group(2)
seq = next((p for p in parts.values() if p["cls"] == "Sequence"), {"props": {}})["props"]
keys = ["TRACKING","AUTOSTOP","AUTOSTART","AUTOPREPOS","PRIORITY","RESTARTMODE","WRAPAROUND","SOFTLTP","OFFWHENOVERRIDDEN","RELEASEFIRSTCUE","SEQUMIB","SEQUMIBMODE","XFADEMODE","USEEXECUTORTIME","APPEARANCE"]
print(f"### Cue timing: {seqname}\n")
print("Sequence settings: " + ", ".join(f"{k}={seq[k]}" for k in keys if k in seq) + "\n")
print("| Cue | Name | Trig | Trig time | In fade | In delay | Out fade | Out delay | Snap delay | Cmd delay | MIB | Note |")
print("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
for a, p in parts.items():
    if p["cls"] != "Cue": continue
    raw = a.split(".")[1]
    try: no = f"{int(raw)/1000:g}"
    except ValueError: no = raw
    pr = p["props"]; pt = parts.get(a + ".0", {"props": {}})["props"]
    note = (pr.get("NOTE") or pt.get("NOTE") or "").replace("\n", " / ")
    print(f"| {no} | {p['name']} | {pr.get('TRIGTYPE','')} | {pr.get('TRIGTIME','')} | {pt.get('CUEINFADE','')} | {pt.get('CUEINDELAY','')} | {pt.get('CUEOUTFADE','')} | {pt.get('CUEOUTDELAY','')} | {pt.get('SNAPDELAY','')} | {pt.get('COMMANDDELAY','')} | {pt.get('MIBMODE','')} | {note} |")
