# Console atlas: every feature in the grandMA3 help, checked against what we have

Aaron, 2026-11-08: "study every single bit of the MA3 help site ... build a massive todo list,
every feature, menu, setting, toggle. Then compare that to-do list to what you have documented.
Check off the list what you have, and leave unchecked what you don't have. What you don't have
becomes our to-do list. And we update the MCP plugin to make sure you have access."

## What is here

| File | What |
| --- | --- |
| [CHECKLIST.md](CHECKLIST.md) | The list: 7,533 items from the help (version 2.5), grouped by manual chapter and page, each with a box and three marks. |
| `checklist.json` | The same items with the evidence for every mark (file that names it, property that reads it). |
| `verified.json` | Hand corrections to the automatic marks. Add to it whenever a session proves or disproves an item. |
| [topics/](topics/INDEX.md) | The study notes: one page per feature area, every chapter of the help, with evidence marks. Entry point for questions: the `ma3-console` skill. |
| [topics/keywords.md](topics/keywords.md) | Generated index of all 444 keywords (shortcut, help page id, covering page, plugin treatment): `python3 -I tools/atlas/keywords.py`. |

Rebuild after any change to our notes, the census or the corrections:

```
python3 tools/helpsite/fetch.py 2.5        # download the help into .cache/ma-help/2.5/ (git-ignored)
python3 tools/helpsite/extract.py 2.5      # pages -> inventory of items
python3 tools/atlas/checklist.py <census.json> 2.5
```

## How the list was made

1. **The whole help, not a sample.** The help's table of contents is embedded in its navigation
   script; `fetch.py` reads it and downloads all 1,574 pages (User Manual 1,109, device quick
   manuals 414, release notes 32, quick start 19). MA's text stays local, never committed.
2. **Every named thing becomes an item** (`extract.py`): each page (topic, command keyword, option
   keyword, Lua function), each heading, each bold setting name and its bold options, each
   on-screen button, each hardware key on the Keys pages, each command syntax line, each table row.
   20,365 raw items; after removing boilerplate headings, breadcrumbs, table cells that are sentences, generic buttons (OK,
   Cancel), the multilingual hardware quick manuals and the release-note bug lists: **7,533**.
3. **Three marks per item** (`checklist.py`), all automatic, all with evidence:
   - **N, named in our notes:** the item appears in our docs. Commands only count inside a code
     span shaped like a command; single plain words only inside code.
     The topic pages count (since 2026-11-08, evening); the generated keyword index does not.
   - **R, readable:** a console property with the same name exists in the class census (so
     `ma3_object` can read it), or the plugin itself calls the Lua function.
   - **P, proven:** used on the desk in a job record or a verified fact, on a line that does not
     report a failure.
   - A box is ticked when the item is P, or N and R together.
   - **M, MA's own example:** MA's Lua shipped with onPC uses it (see below). A lead to study, never
     a tick. 228 items have one.

## Where we stand (2026-11-08, evening)

Every chapter of the help is now studied into a topic page (`topics/INDEX.md`: 41 chapter groups,
the hardware chapters for the grandMA3 light and onPC only). The automatic marks after that study:

| Kind | Items | Named (N) | Ticked |
| --- | ---: | ---: | ---: |
| all | 7,533 | 2,204 | 441 |
| command keywords | 358 | 216 | 26 |
| option keywords | 86 | 22 | 0 |
| Lua functions | 152 | 129 | 27 |
| buttons | 1,528 | 756 | 113 |
| options | 1,137 | 480 | 168 |
| syntax lines | 709 | 0 | 0 |

The morning's figure was 168 ticked and the notes named far fewer items. The tick still needs proof
on the desk or a readable property in the census, and the census stopped at the freeze, so most
named items wait for the onPC census (R) and for jobs that use them (P). The name matcher is strict
on purpose (keywords in code only, no single plain words); syntax lines never match by name, so
"named" understates what the pages cover. `topics/keywords.md` shows every keyword with its
covering page: all but two (`/Ask`, `/Wrap`, whose help pages are empty).

**Limits of this version, stated plainly:**

- The marks are name matches. A wrong tick is possible (a plain word in our notes that means
  something else); `verified.json` holds the corrections made so far (two). A tick is a claim
  with evidence, not a guarantee: the evidence column says where to check.
- The **R** column comes from a census of the console's classes that stopped at the freeze on
  2026-11-08 (298 of the classes read). It runs again **on onPC only** (see the console safety
  rules in the project `CLAUDE.md`); R will grow then.
- Items are the help's names. Settings the help mentions only in prose (no bold name, no table)
  are not items yet.

## What the open items mean for the plugin

Grouped by what it would take to reach them, from the census and the help structure:

1. **Readable today, once mapped:** most settings and options are object properties. The work is
   the mapping (help setting to class and property), done on onPC, plus promoting proven branches
   to the console allow-list (`src/guard.lua`). Biggest win per session.
2. **User-profile settings and window state** (`ShowData > UserProfiles`): refused on the console
   since the guard; prove on onPC first.
3. **Not in the object tree:** Message Center contents, screen contents, running state beyond what
   Cue Display reads, DMX output values, RDM, network and session status, system monitor. Needs
   research per item (UI scrape, hooks, files, OSC).
4. **Files and drives:** importing library files from the stick by command (failed 2026-11-08),
   show files, exports. SFTP to the console is documented by MA; using it needs Aaron's word.
5. **Commands:** 334 keywords and 86 options never used on the desk. Each is proven on onPC first,
   then added to the facts file; dangerous ones are listed and refused.

## MA's own code: the best teacher we have (found 2026-11-08)

onPC installs MA's own Lua next to the software, readable, offline, no console involved:
`~/MALightingTechnology/gma3_2.5.1/shared/resource/`.

| Part | What it gives us |
| --- | --- |
| `lib_plugins/systemtests/db/` (408 tests) | MA's automated tests: exact commands and API calls MA uses for nearly every feature, with the expected results. 17,159 command strings; 196 of the 358 command keywords appear in them. |
| `lib_plugins/systemtests/gma3_api_meta.lua` | Typed signatures for 106 object-free Lua functions (including `CmdIndirectWait`, `HookObjectChange`, `RemoteCommand`). |
| `lib_menus/` | The console's menus are Lua: which object and property each window edits (the DMX curve pop-up showed that the curve value is `CurveIndex`). |
| `lib_dmxcurves/`, `lib_shapes/`, ... | MA's predefined library content. |

Use it before the help when the question is "what exactly does MA send": a feature's system test
is a worked, tested example. Facts learned from it carry the mark [M] (see
`topics/dmx-curves.md`). Never run these tests on the console; some delete objects (the curve test
deletes every curve in the show).

## Topic pages

Deep pages for features we work on, every statement marked with its evidence:

- [DMX curves](topics/dmx-curves.md) (2026-11-08)

## How this list gets worked

One chapter at a time, offline first, then on onPC: read the help pages and MA's system tests for
the chapter, write the topic page, map each item to its object and property or
command, prove it, record it (facts file, `verified.json` for corrections), rebuild the list. The
console is touched only for Aaron's jobs.
