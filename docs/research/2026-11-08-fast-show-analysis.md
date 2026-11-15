# Fast analysis of large amounts of show data (2026-11-08)

Aaron, after the dimmer curve job: "find a fast way to sort through large amounts of information.
It took you some time to sort through everything, and that was just one show. I'll be asking you to
sort through large aspects of multiple shows, for patching, configuration, and programming."
And: "you may not always have the onPC connected and up to date, but the console is always the
source of truth." Then, the same afternoon, the console froze from a read job (see the console
safety rules in `CLAUDE.md`): the console must never carry bulk exploration.

## Where the time went on the curve job

| Step | Time | Note |
| --- | --- | --- |
| Reading the Parameter List one entry per request | 33 s per 900 entries on the console, 126 s for 6,437 on onPC | one HTTP request per object |
| Finding the right object paths | most of the session | trial reads, a quirk (`RTChannels` not iterable) |
| Comparing two shows | minutes of ad-hoc scripts | no common format |
| Same comparison in a database | **0.35 s** | `tools/showdb/showdb.py`, prototype below |

So sorting is not the problem once data sits on the Mac in one format. Getting it there is: one
request per object is slow, and walking the console is what froze it.

## Options for getting a whole show onto the Mac

1. **Read the console object by object over MCP** (what was done). 30 to 50 objects a second.
   Rejected for bulk: slow, and a walk of unknown objects froze the console.
2. **Parse `.show` files directly on the Mac.** Works today for the header: the save history
   (`tools/showfile/lineage.py`, instant, any number of shows). It answered the curve question's
   "how": `Christmas 2026` was split from `Late 2026` on 2026-10-22; `Late 2026 2` came from a later
   `Late 2026` save on 2026-10-31, so the curves were most likely added after the split (not
   confirmed with Aaron). The body is MA's packed binary format (names and GUIDs readable, structure
   not): a reverse-engineering project, fragile across MA versions. Long-term research, not a plan.
3. **The console's saved show file, read by onPC on the Mac** (recommended). The console stays the
   source of truth: its own saved file is what gets read. onPC loads it (the MCP plugin travels
   inside the show file), and a new onPC-only plugin tool writes the whole object tree to a file on
   the Mac's disk in one call, in-process, no request per object. The Mac loads that into the show
   database. Nothing heavy ever runs on the console. Expected speed: hundreds of times faster than
   option 1 (no network round trip per object); not measured yet.
4. **Native XML export on onPC**, parsed on the Mac: one call per pool (all fixture types were 2 MB
   in one call). Complete for pools; not for everything (the Parameter List did not export). A
   complement to 3.

## Getting the show file off the console

- Aaron saves to the USB stick or copies it there (works today, needs him).
- SFTP to the console: MA documents access to the grandMA3 area with the account `madata` /
  `madata` (help: File Management > SFTP Connection to a Console). Read-only use (listing and
  copying show files) would make every saved show reachable from the Mac without the stick. Not
  tried: blocked by the permission check on 2026-11-08 and needs Aaron's word.

## The show database (prototype, `tools/showdb/showdb.py`)

One SQLite file, one row per object property, any number of shows side by side. Objects are
matched across shows by class and name, because addresses shift (the same dimmer was Parameter List
entry 189 in one show and 179 in the other).

Measured 2026-11-08 on this Mac with the curve job's data: 19,311 properties loaded in 0.05 s; the
diff "which channels' DMX curve differs between Late 2026 2 and Christmas 2026" returns the 11
dimmers in 0.35 s.

```
python3 tools/showdb/showdb.py shows.db load-rt "Late 2026 2" docs/jobs/2026-11-08-dimmer-curves/rt-old-all.json
python3 tools/showdb/showdb.py shows.db load-rt "Christmas 2026" docs/jobs/2026-11-08-dimmer-curves/rt-now-1-900.json
python3 tools/showdb/showdb.py shows.db diff "Late 2026 2" "Christmas 2026" RTChannel DMXCURVE
```

## Next

1. Aaron decides how show files leave the console (stick, or SFTP read-only).
2. onPC bench of the plugin guard (alpha.6), then an onPC-only `ma3_snapshot` tool that writes
   every object with its properties as JSON Lines to the Mac's disk; time it on `Christmas 2026`.
3. Load every show on this Mac (20-plus files across versions) into the show database once; then
   cross-show questions (patch, configuration, programming) are queries.
