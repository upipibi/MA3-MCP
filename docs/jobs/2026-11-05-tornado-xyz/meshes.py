"""Keep the 3D look: the yoke and head models move onto plain child parts with compensating poses,
because the two axis parts were re-oriented for XYZ. Working copy = edit-copy FixtureType 25."""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "tools")); sys.path.insert(0, HERE)
from mcp_call import call
from geomath import *
T = "Root 14.10.6.25"; BA = f"{T}.5.4.2"; DONOR = f"{T}.5.4.3"     # 'Pigtail2': a plain part to copy
BEFORE = json.load(open(os.path.join(HERE, "geometry-before.json")))
def get(tool, args):
    ok, v = call(tool, args)
    if not ok: print("FAILED", tool, args, str(v)[:200]); sys.exit(1)
    return v
def setp(a, p, v): return get("ma3_set", {"address": a, "property": p, "value": v}).get("after")
def old(addr, keys): n = BEFORE[addr]; return [float(n.get(k) or 0) for k in keys]
R, P = ("ROTX", "ROTY", "ROTZ"), ("POSX", "POSY", "POSZ")
def place(addr, name, model, rot, pos):
    setp(addr, "NAME", name); m = setp(addr, "MODEL", model)
    setp(addr, "ROTY", 0); setp(addr, "ROTX", rot[0]); setp(addr, "ROTZ", rot[2]); setp(addr, "ROTY", rot[1])
    for k, v in zip(P, pos): setp(addr, k, v)
    return m
F = euler(YOKE_NEW)
for k in range(1, 6):
    y, a, h = f"{BA}.{k}", f"{BA}.{k}.1", f"{BA}.{k}.1.1"
    n = BEFORE[y]["name"].split()[-1]
    kids = get("ma3_children", {"address": h, "limit": 30})["children"]
    if not any(c["name"].startswith("Head body") for c in kids):
        slot = max(c["index"] for c in kids) + 1
        get("ma3_command", {"command": f"Copy {DONOR} At {h}.{slot}"})
        kmat = mm(tr(F), mm(euler(old(a, R)), euler(old(h, R))))
        m = place(f"{h}.{slot}", f"Head body {n}", "Head", decompose(kmat), [0, 0, 0]); setp(h, "MODEL", "")
        print(f"head {n}: body part at child {slot}, model {m}")
    kids = get("ma3_children", {"address": y, "limit": 30})["children"]
    if not any(c["name"].startswith("Yoke body") for c in kids):
        slot = max(c["index"] for c in kids) + 1
        get("ma3_command", {"command": f"Copy {DONOR} At {y}.{slot}"})
        drop = mv(euler(old(a, R)), old(h, P))                       # old head offset in the old yoke frame (yoke rot was 0)
        m = place(f"{y}.{slot}", f"Yoke body {n}", BEFORE[y]["MODEL"].replace("FixtureType 25", "FixtureType 25"), decompose(tr(F)), [round(v, 6) + 0.0 for v in mv(tr(F), [-d for d in drop])])
        if m != BEFORE[y]["MODEL"]: print("   yoke model mismatch:", m, "wanted", BEFORE[y]["MODEL"])
        setp(y, "MODEL", ""); print(f"yoke {n}: body part at child {slot}, model {m}")
ok, r = call("ma3_set", {"address": f"{T}.6.5", "property": "XYZ", "value": True})
o = get("ma3_object", {"address": f"{T}.6.5"})["properties"]
print("mode 5:", {k: o.get(k) for k in ("XYZ", "CONFLICTCOUNT", "TOTALFOOTPRINT")})
