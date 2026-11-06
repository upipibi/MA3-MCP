# Changelog

## 0.2.0-alpha.4 (2026-11-06)

- Fixed: `ma3_sequences` returned no rows, `partial: true` and `next_offset: 0` on a show with 17
  pages, so paging never advanced. The tools yielded once per 50 pool slots visited, empty slots
  included, and on the console one bare `coroutine.yield()` costs a whole frame, about 31 ms. The
  Page pool has 9,999 slots and every page 390, so the executor index `ma3_sequences` builds first
  cost 6.2 s for the empty pool walk plus 0.24 s per page: 10.5 s at 17 pages, the whole budget.
  Measured on a grandMA3 light: `ma3_children` on `Page` took 6.14 s for all slots (17 rows),
  0.64 s for 999 empty slots, 0.06 s for the first five pages.
- Yields are now spent by elapsed time, never by count (`console.pace`, 10 ms of work per slice).
  Walking empty slots no longer yields at all, which makes every bulk read faster: `ma3_pages`,
  `ma3_sequences`, `ma3_groups`, `ma3_macros`, `ma3_presets`, `ma3_fixtures`, `ma3_children`,
  `ma3_cue_timing`, `ma3_timecode`, `ma3_history`.
- A paged read always returns at least one row before it may report `partial`, so `next_offset`
  always advances.
- `ma3_sequences`: the row budget starts after the executor index is built; `executors: false`
  skips the page walk and leaves the field out.
- `ma3_pages` honours the time budget (`partial` can now be true), `{page: n}` reads that page
  only, and `offset` still counts pages.
- Not yet verified on the console: the timings after the change, and that 10 ms slices leave the
  desk responsive during a long read.

## 0.2.0-alpha.3 (2026-11-05)

- The plugin XML is now a plain user plugin (`<Plugin>` with one `ComponentLua`, no `Path`).
  The old form (`<UserPlugin ... Path="/ma3_mcp">`) is the one MA uses for its built-in library
  plugins, so the console treated ours as a disk resource: after a GUI import from a stick the
  code was neither in the showfile nor on the console disk (`FILEEXISTS=false`, InStream locked
  to No), and the plugin was empty after a console restart. As a user plugin its code can be
  stored in the showfile (InStream).
- Verified on the console the same day: after a GUI import the component reads `INSTREAM=true`,
  `ISRESOURCE=false`, `FULLPATH=<Showfile>` with no manual step, and `ma3_commands` ran its first
  real jobs (283 commands for one layout, 89 of them in a quarter of a second).
- `tools/mcp_call.py`: calls one tool on the console's server with the URL and PIN saved in Claude
  Code's config, for when a session's own connector is stale after a PIN change.

## 0.2.0-alpha.2 (2026-11-04)

- `ma3_export` strips the embedded copies of referenced presets and appearances by default
  (`strip_dependencies:false` keeps them), reports `raw_bytes` / `stripped_bytes`, default cap
  8 MB. A 40-cue song went from 8.8 MB to a fraction of that.
- Verified on a grandMA3 light 2.5.1.1: `ma3_export`, `ma3_history` (the console exposes no
  command-line text lines; `lines_supported` false), `ma3_timecode`, sequence filters.

## 0.2.0-alpha.1 (2026-11-04)

- `ma3_commands`: a list of commands in one request, validated as a whole before anything is
  sent, one undo group, stops at the first non-OK result unless told otherwise. Cuts a 77-command
  job from 77 round trips to a handful.
- `ma3_cue_timing`, `ma3_timecode`, `ma3_history`, `ma3_export` (deep reads; export is the path
  to cue contents and is unverified on the console until the first run).
- Filters: `ma3_sequences {from,to,name}`, `ma3_pages {page}`, `ma3_fixtures {summary}`.
- Facts from the first write job folded into the server instructions: cue numbers are
  thousandths, address cues as `Sequence n Cue 1`.

## 0.1.0-alpha.1 (2026-11-03)

First version. One Lua plugin that serves MCP over HTTP from inside the console: PIN
authentication with lockout, generic object tools (status, object, children, dump, set,
command, undo groups), bulk reads (fixtures with instances, groups with members,
sequences with executor assignments, pages, presets, macros), backup and save, gated Lua,
and a window with On/Off, PIN, Lua toggle, clients and backups. Verified live on
grandMA3 onPC 2.5.1.1 and on a grandMA3 light (2.5.1.1) with Claude Code 2.1.295. Alpha: the
backup tool and the optional pool-button Appearance have not been exercised on console hardware yet.
