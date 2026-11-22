---
name: ma3-console
description: Use for any question about how the grandMA3 console works or how to do something on it (a feature, setting, menu, command keyword, Lua function, object path or property), before planning any console job, and whenever command syntax is uncertain. Opens the studied topic page for that feature instead of guessing. Pairs with ma3-housekeeping, which runs the job itself.
---

# MA3 console knowledge

Aaron's goal: "I want you to know [the console] better than me." The knowledge lives in topic
pages, one per feature, every statement marked with its evidence. This skill is the map. Open only
the page the question needs.

## Rules that come first

1. **The console is never a bench.** No exploratory, looping or census reads against the console,
   ever. Unknown objects, properties and commands are tried on onPC on this Mac, after Aaron starts
   it. A walk of unknown objects froze the console mid-service on 2026-11-08. Full rules: project
   `CLAUDE.md`, "Console safety".
   The onPC bench is only a bench while it is **not in the console's session**: joining or being
   invited swaps show files between stations (`networking-and-sessions.md`). Check its Network
   menu shows Standalone or its own session first.
2. **Know the feature before the job.** If the feature's page is missing or its items are `[?]`,
   study first (offline), then plan. Never learn syntax by trying it on a loaded show.
3. **Say how sure you are.** In plans and answers, mark what rests on `[C]`/`[O]` proof and what is
   only `[D]`/`[M]`.

Evidence marks used on every page: **[D]** MA help · **[M]** MA's own Lua shipped with onPC ·
**[O]** proven on onPC · **[C]** proven on the console · **[?]** not proven.

## Where the answer is

