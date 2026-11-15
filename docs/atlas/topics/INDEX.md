# Feature study: every chapter of the grandMA3 manual

Aaron, 2026-11-08, after the DMX curves page: "that studying of the curve import is what I need you
to do for EVERY SINGLE FEATURE."

Each feature gets a topic page like [dmx-curves.md](dmx-curves.md): what it is, where it lives in
the object tree (classes, properties), every setting and what it does, the commands (help syntax
and MA's own worked examples), the Lua functions, safe procedures for the jobs Aaron does, traps
and MA bugs from the release notes, what we have proven, and what is left to bench on onPC. Every
statement carries its evidence: [D] help, [M] MA's shipped Lua, [O] onPC, [C] console, [?] not proven.

**Method, per chapter (offline, nothing touches the console):**

1. `python3 tools/atlas/pack.py "<Chapter>" --terms a,b,c` builds the study pack in
   `.cache/atlas/packs/` (help pages, linked keyword pages, MA system tests and menu code,
   release-note paragraphs, our notes).
2. Read the whole pack. Write `docs/atlas/topics/<slug>.md` from the template below.
3. Add the onPC bench items to the page; update this index's status; rebuild the checklist.
4. When onPC is up: bench the open items, change [?] to [O], and record facts.

**Status:** `-` not started · `studied` page written from the help and MA's code · `benched` onPC
items run · `proven` used on the console in a job.

## Tier 1: Aaron's weekly work

| Chapter | Pages | Status | Topic page |
| --- | ---: | --- | --- |
| Cues and Sequences | 19 | studied | [cues-and-sequences.md](cues-and-sequences.md) |
| Executors (incl. pages) | 5 | studied | [executors-and-pages.md](executors-and-pages.md) |
| Timecode Show | 11 | studied | [timecode.md](timecode.md) |
| Patch and Fixture Setup | 21 | studied | [patch.md](patch.md), [dmx-curves.md](dmx-curves.md) |
| Presets | 6 | studied | [presets.md](presets.md) |
| Groups | 5 | studied | [groups.md](groups.md) |
| Layouts | 8 | studied | [layouts.md](layouts.md) |
| Macros | 10 | studied | [macros.md](macros.md) |
| Masters | 8 | studied | [masters.md](masters.md) |
| Show File Handling | 7 | studied | [show-files.md](show-files.md) |
| Fixture Types | 13 | studied | [fixture-types.md](fixture-types.md) |
| Data Pools | 1 | studied | [data-pools.md](data-pools.md) |

## Tier 2: programming tools

| Chapter | Pages | Status | Topic page |
| --- | ---: | --- | --- |
| Phasers | 6 | studied | [phasers.md](phasers.md) |
| MAtricks and Shuffle | 7 | studied | [matricks.md](matricks.md) |
| Recipes | 4 | studied | [recipes.md](recipes.md) |
| Shapes, Generator - Random, Bitmap | 3 | studied | [shapes-generators-bitmaps.md](shapes-generators-bitmaps.md) |
| Worlds and Filters | 5 | studied | [worlds-and-filters.md](worlds-and-filters.md) |
| Operate Fixtures | 23 | studied | [operate-fixtures.md](operate-fixtures.md) |
| XYZ | 3 | studied | [xyz.md](xyz.md) |
| Appearances | 4 | studied | [appearances-and-tags.md](appearances-and-tags.md) |
| Tags | 1 | studied | [appearances-and-tags.md](appearances-and-tags.md) |
| Agenda | 5 | studied | [agenda-timers-quickeys.md](agenda-timers-quickeys.md) |
| Timers | 3 | studied | [agenda-timers-quickeys.md](agenda-timers-quickeys.md) |
| Quickeys | 4 | studied | [agenda-timers-quickeys.md](agenda-timers-quickeys.md) |
| Preview | 1 | studied | [preview-and-sound.md](preview-and-sound.md) |
| Sound | 3 | studied | [preview-and-sound.md](preview-and-sound.md) |
| Notes, Scribbles, Label Objects, Symbols, Images, Gobos, Meshes, Videos | 15 | studied | [labels-notes-scribbles.md](labels-notes-scribbles.md), [media-pools.md](media-pools.md) |

## Tier 3: the system around the show

| Chapter | Pages | Status | Topic page |
| --- | ---: | --- | --- |
| Windows, Views, and Menus | 16 | studied | [windows-views-pools.md](windows-views-pools.md) |
| Workspace | 31 | studied | [workspace-and-oops.md](workspace-and-oops.md) |
| Single User and Multi User Systems | 5 | studied | [users-and-sessions.md](users-and-sessions.md) |
| System (incl. Message Center) | 10 | studied | [system-and-messages.md](system-and-messages.md) |
| Networking | 17 | studied | [networking-and-sessions.md](networking-and-sessions.md) |
| DMX In and Out | 7 | studied | [dmx-io-and-priorities.md](dmx-io-and-priorities.md) |
| Remote In and Out (OSC, MIDI, DMX, PSN, MVR, MSC) | 16 | studied | [remote-in-out.md](remote-in-out.md) |
| RDM | 1 | studied | [rdm.md](rdm.md) |
| Show Creator | 7 | studied | [show-creator-and-psr.md](show-creator-and-psr.md) |
| File Management | 3 | studied | [show-files.md](show-files.md) (folders section) |
| Plugins (Lua API: 152 functions) | 159 | studied | [lua-api.md](lua-api.md) |
| Command Syntax and Keywords (358 + 86) | 451 | studied | [keywords.md](keywords.md) (generated index), [keywords-more.md](keywords-more.md) |
| Local Settings, Update the Software, Troubleshooting | 15 | studied | [settings-update-troubleshooting.md](settings-update-troubleshooting.md) |
| Control Other MA Devices, grandMA3 onPC, Device Overview, First Steps, System Overview | 157 | studied (grandMA3 light and onPC only) | [hardware-and-onpc.md](hardware-and-onpc.md) |

## Template for a topic page

```
# <Feature>: what we know, how sure we are, how to do the work
Written <date>. Evidence marks: [D] [M] [O] [C] [?].
## What it is (and how Aaron uses it, from PROGRAMMING-STYLE / CONVENTIONS)
## Where it lives in the object tree (classes, addresses, properties)
## Settings (table: setting, property, values, what it does)
## Commands (syntax, MA's worked examples, what we have used)
## Lua (functions and object methods that matter)
## Procedures (the jobs, step by step, with read-back and undo)
## Traps (MA bugs and limits from the release notes; our own mistakes)
## What we have proven
## To bench on onPC
## Plugin access (what the plugin can read or do today; gaps)
```
