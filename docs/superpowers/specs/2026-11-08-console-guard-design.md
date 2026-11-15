# Console guard: the plugin must not be able to freeze the console

Status: approved by Aaron 2026-11-08 ("console guard approved"), built as 0.2.0-alpha.6; onPC bench next, then the stick.

## Why

2026-11-08, Sunday, during a service: a client script ("class census") walked the console's whole
object tree with `ma3_object` reads, about 14 a second. Around read 700 one read never returned.
A plugin runs on the console's screen thread, so the GUI froze while playback and timecode kept
running; the only way out was a restart in the middle of the service.

Aaron, the same hour: "We can NOT allow the MCP plugin to behave in a way that allows it to crash
the console" and "YOU CAN NOT DO THIS AGAIN".

What is known about the hang (from the census file the script saved every 50 reads):

- It happened between reads 701 and 750, on one of the objects queued at read 700: 92 classes,
  all outside the show's pools except user-profile settings. The likeliest are the screen and
  input-device objects (`Root > GraphicsRoot > PultCollect > Pult > Devices > Keyboard / Touch /
  MouseCollect / GestureManager`, `... > DisplayCollect > Display`), the library file list
  (`Root > Temp > Cmdlines > Cmdline > Library > File`), and network discovery
  (`Root > DeviceConfigurations > DMXProtocols > ArtNet/sACN > ... Node`).
- The plugin wrote nothing that names the request in flight, so the exact object is unknown.
- Nothing in the show data the jobs use (pools, patch, timecode, history) was involved: those
  were read hundreds of times this week without trouble.

## Hard truth this design accepts

A Lua plugin cannot interrupt a call into the console's own code. If a console API call never
returns, nothing in the plugin can stop it. So the guard works by never making calls that are not
proven safe on the console, by never repeating a call that once hung, and by keeping its load on
the screen thread low. It cannot make an unproven call safe.

## Goals

1. On the console, the plugin touches only objects proven safe there. Everything else is refused
   with a clear message, before any console API call is made on it.
2. If the console ever freezes or restarts during a request again, the next start names the
   request and refuses it from then on, automatically.
3. No client can drive the console hard: request rate is capped on the console.
4. No single tool can run long on the screen thread: every walk is bounded and paced.
5. onPC on the Mac is the bench: no allow-list there (journal and caps still on), so unknown
   objects are explored there first and then promoted to the console allow-list by a code change.

## Non-goals

- Making Lua execution (`ma3_lua`) safe on the console. Arbitrary code cannot be guarded; see the
  decision below.
- Guarding what Aaron does by hand on the console.

## The pieces

### 1. Allow-list by ancestry (`src/guard.lua`, console only)

Every handle a tool is about to read, write or export is checked by walking its parents to `Root`
(a few `Parent()` and `GetClass()` calls, both proven safe). The class path must match an allowed
branch:

| Allowed branch (class path from Root) | Why it is proven |
| --- | --- |
| `ShowData` and everything below it, except `ShowData > UserProfiles` | pools, patch, timecode, agenda, appearances: every job this week |
| `ShowData > UserProfiles > UserProfile` and its direct properties only | ownership/profile reads (not its window settings) |
| `Temp > Cmdlines > Cmdline` and `... > Undos > Undo` | `ma3_history`, proven 2026-11-05 and -08 |
| `Temp > DriveCollect > Drive` | read 2026-11-08 during the curve job |
| `TimecodeSlots > TCSlot` | read every frame by Cue Display since 2026-11-05 |
| `MAnetSocket` (the object itself) | `ma3_status` show name |
| `Root` (the object itself, and the list of its children) | census read it; class names only |

Refused on the console, with `[console-guard] <class path> is not proven safe on the console;
explore it on onPC first`: everything else, notably `GraphicsRoot`, `DeviceConfigurations`,
`UsbNotifier`, `StationSettings`, `Temp > ... > Library > File`, `ShowData > UserProfiles >
... > TemporaryWindowSettings` and the rest of the user-profile tree.

Promotion: a branch joins the allow-list only by a code change after it has been read on onPC
with the journal on and without a stall, recorded in `docs/research/2026-11-onpc-facts.md`.

Where it applies: `ma3_object`, `ma3_children` (the parent, and the children listed are skipped
if refused), `ma3_dump` (each node), `ma3_set`, `ma3_export`, `ma3_cue_timing`, `ma3_timecode`.
The bulk tools only walk `ShowData` pools and need no per-object check.

`ma3_command` on the console: a command that names `Root <n>` with `n` other than 14 (ShowData)
is refused; the other hazard rules stay (`Thru`/`+`/`*` on pages, refused first words).

