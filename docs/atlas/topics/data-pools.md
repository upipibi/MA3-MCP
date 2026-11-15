# Data pools: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Data Pools", 1 page, 3 keyword pages), MA's
datapool tests and our reads. Study pack: `python3 tools/atlas/pack.py "Data Pools" --terms datapool`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What it is [D]

- A data pool is the parent of most show pools; every new show has one (Default, `DataPool 1`); more
  can be stored, each a complete new set of pools (for example one per act or per artist).
- Children, by destination number in 2.5: 1 Worlds, 2 Filters, 3.1 Bitmaps, 3.2 Generators - Random,
  **4 Shapes** (moved from 16 in 2.5), 5 Preset Pools, 6 Groups, 7 Sequences, 8 Plugins, 9 Macros,
  10 Quickeys, 11 MAtricks, 12 Executor Configurations, 13 Pages, 14 Layouts, 15 Timecodes, 16 Timers.
  **The 2.5 renumbering breaks macros or Lua that address data pool children by number**; names are
  safe. Our tools address by keyword (`Sequence 12`, `Page 1.106`) and by class, not by number [C].
- On Aaron's console the data pool is `Root 14.14.1` (`ShowData > DataPools > Pool`) [C].
- **Data pool 128 is reserved for Preview.**
- Pool windows link to the selected data pool or a fixed one (window settings); menus have a DataPool
  button in the title bar.

## Operations [D]

| Command | Use |
| --- | --- |
| `Store DataPool n` | new data pool |
| `Copy DataPool a At b` | full copy; objects in the copy may still reference the source pool (presets used by copied cues) |
| `Edit DataPool n` | editor with the whole numbered structure (`1.7.1` = data pool 1, sequences, sequence 1) |
| `Assign DataPool 1 Sequence 1 At Page 1.201` | use an object of another data pool from this one |
| `Delete DataPool n` | **deletes everything inside** |
| `Select DataPool n`, `DataPool n` | switch the selected data pool |

## Traps

- 2.5.1.0 fixed `Goto DataPool 1 Page 1.205 Cue 5` going to the wrong cue [D].
- 2.5 fixed a crash when Lua `FromAddr('14.14.1.12.1.101')` addressed executors by numeric path [D]:
  numeric paths shift between versions; prefer keywords.

## What we have proven

- Every job ran in data pool 1 [C]. No second data pool exists on Aaron's show [?: confirm with a read
  of `Root 14.14`].

## Plugin access today, and gaps

- The bulk tools read the default data pool. Gap: no tool parameter for another data pool [?].
