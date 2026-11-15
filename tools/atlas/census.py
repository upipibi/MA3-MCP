#!/usr/bin/env python3
"""Class census of the console's object tree: every class reachable from Root, its properties
(name + type) and its parent/child classes. Sampled, read-only, sequential (one request at a time).

Walk: breadth-first from Root. Every object's class schema is read once (ma3_object schema:true).
Children are listed one page (<= 500) per object; the walk descends into at most PER_CLASS objects
of each class, preferring ones that have children, so big pools (11,618 Parameter List entries,
2,000 fixtures) cost one page each, not one call per entry.
usage: tools/atlas/census.py <out.json> [max_calls]   (MA3_MCP_URL/PIN select onPC, see tools/mcp_call.py)
Writes progress to <out.json> every 50 calls."""
import json, os, sys, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from mcp_call import call

PER_CLASS = 3
out_path = sys.argv[1]; max_calls = int(sys.argv[2]) if len(sys.argv) > 2 else 4000
classes = {}          # class -> {props:[{name,type}], parents:set, children:set, seen:int, descended:int, sample_counts:[]}
calls = 0; t0 = time.time(); errors = []

def rec(cls):
    return classes.setdefault(cls, {"props": None, "parents": set(), "children": set(), "seen": 0,
                                     "descended": 0, "max_children": 0, "example": None})

def save(final=False):
    data = {"generated": time.strftime("%Y-%m-%d %H:%M"), "calls": calls, "seconds": round(time.time() - t0),
            "complete": final, "errors": errors[:50],
            "classes": {k: {**v, "parents": sorted(v["parents"]), "children": sorted(v["children"])}
                        for k, v in sorted(classes.items())}}
    json.dump(data, open(out_path, "w"), indent=1)

def c(tool, args):
    global calls
    calls += 1
    ok, v = call(tool, args)
    if calls % 50 == 0:
        save(); print(f"{calls} calls, {len(classes)} classes, {time.time()-t0:.0f}s", file=sys.stderr, flush=True)
    return ok, v

queue = [("Root", None)]
while queue and calls < max_calls:
    address, parent_cls = queue.pop(0)
    ok, obj = c("ma3_object", {"address": address, "schema": True})
    if not ok or not isinstance(obj, dict):
        errors.append([address, str(obj)[:120]]); continue
    cls = obj.get("class") or "?"; r = rec(cls); r["seen"] += 1
    if parent_cls: r["parents"].add(parent_cls); rec(parent_cls)["children"].add(cls)
    if r["props"] is None:
        r["props"] = obj.get("schema") or []; r["example"] = obj.get("address")
    n = obj.get("child_count") or 0
    r["max_children"] = max(r["max_children"], n)
    if n == 0 or r["descended"] >= PER_CLASS: continue
    r["descended"] += 1
    ok, ch = c("ma3_children", {"address": address, "limit": 500})
    if not ok or not isinstance(ch, dict):
        errors.append([address + " (children)", str(ch)[:120]]); continue
    rows = ch.get("children") or []
    # one representative per child class, preferring later rows too (first and last of each class)
    picked = {}
    for row in rows:
        k = row.get("class")
        picked.setdefault(k, []).append(row)
    for k, lst in picked.items():
        rec(k); rec(cls)["children"].add(k); classes[k]["parents"].add(cls)
        cands = [lst[0]] + ([lst[-1]] if len(lst) > 1 else [])
        for row in cands:
            a = row.get("address")
            if a: queue.append((a, cls))
save(final=not queue)
print(f"done: {calls} calls, {len(classes)} classes, {time.time()-t0:.0f}s, queue left {len(queue)}, errors {len(errors)}", file=sys.stderr)
