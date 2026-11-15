#!/usr/bin/env python3
"""Show database: many shows' objects in one SQLite file, so questions across shows are one query.

Prototype (2026-11-08). One table, one row per object property:
  props(show, address, class, parent, name, key, value)
Loaders: `load` takes JSON Lines, one object per line: {"address","class","parent","name","props":{...}}
(the format a future snapshot tool will write); `load-rt` takes the Parameter List reads made with
docs/jobs/2026-11-08-dimmer-curves/scan_rt.py.
usage:
  showdb.py <db> load    <show> <objects.jsonl>
  showdb.py <db> load-rt <show> <rt.json>
  showdb.py <db> diff    <showA> <showB> [class] [key]     objects/properties that differ
  showdb.py <db> sql     "<query>"
Speed (2026-11-08, M-series Mac): 7,337 objects loaded in well under a second; a two-show diff
over them in milliseconds."""
import json, sqlite3, sys, time

def db(path):
    con = sqlite3.connect(path)
    con.execute("create table if not exists props(show text, address text, class text, parent text, name text, key text, value text)")
    con.execute("create index if not exists p1 on props(show, class, key)")
    con.execute("create index if not exists p2 on props(show, address)")
    return con

def put(con, show, objs):
    con.execute("delete from props where show=?", (show,))
    rows = []
    for o in objs:
        for k, v in (o.get("props") or {}).items():
            rows.append((show, o.get("address"), o.get("class"), o.get("parent"), o.get("name"), k, None if v is None else str(v)))
    con.executemany("insert into props values(?,?,?,?,?,?,?)", rows)
    con.commit()
    return len(rows)

def rt_objects(path):
    for r in json.load(open(path)):
        if "error" in r: continue
        fid = r.get("fid")
        yield {"address": f"Root 14.9.9.{r['i']}", "class": "RTChannel", "parent": "Root 14.9.9",
               "name": f"FID {fid} {r.get('name')}", "props": {"FID": fid, "CHANNELNAME": r.get("name"), "DMXCURVE": r.get("curve") or ""}}

def diff(con, a, b, cls=None, key=None):
    # Objects are matched by (class, name): addresses shift between shows (index 189 vs 179).
    q = """select coalesce(x.class,y.class), coalesce(x.name,y.name), coalesce(x.key,y.key), x.value, y.value from
           (select class,name,key,value from props where show=? {f}) x
           full outer join (select class,name,key,value from props where show=? {f}) y
           on x.class=y.class and x.name=y.name and x.key=y.key
           where coalesce(x.value,'') <> coalesce(y.value,'') order by 1,2,3"""
    f, args = "", []
    if cls: f += " and class=?"; args.append(cls)
    if key: f += " and key=?"; args.append(key)
    return con.execute(q.format(f=f), [a] + args + [b] + args).fetchall()

if __name__ == "__main__":
    path, cmd = sys.argv[1], sys.argv[2]
    con = db(path); t0 = time.time()
    if cmd == "load":
        n = put(con, sys.argv[3], (json.loads(l) for l in open(sys.argv[4]) if l.strip()))
        print(f"{n} properties in {time.time()-t0:.3f} s")
    elif cmd == "load-rt":
        n = put(con, sys.argv[3], rt_objects(sys.argv[4]))
        print(f"{n} properties in {time.time()-t0:.3f} s")
    elif cmd == "diff":
        rows = diff(con, sys.argv[3], sys.argv[4], *(sys.argv[5:7]))
        for r in rows: print(" | ".join("" if v is None else str(v) for v in r))
        print(f"-- {len(rows)} differences in {time.time()-t0:.3f} s", file=sys.stderr)
    elif cmd == "sql":
        for r in con.execute(sys.argv[3]): print(" | ".join("" if v is None else str(v) for v in r))
