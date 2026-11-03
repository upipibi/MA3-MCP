# MA3 MCP — design

**Date:** 2026-11-03
**Status:** approved by Aaron 2026-11-03 (summary approval; calls marked "Claude's call" are Claude's)
**Target:** grandMA3 light, software 2.5.1.1, Worship Center, production network 10.11.0.0/20, console address **10.11.3.10** (DHCP reservation)
**Repo (to be created):** `NorthwoodsCommunityChurch/avl-ma3-mcp`, topic `lighting-tools`, MIT

---

## 1. Intent

Aaron programs the grandMA3 light for weekend services. Much of his console time is not
programming but housekeeping: deleting last month's song sequences, creating this weekend's
from the Planning Center order, laying them onto executor pages, building groups for
newly patched multi-instance fixtures, keeping pools organized the way he likes them.

This project gives an AI model a **full window into the showfile and the console** so a
model can take a large housekeeping job ("remove the old song sequences, add the ones in
PCO, build the weekend pages, group the new fixtures by instance") and do it end to end
while Aaron spends the time programming.

It is a **bridge, not a feature set**. The model decides what to do with the access. The
two examples above are illustrations, not the scope.

## 2. Goals

1. Any MCP client on the production network can reach the console by address with
   nothing installed on the console side beyond one plugin, and nothing per client
   machine beyond an MCP entry. Clients today: Claude Code on Aaron's laptop, Hermes on
   the mini, local models on Puget. The bridge is model-agnostic.
2. **Complete visibility.** Every object the console holds is readable: its properties,
   its children, recursively, including patch, sub-fixtures, groups, presets, sequences,
   cues, cue parts, pages, executors, macros, tags, settings, users.
3. **Complete control**, gated. Any console command can be run and any property set.
   Arbitrary Lua is available but off by default.
4. The common housekeeping jobs are **fast**: one call returns the whole patch with
   instances, one call returns every sequence with where it lives on which page, one
   call returns the pages with their executor assignments.
5. The plugin is **safe to leave running** on the production console: it never blocks the
   UI, it never crashes the console, it refuses the specific calls known to hang MA3
   2.5.1, and nothing without the PIN can touch it.
6. Nothing is lost by accident: a backup copy of the show is saved before any job that
   deletes or rewrites, and the client-side workflow shows Aaron the plan before acting.

## 3. Non-goals

- Live playback control during a service. The tools can trigger playback (a command is a
  command) but the design optimizes for showfile administration between services.
- A polished tool for every console workflow (phasers, recipes, timecode). The generic
  tools reach them; dedicated helpers come later if a job needs them.
- Working over the lighting network, over the internet, or from off-site. Production
  network only.
- Running on onPC in production. onPC on Aaron's Mac is the **development bench** only.
- Replacing the console's own undo/oops. Backups are show-file copies, not per-command
  undo.

## 4. Anti-goals (what makes this a failure even if it works)

- A sequence with real programming deleted because a model decided it "looked like an old
  song". Hence: backup before destructive jobs, plan-then-confirm workflow, and the
  conventions file that tells models how to recognize what is and isn't a song.
- A stalled or crashed console. The plugin runs on the console's UI thread; one blocking
  call freezes the desk. Hence: non-blocking sockets, a yield every frame, per-request
  time budgets, and a list of refused calls.
- Anyone on the production network driving the console. Hence the PIN on every request
  and a visible list of who connected.
- The plugin silently running. It starts **off**; Aaron turns it on, and the pool button
  and window say so.

## 5. Constraints

| Constraint | Consequence |
| --- | --- |
| grandMA3 plugins are Lua 5.4 running **on the UI thread** as a coroutine | all I/O non-blocking; `coroutine.yield()` once per loop pass; never `accept()`/`receive()` without `settimeout(0)` |
| MA3 2.5 ships LuaSocket and a JSON library inside the console (`shared/resource/lib_plugins/requirements`) | no third-party code is redistributed; `require("socket")`, `require("json")` |
| The console has no SSH, no shared folders, no way to run a plugin automatically at show load | the plugin is started by a tap after loading the show; it ships off |
| A plugin cannot register a dockable window; it can build a floating overlay on a display that lives while the plugin runs | the window is an overlay the operator parks on a chosen display; the pool button is the always-visible state indicator |
| A command that opens a modal dialog on the plugin thread stalls the plugin until the dialog is dismissed | mutating commands use `/NoConfirmation`; show saves are queued with `CmdIndirect`; the window shows "stalled by dialog" if a request exceeds its budget |
| `ObjectList` over a page/executor range hangs the console's DataBase task on 2.5.1 (verified on onPC, [probe](https://github.com/bdstark/gma3-mcp/blob/main/docs/probes/objectlist-hang-macos-2.5.1.md)) | the plugin never passes a page/executor range or wildcard to `ObjectList`; the pages tool walks pages and executors one object at a time through the object tree |
| MCP's current spec (2026-07-28) is stateless: one HTTP POST per message, no handshake, headers `MCP-Protocol-Version`, `Mcp-Method`, `Mcp-Name`; older clients still send `initialize` | the server answers both styles (see §7.3) |
| Aaron: MCP talks only on the production network | the listener binds the console's production-network address, not all interfaces |
| Aaron: no API keys, no cloud | nothing in this project calls any model; it only serves one |
| Org standards: MIT, README/CREDITS/SECURITY, no secrets in git | the PIN lives on the console, never in the repo; client configs with the PIN live in OneDrive secrets or Claude Code's local scope |

## 6. Architecture

```
Claude Code (laptop)  ─┐
Hermes (edit-3 mini)  ─┼─ HTTP POST /mcp  ──►  grandMA3 light, prod NIC :9800
Puget model client    ─┘   Authorization: Bearer <PIN>      │
                                                            ▼
                                             Lua plugin "MA3 MCP" (one .lua + .xml)
                                             ├─ HTTP/1.1 server (LuaSocket, non-blocking)
                                             ├─ MCP JSON-RPC dispatcher (tools only)
                                             ├─ tool implementations over the MA3 Lua API
                                             ├─ overlay window + pool-button state
                                             └─ settings file (PIN, bind address, port, Lua on/off)
```

One plugin, one process (the console's), no companion service anywhere. The MCP server
**is** the plugin.

### 6.1 Why in the console rather than a bridge plus a server on a Mac

Every existing grandMA3 MCP project ([gma3-mcp](https://github.com/bdstark/gma3-mcp),
[MA3-MCP-Server](https://github.com/Pahegi/MA3-MCP-Server)) keeps a thin bridge in the
console and the MCP logic in a Node or Python process next to onPC, loopback only. That is
right for one person's onPC. Aaron's case is a shared console that several clients on
several machines should reach, with nothing to install or keep running per client. An
HTTP MCP endpoint on the console itself is the only design that gives "point at the
address and go". The cost is implementing HTTP and MCP JSON-RPC in Lua, which the
stateless 2026 spec makes small (one request, one JSON response, no streams).

gma3-mcp is MIT and its probe records on 2.5.1 are the best field evidence available; the
builder reads them for hazards and API behavior but **does not vendor its 440 KB plugin**.
This plugin stays small enough to read in one sitting.

## 7. Decisions (as decided)

### 7.1 Plugin lifecycle (Aaron)

- The plugin is imported into the Plugins pool once and saved with the show. It ships
  **off**.
- After loading the show, Aaron taps the plugin pool button once. That starts the server
  loop and opens the window.
- Tapping the pool button while running opens the window again if it was closed; it does
  not stop the server. Stopping is the window's Off button (or `Plugin "MA3 MCP" "off"`
  from the command line).
- Pool button appearance reflects state: grey "MCP OFF", green "MCP ON", amber
  "MCP STALLED" (a request has exceeded its time budget, most likely a dialog).
  (Claude's call: appearance via the plugin object's `Appearance`; builder verifies the
  property can be set from the plugin itself. If it cannot, the pool button shows state
  in its name only and the window is the stall indicator. The colored button is wanted,
  not required.)

### 7.2 Window (Aaron)

A floating overlay built from MA3's own UI classes, opened on a display Aaron picks (the
setting persists). Contents, top to bottom:

| Row | Content |
| --- | --- |
| Title bar | "MA3 MCP", close button (closing hides the window; the server keeps running) |
| State | big On/Off button; text "Listening on 10.11.x.x:9800" or "Off" |
| PIN | the 8-character PIN in large text, a **Regenerate** button, a note "paste as Bearer token" |
| Lua | toggle "Allow Lua execution" (default off, resets to off at every start) |
| Clients | the last 10 connections: IP, client name (from MCP clientInfo), last seen, call count, and a red "bad PIN" row for refused attempts |
| Backups | the last 5 backup saves this plugin made, with names |
| Display | "Show on display: 1 / 2 / 3 / ext" |

The PIN alphabet is `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no 0/O/1/I). It persists across
show loads and show files in the plugin's settings file (§7.6); Regenerate is the only
thing that changes it.

How the window is built (field evidence, builder verifies on onPC first):
`GetFocusDisplay().ScreenOverlay:Append('BaseInput')` is the root; `TitleBar` (with
`TitleButton` and `CloseButton` as its children), `UIObject` for text, `Button`,
`CheckBox`, `LineEdit`, `ScrollBox`, `UILayoutGrid` are confirmed classes; button clicks
reach Lua through the plugin's `signalTable` handlers; `dialog:WaitInit()` before
focusing; the plugin's loop keeps the window alive with `IsObjectValid(dialog)` and the
same per-pass `coroutine.yield` that services the socket. The plugin deletes only its own
`BaseInput` on close and never calls `ClearUIChildren` on the overlay (that would kill
the console's own popups). Opening on a chosen display: `GetDisplayByIndex(n).ScreenOverlay`
is the expected call; the builder confirms it and reads the forum thread
"ScreenOverlay vs ModalOverlay" before choosing.

**Risk and fallback (builder spikes this first):** a ScreenOverlay element may be
dismissed by the console when the operator taps elsewhere or changes view. If it does
not survive normal use on its display, the window becomes "opens on tap, closes on Esc or
its close button", and the pool button's color is the always-visible state. The server
behavior does not change either way.

### 7.3 Transport and protocol (Claude's call, informed by the spec read)

- HTTP/1.1 over TCP, port **9800**, bound to the console's production-network IPv4
  address. The window shows the address; a settings-file override exists for the rare
  case the console has more than one production address.
- One endpoint, `POST /mcp`. `GET` and `DELETE` get `405`. Responses are
  `Content-Type: application/json`; no SSE, no sessions, no `Mcp-Session-Id`.
- `Authorization: Bearer <PIN>` on every request. Missing or wrong: `401`, logged in the
  clients list as "bad PIN", and after 5 bad PINs from one IP in a minute, that IP is
  ignored for 5 minutes (no console-side lockout beyond that).
- `Origin` header, if present, must be empty or match the console's own address;
  otherwise `403` (spec MUST).
- The server implements MCP **2026-07-28 stateless** style: `server/discover`,
  `tools/list`, `tools/call`, with the `_meta` protocol-version check and the
  `Mcp-Method` / `Mcp-Name` header checks the spec requires. It **also** accepts the
  older `initialize` / `notifications/initialized` / `tools/list` / `tools/call` sequence
  with the `2025-06-18` protocol version so that Claude Code and other clients that
  have not moved yet still connect. Builder verifies on day one which style Claude Code
  actually sends (one `tcpdump`/log line) and treats the other as the compatibility
  path.
- Requests are served one at a time in arrival order. A second connection's request
  waits. Each request has a time budget (default 10 s); a request over budget returns a
  JSON-RPC error with `"state":"unknown"` and the window shows STALLED. **A timeout
  proves nothing about whether the command ran**; the client checks state before
  retrying. This rule also goes into the conventions file.
- Maximum request body 1 MB; maximum response 4 MB; larger reads must page.
- **Plain HTTP, deliberately.** LuaSocket in the console has no TLS. The PIN travels in
  clear on the production VLAN. The threat this design defends against is "a laptop on
  the prod network drives the console by accident or curiosity", not a hostile actor
  sniffing the VLAN; if that threat ever matters, the answer is network policy (an MSP
  ticket), not TLS in Lua. Flagged to Aaron as a decision in the approval summary.
- Long reads do not hold the UI: a bulk read walks its objects in slices and
  `coroutine.yield()`s between slices, so a 2000-fixture patch costs frames, not a
  freeze. The 10 s budget is per request; a read that cannot finish inside it returns
  the rows it has plus `next_offset`, never an error. (Claude's call; the builder picks
  the slice size by measuring on onPC with a show of Aaron's size.)

### 7.4 Tool surface (Claude's call; Aaron's examples drove it)

Every tool returns a JSON text content block. Names are stable API; descriptions tell the
model exactly what runs on the console.

**Status and safety**

| Tool | Does |
| --- | --- |
| `ma3_status` | show name, software version, user, session role, plugin version, Lua enabled, uptime, request count, last backup name |
| `ma3_backup` | `SaveShow "<stem>_mcp_<MMDD_HHMM>"` queued via `CmdIndirect`, then `SaveShow "<show>"` so the current name is unchanged; returns both names once the files exist (polls `DirList` across frames). `<stem>` is the show name cut to 16 characters so the whole name always fits the console's 31-character cap. The plugin **never deletes show files**; the window lists the last 5 backups and Aaron prunes old ones from the console's Backup menu. (Claude's call.) |
| `ma3_save` | `SaveShow` under the current name, no dialog |

**Generic tree (the "full window")**

| Tool | Does |
| --- | --- |
| `ma3_object` | `{address}` → the object's class, number, name and every property, with `schema:true` returning property names, types and enum values; handles resolved to addresses; `Tags` resolved to names |
| `ma3_children` | `{address, offset?, limit?}` → direct children (index, class, number, name) with paging; a `fields` list adds properties per child |
| `ma3_dump` | `{address, depth?}` → the console's own `Dump()` text for an object (what MA shows in the System Monitor) |
| `ma3_set` | `{address, property, value}` → `:Set()` and read-back; refuses `Tags` (use a command) |
| `ma3_command` | `{command, timeout_ms?}` → runs the command line text via `Cmd()`, returns the console's result string (required), the command-line feedback captured during the call (best effort: ship without it if the console offers no clean hook, and say so in the tool description), and the "noconfirmation" flag the plugin added if the command is one known to open a dialog |

Addresses are MA command-line object addresses (`Sequence 12`, `Sequence 12 Cue 3 Part 0`,
`Fixture 101.3`, `Page 2.5`, `Group 4`, `DataPool 1 Preset 4.1`). The plugin resolves them
with a single-object `ObjectList` or by walking the tree; **it refuses any address with
`Thru`, `+`, `*` on `Page`/`Executor`** (`[unsafe-range]`) and expands ranges on other pools
itself.

**Bulk reads (the fast path for housekeeping)**

| Tool | Returns |
| --- | --- |
| `ma3_fixtures` | the whole patch: fixture ID, name, fixture type, mode, patch (universe.address) and for each fixture its **sub-fixtures (instances)** with ID (`101.1`), name, and index, plus layer and class; optional filter by fixture-type name or ID range |
| `ma3_groups` | every group: number, name, appearance, tags, and the member fixture/sub-fixture IDs |
| `ma3_sequences` | every sequence: number, name, cue count, first and last cue names, tags, note, appearance, and **every executor it is assigned to** (`page.executor`, page name, executor label); optional `include_cues:true` adds the cue list per sequence |
| `ma3_pages` | every page: number, name; every assigned executor on it: executor number, label, assigned object address and name, key and fader functions. Built by walking `Page N` children one at a time (never a range). |
| `ma3_presets` | per preset pool: number, name, tags, appearance, fixture count (not values) |
| `ma3_macros` | every macro with its lines |

Bulk tools page at 500 rows and return `next_offset`.

**Writes beyond `ma3_command` and `ma3_set`**: none. Creating sequences, labeling,
assigning to executors, building groups, deleting pools are all MA commands, and the model
composes them. The conventions file and the client skill carry the recipes (`Store Group 7
"Spots L" /NoConfirmation` after `Fixture 101.1 + 102.1`, `Assign Sequence 12 At Page 3.201`,
and so on).

**Lua (gated)**

| Tool | Does |
| --- | --- |
| `ma3_lua` | `{code, timeout_ms?}` → runs the chunk on the plugin thread (a child coroutine has no console context), returns its return value JSON-encoded plus captured `Echo`/`Printf` output. Refused with a clear message unless the window toggle is on. The chunk sees the full console API and the standard libraries **except** `os.exit`, `os.execute`, `os.remove`, `os.rename` and the `io` library (nothing a model runs may kill the console process or touch its drive; `ma3_backup`/`ma3_save` are the file operations). A wall-clock deadline is enforced with a debug hook. (Claude's call.) |

### 7.5 Client side (Claude's call)

- **v1 client is Claude Code on Aaron's laptop.** Hermes and Puget clients are wanted but
  are not a v1 gate; they connect once their MCP client libraries are confirmed to speak
  one of the two supported styles. (Claude's call.)
- **Claude Code**: `claude mcp add --transport http ma3 http://<console-ip>:9800/mcp --header "Authorization: Bearer <PIN>"` with `--scope user` on Aaron's laptop. The PIN never goes in a repo.
- **Conventions file**: `docs/CONVENTIONS.md` in this repo, written from Aaron's description of how he wants sequences, pages, groups and names organized, and what distinguishes a song sequence from everything else. Every job starts by reading it. Per-job instructions override it.
- **Job skill**: `.claude/skills/ma3-housekeeping/SKILL.md`, the workflow a model follows for any job: read conventions → read the relevant bulk tools → write the plan (deletes, creates, assigns, as a list) → **stop and show Aaron** → on "go": `ma3_backup` → execute → re-read and verify → report what changed and the backup name. Also carries the hazards (timeout proves nothing; `/NoConfirmation`; never range Page/Executor).
- Hermes and Puget clients point at the same URL with the same header; nothing else.

### 7.6 Settings and files on the console (Claude's call)

- Plugin files: `MA3 MCP.lua` + `MA3 MCP.xml`, imported from a USB stick's
  `grandMA3/gma3_library/datapools/plugins/`.
- Settings: one small JSON file next to the plugin folder on the console's internal drive
  (`GetPath(Enums.PathType.PluginFiles)`-relative; builder confirms the writable location
  on a console): `{pin, port, bind, display, lua_default:false, clients:[...], backups:[...]}`.
  Not stored in the show file so a show file sent to someone does not carry the PIN.
- Log: a rolling text log in the console's temp path; the last 200 lines readable from
  `ma3_status {log:true}`.

### 7.7 Development and test (Claude's call)

- **Gate zero, before anything else is built**: prove a LuaSocket server can bind the
  console's production-network address on the real grandMA3 light and answer a
  connection from Aaron's laptop. This is a 10-line throwaway plugin (bind, accept with
  timeout 0, reply "hello", yield loop, stop after 60 s) that Aaron runs at a quiet time
  with Claude watching the result from the laptop. Nobody has published evidence of a
  non-loopback listener on console hardware; onPC evidence does not cover it. If it
  fails, the design falls back to the bridge-plus-server shape (§6.1) and comes back to
  Aaron before continuing.
- **Bench**: grandMA3 onPC 2.5.1 on Aaron's Mac (installed at
  `~/MALightingTechnology/gma3_2.5.1`). There the plugin binds 127.0.0.1. Claude Code on
  the same Mac is the first client.
- **Unit tests** run without the console: Homebrew Lua 5.4 + LuaSocket + the same json
  library, with a fake console API (`ObjectList`, `Cmd`, `DataPool`, `GetFocusDisplay`)
  so the HTTP parser, JSON-RPC dispatcher, auth, rate limit, address validator and every
  tool's shaping logic are tested. A `busted`-style runner is fine; keep it plain.
- **Live tests** against onPC on a disposable show: a script of read-only calls plus a
  write-and-restore sequence (create sequence 9500, label, assign to page 9, delete).
- **Console install**: a documented USB procedure plus a smoke test (`ma3_status`,
  `ma3_fixtures`, one `ma3_command Echo`). Aaron does the install; Claude never changes
  the production console without his word.
- Release: tagged zip of the two plugin files plus CONVENTIONS and the skill. No Sparkle
  (not a Mac app).

## 8. Left to the builder

- HTTP parser details (chunked bodies are not required; `Content-Length` only).
- The overlay's exact widget tree and sizes; the display picker's behavior when the
  chosen display is absent (fall back to display 1).
- How the plugin finds the production-network IP (LuaSocket `dns` on the hostname, or the
  console's network settings objects); expose the found list in the settings file.
- The internal request/response schema and error codes beyond what §7.3 fixes.
- Handle-to-address resolution strategy and its cache.
- Capture of command-line feedback during `ma3_command` (hooking the command line
  history versus `Cmd()` return only); document what is not capturable.
- The exact list of commands known to open dialogs and the `/NoConfirmation` policy.
- Rate limiting data structure; log rotation.

## 9. Hazards the builder must design around (field evidence, 2.5.1)

- `ObjectList` with a page/executor range or wildcard never returns and hangs the DataBase
  task; only relaunch recovers. Never do it. ([probe](https://github.com/bdstark/gma3-mcp/blob/main/docs/probes/objectlist-hang-macos-2.5.1.md))
- A modal dialog opened on the plugin thread stalls the plugin until dismissed on the
  console. `SaveShow "<new name>"` opens one; queue it with `CmdIndirect` so it lands on a
  later frame. ([probe](https://github.com/bdstark/gma3-mcp/blob/main/docs/probes/su-20-save-show-macos-2.5.1.md))
- Show names are cut to 32 characters by the console (manual says 31).
- A coroutine created from Lua has no console context: `ObjectList`, `DataPool`,
  `Programmer` return nothing there. Run tool code on the plugin's own thread.
- `obj:Get("Tags")` returns names by default and handles in the Edit role; names must be
  split on the last colon. `Set("Tags","")` is silently ignored. ([probe](https://github.com/bdstark/gma3-mcp/blob/main/docs/probes/su-21-tags-macos-2.5.1.md))
- Code at a plugin's top level runs at load time on the main task and must not yield or
  block; everything lives inside the returned function. ([forum](https://forum.malighting.com/forum/thread/7973-non-blocking-plugins/))

## 10. Open questions for Aaron

Only what changes what gets built:

1. ~~Is the console's production-network IP fixed?~~ **Answered 2026-11-03:** 10.11.3.10 by
   DHCP reservation. Clients are configured by address; no lookup step.
2. ~~OK to run the gate-zero socket test on the real console?~~ **Answered 2026-11-03:** yes.

Everything else the builder check raised was settled in this document and marked
"Claude's call": plain HTTP with the PIN (§7.3), the v1 client set (§7.5), best-effort
command feedback and button color (§7.1, §7.4), no backup deletion and the 16-character
stem (§7.4), sliced bulk reads (§7.3), and the Lua sandbox list (§7.4).

## 11. Sources

- [gma3-mcp](https://github.com/bdstark/gma3-mcp) (MIT): non-blocking LuaSocket server loop inside a plugin, 2.5.1 probe records
- [MA3-MCP-Server](https://github.com/Pahegi/MA3-MCP-Server): file-IPC alternative, not used
- [Lua in grandMA3 requirements](https://github.com/MayBeLinux/requirements_Lua-grandMA3): LuaSocket and json ship with the console
- [MA forum: non-blocking plugins](https://forum.malighting.com/forum/thread/7973-non-blocking-plugins/)
- [MA forum: UI element list](https://forum.malighting.com/forum/thread/69718-ui-element-list/), [LUA: UI](https://forum.malighting.com/forum/thread/5738-lua-ui/)
- [MA forum: ScreenOverlay vs ModalOverlay](https://forum.malighting.com/forum/thread/69324-custom-dialogs-screenoverlay-vs-modaloverlay/) (not yet read; builder reads it)
- [BakaCowpoke/GrandMA3-Lua](https://github.com/BakaCowpoke/GrandMA3-Lua): UI class dump code ("UI Reference")
- [MacTirney/GrandMA3-API-Documentation](https://github.com/MacTirney/GrandMA3-API-Documentation), [hossimo/GMA3Plugins](https://github.com/hossimo/GMA3Plugins): community Lua API references
- [MCP spec 2026-07-28, Streamable HTTP](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http)
- [grandMA3 manual 2.5](https://help.malighting.com/grandMA3/2.5/HTML/)

## 12. Addendum (2026-11-03, after approval; facts found while planning)

- **MA ships its own HTTP server library** in the console:
  `shared/resource/lib_plugins/requirements/gma3_webserver.lua`, with an example plugin
  (`examples/webserver_example`). It binds `socket.bind("*", port)`, runs its accept loop
  under `Timer(serverMain, 0, 1)` (a console task separate from the plugin's `Main`), and
  `coroutine.yield()`s per pass. This is MA's blessing of a listening socket inside a
  plugin. We do **not** use the library itself: its header parsing is case-sensitive
  (`Content-Length` only) and Node clients send lowercase headers, and its reads time out
  at 10 ms. We copy its lifecycle shape (`Timer` task for the server, `Main` for the
  window, `cleanup` on stop) and write our own parser.
- **Plugin entry contract** (from MA's examples): a component receives
  `pluginName, componentName, signalTable, my_handle` as `...`, returns `Main[, cleanup]`;
  `Main(display_handle, argument)` runs as a coroutine when the pool button is tapped or
  `Plugin "<name>" "<argument>"` is run.
- **Claude Code 2.1.295 traffic, captured** against a stub on 2026-11-03: it first POSTs
  `server/discover` with headers `mcp-method: server/discover`,
  `mcp-protocol-version: 2026-07-28` and the `_meta` client block; if that returns a
  JSON-RPC error it falls back to `initialize` (`protocolVersion` `2025-11-25`, no
  `mcp-method` header), `notifications/initialized` (expects 202), a `GET /mcp` for an
  event stream (405 is accepted), then `tools/list` and `tools/call` as plain POSTs.
  Headers arrive lowercase. The fallback flow completed a real tool call end to end
  against a 40-line stub, so the legacy path is the baseline and `server/discover` is the
  upgrade.
- Useful console API for the tools (community docs): `GetObjApiDescriptor()` prints the
  object-handle API (the spike records it), `GetSubfixture`/`GetSubfixtureCount`,
  `CreateUndo`/`CloseUndo` (one Oops for a whole job; `ma3_command` accepts an
  `undo_group` so a job can be undone from the console), `GetDisplayByIndex`,
  `GetDisplayCollect`, `Timer`, `HookObjectChange`, `GetPath(Enums.PathType.*)`.
- The console's Lua is 5.4-class (`string.split` is an MA extension; the bundle must not
  rely on it). Tests run on Homebrew `lua@5.4`.
