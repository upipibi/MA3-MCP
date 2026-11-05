# MA3 MCP — project context

A grandMA3 Lua plugin that makes the grandMA3 light an MCP server. Public personal repo:
https://github.com/upipibi/MA3-MCP (Aaron's, not the Northwoods org). State as of 2026-11-05:
v0.2.0-alpha.3 runs on the console, stored in the show file `Christmas 2026`, and has done real jobs
(stage flip, Portman layout, agenda).

**This repo is public.** No console or network addresses, no PIN, no private paths in anything that
gets committed. Raw data read from Aaron's shows (per-show reports, exports, his stage plot, the
production schedule) stays local: see the "raw show data" block in `.gitignore`.

## Read first

- `README.md`: what it is, tools, install, build.
- `docs/CONVENTIONS.md`: how Aaron's showfile is organized. Every job reads it. No open questions.
- `.claude/skills/ma3-housekeeping/SKILL.md`: the job workflow (orient, plan, show Aaron, go, backup,
  execute in one undo group, verify, report).
- `docs/research/2026-11-onpc-facts.md`: console facts that cost hours. Read before changing the plugin.
- `docs/PROGRAMMING-STYLE.md`: how Aaron programs (cues, timing, pages, groups, presets, timecode),
  learned from his show files. Per-show reports are local only, in `docs/research/shows/`.
- `docs/jobs/`: one record per job (table below).
- `docs/superpowers/specs/...` and `plans/...`: the design and the plan it was built from.

## Where things stand (2026-11-05)

| Thing | State |
| --- | --- |
| Plugin on the console | 0.2.0-alpha.3, `Plugin 36`, lives in the show file (`INSTREAM` true). Unproven: one console restart with the USB stick out. |
| Cue Display plugin (`../MA3 Cue Display/`) | Fixed and re-imported as `Plugin 38`, verified. Details in that project's CLAUDE.md. |
| Stage model | Imported from Capture as MVR; Aaron switched its 3D selection off himself. |
| Portman layout | 90 elements + box in Layout 1, verified. |
| Agenda | 15 entries for the Christmas 2026 run (`Agenda 14-28`). |
| Tornado XYZ | NOT possible for a five-head bar as one fixture. Waiting on Aaron: leave it off, or split each bar into single-head fixtures (new session). |
| Cue Display timecode + fades | Design paused mid-brainstorm (section below). |

Job records:

| Folder | What |
| --- | --- |
| `docs/jobs/2026-11-03-stage-flip.md` | Song pool cleared and rebuilt from Planning Center, November pages, Weekend Base. |
| `docs/jobs/2026-11-05-stick-delivery/` | Plugin alpha.3, Cue Display, stage MVR (`strip_layers.py`), Portman layout (`portman-layout-plan.md`, `plan_portmans.py`, `run_portmans.py`). `README.md` is the day's log. |
| `docs/jobs/2026-11-05-tornado-xyz/` | `FINDINGS.md`: the rules MA applies before it allows XYZ on a DMX mode, and why the Tornado cannot have it. Scripts for the scratch-copy build. |
| `docs/jobs/2026-11-05-agenda/` | The agenda entries and the proven Agenda syntax. |

## Running a job

- The console server is registered in Claude Code user scope as `ma3` (tools `mcp__ma3__ma3_*`).
  The PIN lives in the plugin window on the console and in Claude Code's config, never in this repo.
- If a session's own connector is stale (PIN changed, "Needs Auth" in the VS Code panel), do NOT use
  the panel's Authenticate button: it starts an OAuth sign-in the plugin does not have, every try
  counts as a wrong PIN, and five in a minute lock this machine out for five minutes. After
  `claude mcp remove ma3 -s user` + `claude mcp add ... --header "Authorization: Bearer <PIN>"`, a
  running VS Code session still holds the old PIN until the window is reloaded. Until then,
  `python3 tools/mcp_call.py <tool> '<json args>'` calls the same MCP tools with the saved PIN
  (`--list` shows tools and inputs). That is how the 2026-11-05 jobs after the PIN change were run.
- Planning Center comes from Weekend Rundown's read-only `pco-mcp`, wired here as `planning_center`
  through `.mcp.json` (gitignored: absolute paths). Tools: `list_service_types`, `list_plans`,
  `get_plan`, `get_plan_items`, ... Service type: Sunday services. Songs = items PCO types as song.
- Writes go through `ma3_command` / `ma3_commands` only after Aaron says go, with `ma3_backup` first.
  `ma3_commands` (up to 200 commands per request, one undo group) is the normal way to run a job:
  89 commands take about a quarter of a second. `ma3_set` is not part of an undo group.
- Big results (`ma3_export`, `ma3_dump`, `ma3_fixtures` with children) go to a file and are read
  with a script, never inline. On an old show `ma3_fixtures` also returns hundreds of fixture types.
- Fixture types can only be changed while the Patch menu is open on the console: the editable copy
  is `Root 14.10` (empty otherwise); `FixtureType n` on the live patch ignores writes silently.

## Developing the plugin

