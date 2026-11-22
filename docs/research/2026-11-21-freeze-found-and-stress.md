# The freeze of 2026-11-08 is found, and the console load test (2026-11-21)

Aaron, programming alone at the desk on a Saturday evening: "go ahead and do all the things you need
to do while I program ... the console saves every 5 minutes. I'd rather you stress test things now."

## The object that froze the console

**`ma3_object {"address": "Geometry "}`.** Reproduced on onPC (2.5.1.1, in the console's session,
plugin alpha.7) with the same census as 2026-11-08 (`tools/atlas/census.py`), this time writing each
address to a log before the call (`tools/atlas/census_logged.py`). It stopped at call 706; the
console census died between calls 701 and 750. The plugin's own journal on onPC named the same call.

- Where the address comes from: `ma3_children "FixtureType 1"`. The fixture type's children 1 to 4
  report path addresses (`FixtureType 1.1` .. `1.4`); the fifth, the geometry collection (class
  `Geometries`), reports **`Geometry `**: a bare keyword that does not lead back to the object.
- What happens: resolving it (`ObjectList("Geometry ")`, inside the plugin) does not return. onPC's
  process stays at low CPU with its main thread in its normal wait, so it is a wait that never ends,
  not a busy loop. The plugin answers nothing afterwards (more than ten minutes observed). The
  console was unaffected by onPC's stall.
- Not known: whether `ObjectList` blocks by itself or the property read after it does; whether the
  other collections of a fixture type that the census had not reached (`DMXModes`, ...) behave the
  same; whether onPC's screen was frozen for the operator as the console's was.

## The fix (built, 3,635 tests pass on 5.5 and 5.4; not on a station yet)

- `addr.check` refuses any address that starts with `Geometry` (`[unsafe-address]`), on every host.
- `ma3_children` no longer hands out an address it cannot vouch for: a child whose reported address
  does not start with a proven keyword gets its path below the parent (`FixtureType 1.5`), with the
  reported one kept as `reported_address`. A walk therefore never sends the dangerous address.
- On a console the guard resolves an address only when it starts with a keyword proven on onPC (the
  58 pool keywords the census resolved, plus the ones the tools use daily: `addr.PROVEN_KEYWORDS`).
- `ma3_children` lists a child that is not an object (`not_an_object`) instead of failing.

The census on onPC got through 705 calls and 387 classes: `.cache/census/onpc-2026-11-21.json`
(local). It continues once the fixed plugin runs on onPC.

## First calls on the console (alpha.7), all answered in under 0.12 s

`ma3_masters`, `ma3_programmer`, `ma3_ports`, `ma3_user`, `ma3_selection`, `ma3_values`, `ma3_dmx`
(the last four with `console_ok`), `ma3_playbacks`, `ma3_universes`, and `ma3_groups` with fixture
addresses. Same answers as onPC.

## Load test on the console (reads proven there, while Aaron programmed)

| Test | Result |
| --- | --- |
| Every bulk read back to back (135 sequences with cues, 17 pages, 123 groups, 58 presets, 31 macros, fixtures) | each in one request, 0.01 to 0.16 s |
| Export of Sequence 1 (4.1 MB) and Layout 1 (1.5 MB) | 0.53 s and 0.25 s |
| 240 single reads at 6 a second for 40 s | median 12 ms, 95 % under 18 ms, slowest 36 ms, none failed |
| 60 reads with no pause (over the cap of 8 a second) | 23 answered, 37 refused with `too many requests`; nothing else happened |
| 4 clients at once, 100 reads | 96 answered, 4 refused by the cap, slowest 63 ms |

No slow-call line in the plugin log. What Aaron saw at the desk during it: not reported yet.

## A stalled onPC is not free: it backed up the console's session

About fifteen minutes after onPC stalled, Aaron reported from the desk: "flow control is maxed out
right now". The stalled station was still a member of the session and had stopped taking the
console's data, so the console's flow-control indicator filled. I ended the three onPC processes
(TERM did nothing, KILL did); the console's plugin answered normally before and after. Whether the
indicator dropped once onPC was gone: Aaron's word needed.

What this corrects: "a read that hangs freezes onPC, not the desk" is half true. The desk's screen
keeps working, but a session member that stops answering loads the session. Rules from it:

- Exploration on onPC that can hang (a census, a first call on an unknown class) runs with onPC
  **outside** the console's session, or with someone ready to end onPC at once.
- If onPC's plugin stops answering, end onPC straight away (`pkill -KILL -f "grandMA3 onPC"`); do not
  wait to see if it recovers.
- This is the price of keeping onPC in the session for the MCP user: jobs through onPC use proven
  calls only, the same as on the console.

## After alpha.8 was loaded (22:00, both stations)

- `ma3_object "Geometry "` is refused at once on onPC (`[unsafe-address]`).
- The same object reads fine by its path: `ma3_object "FixtureType 1.5"` gives class `Geometries`
  (it still reports its address as `Geometry `), and `ma3_children` lists its geometries with path
  addresses (`FixtureType 1.5.1`, reported `Geometry 1`). So the hang is in resolving the address
  `Geometry `, not in reading the object.
- **The census ran to the end on onPC: 2,099 calls, 629 classes, 36 s, no call slower than 1 s, no
  hang** (`.cache/census/onpc-2026-11-21-full.json`, local; `tools/atlas/census_logged.py`, which
  ends onPC by itself if a call stalls). 243 classes are new against the console census that died at
  390. Eight reads answered `object not found`: addresses the console reports that do not lead back
  (`Sequence 1.-1`, `UserProfile 1.1.1.3.1`, `Fixture 100002.44`, `Shape 1.1.2.3`); harmless.
- The census samples three objects per class. It proves every class is readable on onPC, not every
  object, and not the console.
- Checklist rebuilt from it: 811 of 7,533 help items covered (441 before).
