#!/usr/bin/env python3
"""Download every topic of the grandMA3 help (one version) into .cache/ma-help/<ver>/html/.

The table of contents is embedded in the site's toc_nav.js; this reads it, then fetches each
topic page politely (4 at a time, skips pages already on disk). MA's content stays local:
.cache/ is git-ignored.
usage: tools/helpsite/fetch.py [version]   (default 2.5)"""
import json, os, re, sys, time, urllib.request, concurrent.futures as cf

VER = sys.argv[1] if len(sys.argv) > 1 else "2.5"
BASE = f"https://help.malighting.com/grandMA3/{VER}"
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".cache", "ma-help", VER)
UA = {"User-Agent": "MA3-MCP help indexer (personal use)"}

def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return r.read()

def toc():
    s = get(f"{BASE}/_webHelpScripts/Master/toc_nav.js").decode("utf-8", "replace")
    start = s.find('[{"id":"'); depth = 0; i = start; inq = esc = False
    while True:
        c = s[i]
        if inq:
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == '"': inq = False
        elif c == '"': inq = True
        elif c == "[": depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0: break
        i += 1
    tree = json.loads(s[start:i + 1]); flat = []
    def walk(nodes, path):
        for n in nodes:
            p = path + [n["t"]]
            flat.append({"id": n["vals"].get("e"), "title": n["t"], "path": " > ".join(p),
                         "depth": len(p), "children": len(n.get("c") or [])})
            walk(n.get("c") or [], p)
    walk(tree, [])
    return flat

def fetch(t):
    out = os.path.join(ROOT, "html", t["id"] + ".html")
    if os.path.exists(out) and os.path.getsize(out) > 0: return t["id"], "cached"
    for attempt in range(3):
        try:
            data = get(f"{BASE}/HTML/{t['id']}.html")
            open(out, "wb").write(data); time.sleep(0.1); return t["id"], "ok"
        except Exception as e:
            err = str(e); time.sleep(2 * (attempt + 1))
    return t["id"], "fail " + err

if __name__ == "__main__":
    os.makedirs(os.path.join(ROOT, "html"), exist_ok=True)
    topics = toc(); json.dump(topics, open(os.path.join(ROOT, "toc.json"), "w"), indent=0)
    todo = [t for t in topics if t["id"]]
    done = 0; fails = []
    with cf.ThreadPoolExecutor(4) as ex:
        for tid, st in ex.map(fetch, todo):
            done += 1
            if st.startswith("fail"): fails.append((tid, st))
            if done % 100 == 0: print(f"{done}/{len(todo)}", flush=True)
    print(f"done {done}, failed {len(fails)}", fails[:10], flush=True)
