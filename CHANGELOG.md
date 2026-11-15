# Changelog

## 0.2.0-alpha.6 (2026-11-08): console guard

Why: on 2026-11-08, during a Sunday service, a client script walked the console's whole object
tree with `ma3_object` reads. Around read 700 one read never returned. A plugin runs on the
console's screen thread, so the GUI froze while playback and timecode kept running, and the
console had to be restarted mid-service. A plugin cannot interrupt a console call that hangs, so
this release keeps the plugin away from anything not proven safe on a console, and makes sure a
stall can never repeat. Design: `docs/superpowers/specs/2026-11-08-console-guard-design.md`.

- **Allow-list on a console** (`src/guard.lua`): every tool that takes an address checks the
  object's class path before touching it. Allowed: show data (pools, patch, timecode, agenda;
  not the user-profile window settings), command history, drives, timecode slots, the show-name
  socket, and the list of Root's children. Everything else is refused with `[console-guard] ...
  explore it on onPC first`, before any property is read. A child listing or dump names refused
  children by class only. onPC is unrestricted (it is the bench).
- **Commands on a console** may address `Root 14` (show data) only.
- **Black-box journal** (`ma3_mcp_inflight.json` beside the settings): every call is recorded
  before it runs and marked done after. If the console stops during a call, the next start
  quarantines that address or call, prints it on the command line and refuses it from then on.
  `Plugin "MA3 MCP" "quarantine"` lists, `"quarantine clear"` empties (console only).
- **Rate cap on a console:** 8 requests a second, bursts of 16; over that the plugin answers at
  once without touching the console.
- **Bounded work:** `ma3_dump` stops at 2,000 objects and paces itself; a tool that keeps
  running Lua without a pause for 15 s is stopped (a hung console call cannot be); calls slower
  than 100 ms are logged with their target.
- **Commands are checked segment by segment.** The console runs several commands on one line
  separated by `;` (MA's own example macros do it), so `ma3_command` and `ma3_commands` now apply
  the refused-keyword check to every segment outside quotes, and refuse `Thru`, `+` or `*` on Page
  and Executor addresses inside commands too (it was only enforced on object addresses).
- **Refused keywords cover shortcuts and station commands.** The console accepts keyword
  shortcuts (`Lu` = Lua, `Sa` = SaveShow, `R` = Reboot), which slipped past the old full-name check.
  `ma3_command` now refuses a word that is the keyword, a documented alias, or a long-enough prefix
  of it, and the list grew from Lua and the show-file commands to the commands that restart, shut
  down or update a station (`Reboot`, `Restart`, `ShutDown`, `ReloadUI`, `ReloadAllPlugins`, the
  software commands), change the session (`JoinSession`, `LeaveSession`, `Invite`, `Dismiss`,
  `Disconnect`, `Reconnect`, `RemoteCommand`, `ChangeMulticastBase`, `NetworkSpeedTest`), log the
  operator out (`LogIn`, `Logout`), or open pop-ups and menus on the operator's screens (`Menu`,
  `Help`, `DumpLog`, `CopyCrashLog`, `Eject`). `Reboot`, `Restart` and `ShutDown` accept
  `/NoConfirmation`, so before this a PIN holder could restart the desk with one call. `Load` stays
  allowed. Found while studying the Networking chapter of the MA help.
- **Commands on a console stay in show data by keyword too.** Besides `Root <n>` addresses, the
  guard now refuses object keywords whose objects live outside show data: stations and the session
  (`Station`, `Console`, `onPC`, `NetworkNode`, `Session`, `Interface`, ...), the station's settings
  and displays (`StationSettings`, `Display`, `MessageCenter`), and the operator's user profile
  (`View`, `ViewButton`, `ScreenContent`, `ScreenConfiguration`, `UserProfile`,
  `CurrentUserProfile`, `EncoderBar`, `Camera`, `Readout`, `Keyboard`, the colour theme). Single
  quotes now count as quotes for these checks. onPC is unaffected.
- **A client cannot change the plugin's own switches through the console.** `ma3_command` used to
  accept `Plugin "MA3 MCP" "lua on"` (or `"quarantine clear"`, `"regen"`, `"off"`, a port), so a PIN
  holder could switch Lua on behind the window toggle. Now commands that name this plugin (by name
  or pool number, with the `Plugin` keyword or a shortcut) are refused, and while a client request
  runs the plugin refuses every argument except `status` and `quarantine`, whatever address reached
  it. The operator's window and command line at the desk work as before.
- **Parentheses outside quotes are refused.** In a command, `( ... )` makes the console ask the
  operator for the value in a text-input pop-up (MA help, Extended Command Line), which would leave
  the plugin waiting on a dialog. Names in quotes may contain parentheses.
- **`$variables` outside quotes are refused**: the console expands them into command text after
  the plugin's checks (a variable could hold `Reboot`). A `$` inside a quoted name is fine.
- **Lua starts off on a console, every time**, and the window switch holds for that session
  only. This reverses alpha.5's "on by default" for consoles: arbitrary code cannot be kept away
  from objects that can freeze the desk. onPC keeps the remembered setting.
- Includes alpha.5 (never installed on the console): settings path fix, no-header probes do not
  count toward the lockout.
- The client helper `tools/mcp_call.py` decodes replies that contain non-UTF-8 bytes, and takes
  `MA3_MCP_URL` / `MA3_MCP_PIN` to reach onPC without touching the console connector.

## 0.2.0-alpha.5 (2026-11-07)

- Fixed: the PIN appeared to change on every import (three times in two days). The settings
  file is found through `GetPath(Library)`, and after an import from a USB stick that path
  follows the selected drive, so a fresh settings file (new PIN) was written to the stick and
  the next restart read the internal file again. The settings path is now derived from the
  temp folder, which always points inside the installation; a settings file found under the
  library path is copied in once. The plugin logs the settings path at start.
- Lua execution is on by default and the switch is remembered across restarts (window
  checkbox or `Plugin "MA3 MCP" "lua off"`). The PIN is the key; command access through the
  plugin already reaches the whole show, and the Lua tool keeps its sandbox (no file system,
  no module loading).
- Requests with no `Authorization` header at all (browser probes, a client's OAuth discovery
  calls) no longer count toward the bad-PIN lockout. Wrong PINs still do.

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
