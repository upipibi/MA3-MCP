"""Build the XYZ-capable Tornado on the working copy (edit-copy FixtureType 25), mode 5 tree.
Needs the Patch menu open. Steps: axes (yoke, array, head) -> try XYZ -> head children -> verify.
usage: build.py axes | children | verify"""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "tools")); sys.path.insert(0, HERE)
from mcp_call import call
from geomath import *
T = "Root 14.10.6.25"; BEAM_ARRAY = f"{T}.5.4.2"; MODE = f"{T}.6.5"
BEFORE = json.load(open(os.path.join(HERE, "geometry-before.json")))
def get(tool, args):
    ok, v = call(tool, args)
    if not ok: print("FAILED", tool, args, str(v)[:300]); sys.exit(1)
    return v
def setp(addr, prop, val): return get("ma3_set", {"address": addr, "property": prop, "value": val}).get("after")
def pose(addr):
    p = get("ma3_object", {"address": addr})["properties"]
    return [float(p.get(k) or 0) for k in ("ROTX", "ROTY", "ROTZ")], [float(p.get(k) or 0) for k in ("POSX", "POSY", "POSZ")]
def set_rot(addr, t):
    setp(addr, "ROTY", 0); setp(addr, "ROTX", t[0]); setp(addr, "ROTZ", t[2])
    if t[1]: setp(addr, "ROTY", t[1])
def set_pos(addr, p):
    for k, v in zip(("POSX", "POSY", "POSZ"), p): setp(addr, k, v)
def old(addr, what): n = BEFORE[addr]; return [float(n.get(k) or 0) for k in (("ROTX", "ROTY", "ROTZ") if what == "rot" else ("POSX", "POSY", "POSZ"))]
step = sys.argv[1]
yokes = [f"{BEAM_ARRAY}.{k}" for k in range(1, 6)]
if step == "axes":
    for y in yokes:
        a, h = f"{y}.1", f"{y}.1.1"
        # MA's XYZ rules (measured): tilt axis square to the pan axis AND its origin on the pan axis.
        # So the pan axis moves to the head's pivot: yoke origin shifts by the old head offset, head offset 0.
        drop = mv(mm(euler(old(y, "rot")), euler(old(a, "rot"))), old(h, "pos"))
        set_pos(y, [round(old(y, "pos")[i] + drop[i], 6) + 0.0 for i in range(3)])
        set_rot(y, YOKE_NEW); set_rot(a, (0, 0, 0)); set_rot(h, (0, 0, 0)); set_pos(h, [0, 0, 0])
        print(BEFORE[y]["name"], "yoke", pose(y), "| array", pose(a)[0], "| head", pose(h))
    r = get("ma3_set", {"address": MODE, "property": "XYZ", "value": True})
    print("XYZ on mode 5 with five heads:", r.get("before"), "->", r.get("after"))
if step == "children":
    n = 0
    for y in yokes:
        a, h = f"{y}.1", f"{y}.1.1"
        k = mm(tr(euler(YOKE_NEW)), mm(euler(old(a, "rot")), euler(old(h, "rot"))))
        for addr in sorted((x for x in BEFORE if x.startswith(h + ".") and x.count(".") == h.count(".") + 1), key=lambda x: int(x.rsplit(".", 1)[1])):
            m = mm(k, euler(old(addr, "rot"))); t = decompose(m); assert close(euler(t), m)
            set_rot(addr, t); set_pos(addr, [round(v, 6) + 0.0 for v in mv(k, old(addr, "pos"))]); n += 1
        print(BEFORE[y]["name"], "children done")
    print("children re-posed:", n)
if step in ("children", "verify"):
    bad = 0; checked = 0
    for y in yokes:
        a, h = f"{y}.1", f"{y}.1.1"
        (yr, yp), (ar, ap), (hr, hp) = pose(y), pose(a), pose(h)
        w_old_h = mm(euler(old(y, "rot")), mm(euler(old(a, "rot")), euler(old(h, "rot"))))
        w_new_h = mm(euler(yr), mm(euler(ar), euler(hr)))
        o_old = [old(y, "pos")[i] + mv(mm(euler(old(y, "rot")), euler(old(a, "rot"))), old(h, "pos"))[i] for i in range(3)]
        o_new = [yp[i] + mv(mm(euler(yr), euler(ar)), hp)[i] for i in range(3)]
        if any(abs(v) > 1e-6 for v in hp[:2]): bad += 1; print("  tilt pivot off the pan axis", BEFORE[h]["name"], hp)
        if max(abs(o_old[i] - o_new[i]) for i in range(3)) > 1e-4: bad += 1; print("  head origin moved", BEFORE[h]["name"], o_old, o_new)
        if not close(euler(hr), [[1, 0, 0], [0, 1, 0], [0, 0, 1]]) or not close(euler(ar), [[1, 0, 0], [0, 1, 0], [0, 0, 1]]): bad += 1; print("  tilt axis not square", BEFORE[h]["name"])
        for addr in (x for x in BEFORE if x.startswith(h + ".") and x.count(".") == h.count(".") + 1):
            cr, cp = pose(addr); checked += 1
            if not close(mm(w_old_h, euler(old(addr, "rot"))), mm(w_new_h, euler(cr)), 1e-3): bad += 1; print("  orientation differs", BEFORE[addr]["name"], cr)
            po, pn = mv(w_old_h, old(addr, "pos")), mv(w_new_h, cp)
            if max(abs(po[i] - pn[i]) for i in range(3)) > 1e-4: bad += 1; print("  position differs", BEFORE[addr]["name"], po, pn)
    m = get("ma3_object", {"address": MODE})["properties"]
    print(f"verify: {checked} head children checked, problems: {bad} | mode 5 XYZ = {m.get('XYZ')}, footprint {m.get('TOTALFOOTPRINT')}, conflicts {m.get('CONFLICTCOUNT')}")