| Question about | Open |
| --- | --- |
| Which features are studied, and their status | `docs/atlas/topics/INDEX.md` |
| A studied feature | `docs/atlas/topics/<slug>.md` (listed in the index) |
| Cues, sequences, tracking, cue timing, MIB, playback commands | `docs/atlas/topics/cues-and-sequences.md` |
| DMX curves, Parameter List, curve import from a stick | `docs/atlas/topics/dmx-curves.md` |
| Executors, pages, handles, executor configurations, fader functions | `docs/atlas/topics/executors-and-pages.md` |
| Timecode shows, slots, events, offsets, external timecode | `docs/atlas/topics/timecode.md` |
| Patch, IDs, addresses, multipatch, MVR, live patch, DMX sheet and tester, universes, stages, 3D, attributes | `docs/atlas/topics/patch.md` |
| Presets: modes, pools, embedded, recipe, MAgic, recast, extract, update | `docs/atlas/topics/presets.md` |
| Groups, selection grid by command, group masters | `docs/atlas/topics/groups.md` |
| Macros, variables, handles, prompts, `;` chains, properties by command | `docs/atlas/topics/macros.md` |
| Layouts, elements, canvas, layout encoder bar | `docs/atlas/topics/layouts.md` |
| Masters: selected, grand, speed, playback, timing; highlight, solo, blind; time control | `docs/atlas/topics/masters.md` |
| Show files: save, load, backups, history, drives, onPC start-up (RUNPLUGIN) | `docs/atlas/topics/show-files.md` |
| Fixture types: import, GDTF, editor, channels, geometries, ShareGlobal, XYZ rules | `docs/atlas/topics/fixture-types.md` |
| Data pools: structure, numbering (changed in 2.5), cross-pool references | `docs/atlas/topics/data-pools.md` |
| Phasers: steps, layers, editor, stomp, sync, phaser recipes | `docs/atlas/topics/phasers.md` |
| MAtricks, shuffle, selections, blocks, groups, wings, width | `docs/atlas/topics/matricks.md` |
| Recipes: cooking, priority rules, editor columns, edit recipe mode | `docs/atlas/topics/recipes.md` |
| Worlds and filters: access, rules, static vs dynamic, where they attach | `docs/atlas/topics/worlds-and-filters.md` |
| Selecting fixtures, selection grid commands, fixture sheet, programmer, blind, align, clone | `docs/atlas/topics/operate-fixtures.md` |
| XYZ, MArker fixtures, PSN tracking | `docs/atlas/topics/xyz.md` |
| Appearances, tags (Kill Instant / Delayed, Forward Commands) | `docs/atlas/topics/appearances-and-tags.md` |
| Agenda, timers, quickeys | `docs/atlas/topics/agenda-timers-quickeys.md` |
| Preview mode, sound input, sounds pool | `docs/atlas/topics/preview-and-sound.md` |
| Shapes, random generators, bitmaps (media mapped to fixtures) | `docs/atlas/topics/shapes-generators-bitmaps.md` |
| Labels (forbidden characters, bare `Label` hits a cue), notes, scribbles | `docs/atlas/topics/labels-notes-scribbles.md` |
| Images, symbols, gobos, videos, meshes; media size limits | `docs/atlas/topics/media-pools.md` |
| Windows, views, view buttons, main menu; pool Move / Insert / Copy / Lock / Delete behaviour | `docs/atlas/topics/windows-views-pools.md` |
| Command line (default keyword, shared `cd`), Oops (cleared by patch changes), screens, encoder bars, programmer keywords | `docs/atlas/topics/workspace-and-oops.md` |
| Users, rights, user profiles (Single Digit Input), screen configurations, ownership; plugin as its own user | `docs/atlas/topics/users-and-sessions.md` |
| Date/time, clock, System Info (frame timing), System Monitor, Info window, Message Center, status icons, Park | `docs/atlas/topics/system-and-messages.md` |
| Sessions (never join onPC to the console's session), network menu, keys, web remote, protocol ports, station commands | `docs/atlas/topics/networking-and-sessions.md` |
| DMX ports, Art-Net, sACN, refresh rate; the output priority ladder (tester, park, Super, Freeze, masters) | `docs/atlas/topics/dmx-io-and-priorities.md` |
| DC / MIDI / DMX remotes, OSC (`/cmd` runs any command), PSN, MVR-xchange, MSC, SendOSC / SendMIDI | `docs/atlas/topics/remote-in-out.md` |
| RDM (global and per-port switches, device window, matching to the patch) | `docs/atlas/topics/rdm.md` |
| Import / Export, AutoCreate, AutoStore, Partial Show Read (same version, no Oops, newer/older markers) | `docs/atlas/topics/show-creator-and-psr.md` |
| Local settings, software update, clean start, the Panic macro | `docs/atlas/topics/settings-update-troubleshooting.md` |
| Plugins in a show, Cmd vs CmdIndirect, the Lua API and which functions close known gaps | `docs/atlas/topics/lua-api.md` |
| Any keyword: shortcut, help page id, covering page, plugin treatment | `docs/atlas/topics/keywords.md` (regenerate: `python3 -I tools/atlas/keywords.py`) |
| Syntax rules, playback functions, layers, readouts, running objects, conditions, options | `docs/atlas/topics/keywords-more.md` |
| The grandMA3 light (screens, ports, 16,384 parameters), UPS, crash logs, Terminal app, onPC instances on this Mac | `docs/atlas/topics/hardware-and-onpc.md` |
| Whether an item of the help is known, readable, proven | `docs/atlas/CHECKLIST.md` (search the item), evidence in `checklist.json` |
| What the MCP cannot see or do yet, and the rule when a new miss turns up | `docs/GAPS.md` |
| Console facts that cost hours (plugin, yields, paths, the freeze) | `docs/research/2026-11-onpc-facts.md` |
| How Aaron's show is organised | `docs/CONVENTIONS.md`, `docs/PROGRAMMING-STYLE.md` |
| What the plugin may touch on the console | `src/guard.lua` (`M.RULES`), design in `docs/superpowers/specs/2026-11-08-console-guard-design.md` |
| Sorting data across shows | `docs/research/2026-11-08-fast-show-analysis.md`, `tools/showdb/showdb.py`, `tools/showfile/lineage.py` |

## Primary sources, offline

- The help, downloaded: `.cache/ma-help/2.5/` (refresh: `python3 tools/helpsite/fetch.py 2.5`).
  Print pages: `python3 tools/helpsite/text.py <page-id> [--grep word]`. Page ids are in
  `.cache/ma-help/2.5/toc.json`.
- MA's own Lua: `~/MALightingTechnology/gma3_2.5.1/shared/resource/`. System tests
  (`lib_plugins/systemtests/db/system_test_<feature>_*.lua`) show the exact commands MA sends and
  checks; `lib_plugins/systemtests/gma3_api_meta.lua` has typed signatures; `lib_menus/` shows which
  properties each window edits. Never run these tests: some delete every object of a kind.

## Studying a feature that has no page yet

1. `python3 tools/atlas/pack.py "<Chapter title>" --terms a,b,c` (chapter titles:
   `python3 tools/atlas/pack.py --list`). The pack lands in `.cache/atlas/packs/`.
2. Read the whole pack: help pages, linked keyword pages, MA test commands, release-note lines
   (2.2 to 2.5), our notes. Write the page as you read, so a compaction loses nothing.
3. Follow the template at the bottom of `docs/atlas/topics/INDEX.md`; end with "To bench on onPC"
   and "Plugin access". Update the index status.
4. Where MA's tests contradict the help, record both and mark the claim `[?]` until benched.

## After a job or a bench

Change the marks on the page (`[?]` to `[O]` or `[C]`), add hand corrections to
`docs/atlas/verified.json`, and rebuild the checklist:
`python3 tools/atlas/checklist.py .cache/census/console-2026-11-08.json 2.5`.
