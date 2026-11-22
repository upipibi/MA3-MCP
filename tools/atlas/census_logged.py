#!/usr/bin/env python3
"""The 2026-11-08 class census again, on onPC, with the address written to a log BEFORE each call,
so a call that never returns names its object. Same breadth-first walk as tools/atlas/census.py.
usage: census_logged.py <out.json> <log.txt> [max_calls] [per_class]"""
import json, os, sys, time, urllib.request, socket
s = json.load(open(os.path.expanduser("~/MALightingTechnology/gma3_library/ma3_mcp_settings.json")))
URL = "http://127.0.0.1:%s/mcp" % s.get("port", 9800); HDR = {"Authorization": "Bearer " + str(s.get("pin", "")), "Content-Type": "application/json"}
out_path, log_path = sys.argv[1], sys.argv[2]
max_calls = int(sys.argv[3]) if len(sys.argv) > 3 else 6000
PER_CLASS = int(sys.argv[4]) if len(sys.argv) > 4 else 3
log = open(log_path, "a")
classes, calls, t0, errors, slow = {}, 0, time.time(), [], []
def rec(cls): return classes.setdefault(cls, {"props": None, "parents": set(), "children": set(), "seen": 0, "descended": 0, "max_children": 0, "example": None})
def save(final=False):
    json.dump({"generated": time.strftime("%Y-%m-%d %H:%M"), "station": "onPC", "calls": calls, "seconds": round(time.time() - t0), "complete": final,
               "errors": errors[:200], "slow": slow[:100],
               "classes": {k: {**v, "parents": sorted(v["parents"]), "children": sorted(v["children"])} for k, v in sorted(classes.items())}}, open(out_path, "w"), indent=1)
def c(tool, args):
    global calls
    calls += 1
    log.write(f"{calls}\t{tool}\t{args.get('address')}\n"); log.flush(); os.fsync(log.fileno())
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": tool, "arguments": args}}).encode()
    t = time.time()
    try:
        with urllib.request.urlopen(urllib.request.Request(URL, data=body, headers=HDR), timeout=12) as r: resp = json.loads(r.read().decode("utf-8", "replace"))
    except (socket.timeout, TimeoutError, urllib.error.URLError) as e:
        save(); print(f"HANG or connection lost at call {calls}: {tool} {args.get('address')} ({e})", flush=True)
        # a stalled onPC inside the session backs up the console (flow control, 2026-11-21): end it at once
        import subprocess; subprocess.run(["pkill", "-KILL", "-f", "grandMA3 onPC 2.5.1.1.app/Contents/MacOS"]); print("onPC ended", flush=True)
        sys.exit(3)
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}"
    dt = time.time() - t
    if dt > 1.0: slow.append([args.get("address"), tool, round(dt, 2)])
    if calls % 100 == 0: save(); print(f"{calls} calls, {len(classes)} classes, {time.time()-t0:.0f}s, queue {len(queue)}", flush=True)
    if "error" in resp: return False, resp["error"]
    res = resp["result"]; text = res["content"][0]["text"] if res.get("content") else ""
    try: val = json.loads(text)
    except ValueError: val = text
    return not res.get("isError"), val
queue = [("Root", None)]
while queue and calls < max_calls:
    address, parent_cls = queue.pop(0)
    ok, obj = c("ma3_object", {"address": address, "schema": True})
    if not ok or not isinstance(obj, dict): errors.append([address, str(obj)[:160]]); continue
    cls = obj.get("class") or "?"; r = rec(cls); r["seen"] += 1
    if parent_cls: r["parents"].add(parent_cls); rec(parent_cls)["children"].add(cls)
    if r["props"] is None: r["props"] = obj.get("schema") or []; r["example"] = obj.get("address")
    n = obj.get("child_count") or 0; r["max_children"] = max(r["max_children"], n)
    if n == 0 or r["descended"] >= PER_CLASS: continue
    r["descended"] += 1
    ok, ch = c("ma3_children", {"address": address, "limit": 500})
    if not ok or not isinstance(ch, dict): errors.append([address + " (children)", str(ch)[:160]]); continue
    picked = {}
    for row in ch.get("children") or []:
        if row.get("class") and not row.get("not_an_object") and not row.get("refused"): picked.setdefault(str(row["class"]), []).append(row)
    for k, lst in picked.items():
        rec(k); rec(cls)["children"].add(k); classes[k]["parents"].add(cls)
        for row in [lst[0]] + ([lst[-1]] if len(lst) > 1 else []):
            if row.get("address"): queue.append((row["address"], cls))
save(final=not queue)
print(f"done: {calls} calls, {len(classes)} classes, {time.time()-t0:.0f}s, queue left {len(queue)}, errors {len(errors)}, slow {len(slow)}")