- `make test` (Lua 5.5, the console's version; `LUAV=5.4` as a check), `make build`, `make release`.
- onPC bench on this Mac: `make install-onpc`, then in onPC `ReloadAllPlugins` and `Plugin "MA3 MCP"`.
  onPC settings/PIN: `~/MALightingTechnology/gma3_library/ma3_mcp_settings.json`; log in
  `gma3_2.5.1/onpc/temp/ma3_mcp.log`.
- Console update, Aaron's way (no commands): copy `dist/MA3 MCP.lua` + `.xml` to the MA3 USB stick's
  `grandMA3/gma3_library/datapools/plugins/` (verify md5, eject), he deletes the old plugin slot,
  imports `MA3 MCP.xml` through the GUI and starts it. The plugin XML must stay in the plain
  `<Plugin>` + bare `<ComponentLua Name FileName>` form: `UserPlugin` + `Path`, or `Installed` /
  `LoadOnDemand` on the component, make the console treat it as a library resource that is not
  stored in the show file and does not survive a restart. Full guide: `docs/INSTALL-CONSOLE.md`.
- Never drive onPC or anything else on this Mac with keystrokes or mouse automation while Aaron is
  using it (2026-11-03: two batches landed in his VS Code window). Use HTTP calls or ask him.

## Reading an old show (information-dump recipe)

Aaron loads the show on the console, then imports the plugin through the GUI (edit an empty plugin
slot, Import, pick `MA3 MCP.xml` from the stick) and starts it; the PIN persists. Then: `ma3_status`,
the six bulk reads (`ma3_sequences {include_cues:true}` included); the big ones land in tool-result
files, copy them to the scratchpad as `fixtures.json`, `groups.json`, `sequences.json`, `pages.json`
and run `python3 -I tools/show_digest.py <dir> "<show>" docs/research/shows/<slug>.md`. Add by hand:
presets, macros, `ma3_children` on `Appearance`, `View`, `Layout`, `Timecode`, `MAtricks`, `World`.
Deep reads: `ma3_cue_timing {sequence}`, `ma3_timecode {timecode}`, `ma3_history`, and
`ma3_export {address}` (lands in a file; analyse with `tools/cue_values.py <xml> <fixtures.json>`,
never read it inline). Sparse pools: `ma3_groups {offset: n-1, limit: 1}` reads group n alone.
Fold new patterns into `docs/PROGRAMMING-STYLE.md`. Do not save an old show.

## Paused 2026-11-05: Cue Display feature design (brainstorm, nothing built)

Aaron wants the Cue Display page (`../MA3 Cue Display/`) to also show timecode and fades. Decided so
far, in his words: show timecode slot 1 and slot 2; "the fades for any cue running"; one frame at a
fixed size so a single OBS crop never changes; inside it the boxes pack tight from the centre;
"ideally it's just song and key sequences" (my default for that: running sequences numbered 1-89,
configurable). Read on the console: `TimecodeSlot n` has `TIMESTRING` and `TIME` (live update
unverified, nothing was rolling); cue fades are in the cue's Part 0. I had offered browser mockups;
he said "push pause on this". Resume by offering the mockups again. Brainstorming skill gate: no
product code until he approves the description. Version bump is his call.

## Tornado XYZ (waiting on Aaron)

Read `docs/jobs/2026-11-05-tornado-xyz/FINDINGS.md`. Short version: MA allows XYZ on a DMX mode only
with Pan on the outer axis, a tilt axis with zero rotation relative to it, and the tilt pivot on the
pan axis. A faithful re-description of the Tornado passed all of that on a scratch copy, but MA then
creates the XYZ controls for one pan/tilt pair per fixture only, so a five-head bar gets XYZ on one
head. Aaron's options: leave it off, or split each bar into five single-head fixtures plus a bar
fixture (two new fixture types, full re-patch, groups/layouts/presets rebuilt). His Tornado groups
are recorded locally in `groups-before/` in that folder.

## Open items

- Aaron asked 2026-11-05: could the MCP plugin be its own user, so Claude does not share his command
  line and screens? Not researched. Known: the plugin's commands run on the command line of the
  user who started it (`Root 20.1` lists `Cmdline 1` = User 5, `Cmdline 2` = User 2). Idea to test:
  a dedicated user/profile and the plugin started from a second station logged in as that user.

- The PIN was different after Aaron went Christmas 2026 -> Christmas 2025 -> back on 2026-11-05 (he
  said it is fine; `last_backup` was also empty, so the settings file was written fresh). Worth a
  look when next in the plugin: write settings to a temp file and rename; never regenerate when the
  file exists but fails to parse; do not count requests without an Authorization header toward the
  lockout; answer OAuth discovery/registration paths with a plain 404.

- Verified on the console: `ma3_commands` (2026-11-05, Portman layout), `ma3_export`, `ma3_history`
  (`lines_supported` is false on 2.5.1.1: the console does not expose command-line text lines),
  `ma3_timecode`, and the `from`/`to` filter on `ma3_sequences`.

- The optional pool-button Appearance is unverified on console hardware (`ma3_backup` is verified).
- Hardening to check (pre-existing, found in the 2026-11-05 security pass, unverified): `ma3_command`
  refuses `Lua`/`SaveShow`... by the FIRST word only. If the console accepts several commands on one
  line separated by `;`, a PIN holder could chain past that refusal. Test on onPC; if so, refuse `;`
  outside quotes or check every segment.
- `ma3_set` writes are not part of a `ma3_command` undo group; a job that sets executor
  properties should say so in its report. Idea: let `ma3_set` take `undo_group` too.
- Review minors deferred (see git history of the fix pass): no 4 MB response cap, `ma3_pages`
  ignores the time budget, bad-PIN rows not red, undo groups never closed by a client stay open.
- Future idea Aaron mentioned: build a simple song sequence from his existing programming. Not a job yet.
