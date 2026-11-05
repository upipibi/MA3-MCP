"""Execute the Portman layout plan through the MA3 MCP server (tools/mcp_call.py).
usage: run_portmans.py assign | place | verify     (in that order; each step reads the console back)"""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "tools"))
from mcp_call import call
PLAN = json.load(open(os.path.join(HERE, "portman-plan.json")))["elements"]
GROUP, FIRST = "portman-layout", 228   # Layout 1.228 = Fixture 1201, placed by hand as the test
def s16(v): return v - 65536 if v > 32767 else v
def must(tool, args):
    ok, val = call(tool, args)
    if not ok: print("FAILED", tool, json.dumps(val)[:500]); sys.exit(1)
    return val
def elements():
    out, off = [], FIRST - 1
    while True:
        r = must("ma3_children", {"address": "Layout 1", "offset": off, "limit": 100, "fields": ["OBJECT", "POSX", "POSY", "WIDTH", "HEIGHT"]})
        out += r["children"]
        if not r.get("next_offset"): return out
        off = r["next_offset"]
step = sys.argv[1]
if step == "assign":
    cmds = [f"Assign Fixture {p['fixture']} At Layout 1" for p in PLAN[1:]]
    r = must("ma3_commands", {"commands": cmds, "undo_group": GROUP})
    bad = [x for x in r["results"] if x["result"] != "OK"]
    print("sent", r["sent"], "of", r["total"], "| not OK:", bad[:3], "| ms", r.get("duration_ms"), "| stopped_at", r.get("stopped_at"))
if step in ("assign", "place", "verify"):
    els = elements()
    print("elements from", FIRST, ":", len(els))
    if step == "assign":
        for c in els[:3] + els[-2:]: print("  ", c["address"], c["name"], c["properties"].get("OBJECT"))
if step == "place":
    assert len(els) == len(PLAN), (len(els), len(PLAN))
    cmds = []
    for c, p in zip(els, PLAN):
        obj = c["properties"].get("OBJECT", "")
        assert obj == "Fixture " + p["fixture"], (c["address"], obj, p["fixture"])
        cmds.append(f'Set {c["address"]} Property "PosX" {p["x"]}')
        cmds.append(f'Set {c["address"]} Property "PosY" {p["y"]}')
    for i in range(0, len(cmds), 180):
        r = must("ma3_commands", {"commands": cmds[i:i + 180], "undo_group": GROUP})
        bad = [x for x in r["results"] if x["result"] != "OK"]
        print("batch", i // 180 + 1, "sent", r["sent"], "of", r["total"], "| not OK:", bad[:3], "| ms", r.get("duration_ms"))
        if bad or r["sent"] != r["total"]: sys.exit(1)
    els = elements()
if step in ("place", "verify"):
    wrong = []
    for c, p in zip(els, PLAN):
        q = c["properties"]
        got = (q.get("OBJECT"), s16(q["POSX"]), s16(q["POSY"]), q["WIDTH"], q["HEIGHT"])
        want = ("Fixture " + p["fixture"], p["x"], p["y"], p["w"], p["h"])
        if got != want: wrong.append((c["address"], got, want))
    print("verified", len(els) - len(wrong), "of", len(PLAN), "| mismatches:", wrong[:5])
