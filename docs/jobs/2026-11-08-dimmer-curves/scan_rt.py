#!/usr/bin/env python3
"""Read every Parameter List entry (Root 14.9.9.<n>) by index and save fid/cid/name/curve per entry.
usage: scan_rt.py <count> <out.json>   (MA3_MCP_URL / MA3_MCP_PIN select the server, see tools/mcp_call.py)
Writes the file every 100 entries so a stop loses little; prints progress to stderr."""
import json, sys, time, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "tools"))
from mcp_call import call
count, out = int(sys.argv[1]), sys.argv[2]
rows, t0 = [], time.time()
for i in range(1, count + 1):
    ok, v = call("ma3_object", {"address": f"Root 14.9.9.{i}"})
    if not ok or not isinstance(v, dict):
        rows.append({"i": i, "error": v}); continue
    p = v.get("properties", {})
    row = {"i": i, "fid": p.get("FID"), "cid": p.get("CID"), "name": p.get("CHANNELNAME"),
           "curve": p.get("DMXCURVE"), "idtype": p.get("IDTYPE")}
    extra = {k: p[k] for k in p if k not in ("INDEX","CID","NO","NAME","OWNED","USEREXPANDED","LOCK","IDTYPE","DEFAULT","LOWLIGHT","CHANNELNAME","HIGHLIGHT","SYSTEMLOCKED","COUNT","STRUCTURELOCKED","FID","HIDDEN","FADERENABLED","MEMORYFOOTPRINT")}
    if extra: row["extra"] = extra
    rows.append(row)
    if i % 100 == 0 or i == count:
        json.dump(rows, open(out, "w"), indent=1)
        print(f"{i}/{count} {time.time()-t0:.0f}s curves so far: {sum(1 for r in rows if r.get('curve'))}", file=sys.stderr)