Addendum 2026-11-08 (during the feature study, before alpha.6 reached the console): the refused
first words are checked with MA's shortcuts in mind (a word is refused when it is the keyword, a
documented alias, or a prefix at least as long as MA's shortcut), and the list covers the commands
that restart, shut down or update a station, change the session, log the operator out, or open
menus and help pop-ups (`REFUSED_KEYWORDS` in `src/tools/generic.lua`; the reasons are in the
changelog). The check applies on every host, onPC included: none of these belong in a job.
Same day, from the Command Syntax chapter: object keywords reach objects outside show data without
naming `Root <n>` (`Set StationSettings ...`, `Store View 3`, `Set CurrentUserProfile ...`), so on a
console `allow_command` also refuses the keywords in `M.OUTSIDE_SHOWDATA_KEYWORDS`, matched with
shortcuts, outside single or double quotes. Not covered: `ChangeDestination` by number from Root
(`cd 19`), which needs destination tracking; jobs use `cd` only into show-data pools.

Same day: the plugin's own arguments (`lua on`, `quarantine clear`, `regen`, `off`, port, bind) were
reachable through `ma3_command` (`Plugin "MA3 MCP" "lua on"`), which defeated "Lua is switched only
at the desk" and "a client cannot clear the quarantine". Fixed twice: `ma3_command` refuses commands
naming this plugin (`calls_self`), and `Main` refuses those arguments while a client request runs
(`ctx.in_request`), which also covers addresses the command check cannot see. Unproven on onPC:
that a `Plugin` command from `Cmd` re-enters `Main` synchronously (the second layer assumes it; if it
is queued instead, the first layer still holds for the name and number forms).

### 2. Black box journal (`ma3_mcp_inflight.json`, beside the settings file)

- Before a tool handler runs: write `{tool, address or args summary, started}` to the journal.
- After the guard resolves the target: rewrite it with the class path.
- After the handler returns (or errors): write `{done: true}`.
- Walkers (`ma3_children`, `ma3_dump`, bulk tools) update the target at most once per pacing slice.
- At plugin start: if the journal holds an entry without `done`, the plugin adds its address and
  class path to `quarantine` in the settings file, logs it, and prints on the console command
  line: `MA3 MCP: the last session stopped during <tool> <address>; it is now refused`.
- Quarantined addresses and class paths are refused on any host, before resolve where possible.
  `Plugin "MA3 MCP" "quarantine"` lists them; `"quarantine clear"` empties the list. Both only
  from the console (a client cannot clear it).

Cost: two small file writes per request (well under a millisecond on the console's SSD).

### 3. Rate cap (console only)

A token bucket: 8 requests per second sustained, bursts of 16. Over the cap the plugin answers at
once with `[console-guard] too many requests; slow down` (HTTP 200, tool error) without touching
the console. Measured jobs this week ran at up to 27 reads a second over the LAN; they will take
about three times longer, which is acceptable. onPC: no cap.

### 4. Bounded walks

- `ma3_dump`: at most 2,000 nodes, paced like the other walks, `truncated: true` past that.
- Every tool handler runs under a wall-clock hook (Lua instruction count hook): a handler that
  spends more than 15 s in Lua code is stopped with an error. It cannot stop a hung console call,
  only runaway Lua.
- Requests slower than 100 ms are logged with tool, target and duration, so slow objects are
  visible before they become a problem.

### 5. Lua execution on the console (decision for Aaron)

`ma3_lua` runs any code with the full console API; no allow-list can apply to it. alpha.5 made
Lua on by default at his request (2026-11-07). The guard build changes that on the console: Lua
starts off on the console every time and can be switched on from the plugin window for the
current session only; on onPC it keeps the remembered setting. If he wants Lua on by default on
the console anyway, that is one setting.

## Tests

Fake console gains a host type switch and parent chains. Tests: allow-list accepts every proven
branch and refuses `GraphicsRoot`, `Library > File`, `UserProfile > TemporaryWindowSettings`;
children of an allowed parent skip refused children; onPC allows everything; journal written
before the handler and marked done after, including when the handler errors; a journal left
without `done` quarantines its address at the next start and the address is then refused; rate
cap refuses the 17th request inside a second on the console and never on onPC; dump stops at
2,000 nodes; `ma3_command` refuses `Root 19` on the console and allows `Root 14.9.9.5`; Lua is
off at start on the console even when the settings say on.

## Bench plan (onPC only, Aaron starts it)

1. Install the guard build on onPC, load `Christmas 2026`, start the plugin.
2. Run the census on onPC with the journal on, one branch at a time, starting with the suspects,
   to find the object that hangs (onPC may freeze; that costs a restart of onPC only).
3. Record the result; keep the class refused on the console forever if it hangs.
4. Only then put the build on the stick for the console.
