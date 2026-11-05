"""Relabel pan/tilt on the Tornado TEST COPY (edit-copy fixture type 25) and try XYZ.
Outer axis (Yoke n channel) becomes Pan, inner axis (Head n channel) becomes Tilt.
The Patch menu must be open on the console: this writes to ShowData.Patch (Root 14.10).
usage: relabel.py <mode index>"""
import json, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))
from mcp_call import call
T = "Root 14.10.6.25"; mode = sys.argv[1]; M = f"{T}.6.{mode}"
def get(tool, args):
    ok, v = call(tool, args)
    if not ok: print("FAILED", tool, args, v); sys.exit(1)
    return v
def setp(addr, prop, val):
    r = get("ma3_set", {"address": addr, "property": prop, "value": val})
    if r.get("after") != val: print("  NOT APPLIED", addr, prop, r.get("before"), "->", r.get("after"))
    return r
chans = get("ma3_children", {"address": f"{M}.1", "limit": 200, "fields": ["GEOMETRY", "DEFAULTCHANNELFUNCTION"]})["children"]
todo = []
for c in chans:
    f = c["properties"].get("DEFAULTCHANNELFUNCTION", "")
    if c["name"].startswith("Head") and (f.startswith("Pan.") or f == "Tilt.Pan"): todo.append((c["index"], c["name"], "Tilt"))
    if c["name"].startswith("Yoke") and f.startswith("Tilt."): todo.append((c["index"], c["name"], "Pan"))
print("mode", mode, "channels to relabel:", todo)
for idx, name, new in sorted(todo, key=lambda t: t[2] != "Tilt"):   # heads first
    setp(f"{M}.1.{idx}.1", "ATTRIBUTE", new)
    setp(f"{M}.1.{idx}.1.1", "ATTRIBUTE", new)
    setp(f"{M}.1.{idx}.1.1", "NAME", new)
chans = get("ma3_children", {"address": f"{M}.1", "limit": 200, "fields": ["GEOMETRY", "DEFAULTCHANNELFUNCTION"]})["children"]
print("after:", [(c["name"], c["properties"]["GEOMETRY"], c["properties"]["DEFAULTCHANNELFUNCTION"]) for c in chans if "Pan" in c["name"] or "Tilt" in c["name"]])
r = get("ma3_set", {"address": M, "property": "XYZ", "value": True})
print("XYZ on mode", mode, ":", r.get("before"), "->", r.get("after"))
o = get("ma3_object", {"address": M})["properties"]
print({k: o.get(k) for k in ("NAME", "XYZ", "XYZPOSSIBLE", "TOTALFOOTPRINT", "CONFLICTCOUNT", "CONFLICTSUMMARY", "USED")})
