# onPC 2.5.1.1 facts for the MA3 MCP plugin

Recorded 2026-11-03 on Aaron's Mac, grandMA3 onPC 2.5.1.1 (macOS), show "Christmas 2026"
loaded, Admin user. Method: the throwaway `spike/onpc-facts` plugin (imported as Plugin 90,
started once, deleted afterwards; the show was not saved) plus one-line `Lua "..."` commands
typed into the command line. Raw outputs sit next to this file (`onpc-2.5.1.1-*.txt`).

| Item | Finding | Consequence |
| --- | --- | --- |
| (g) Lua version | `_VERSION = "Lua 5.5"`, `LuaSocket 3.0-rc1`; `json`, `lfs` load; `string.split` exists (MA extension) | tests run on Lua 5.5 primary, 5.4 as a check; bundle must not rely on `string.split` |
| (g) paths | `GetPath(Temp)` = `.../gma3_2.5.1/onpc/temp`; `GetPath(Library)` = `~/MALightingTechnology/gma3_library`; `GetPath(Showfiles)` = `.../shared/shows`; `PluginFiles`/`UserPlugins`/`Plugins` = nil; `my_handle.fullpath` = the imported `.lua` under `shared/resource/lib_plugins/ma3_mcp/` | settings file lives at `GetPath(Library) .. "/ma3_mcp_settings.json"` (persists across shows and software versions), log in Temp |
| (g) import path | `Import Plugin Library "MA3 MCP Facts.xml" At Plugin 90` found the files in `gma3_library/datapools/plugins/` and copied the Lua to `lib_plugins/ma3_mcp/` | install = copy to the library's `datapools/plugins/` (USB on a console), then Import |
| (d) addresses | `socket.dns.getaddrinfo(socket.dns.gethostname())` lists every local IP (127.0.0.1, 127.0.0.2, <laptop-ip> on this Mac); `Root().maNetSocket` has HOSTNAME, PRIMARYIP ("No Cable" here), INTERFACE, STATUS, SHOWFILE, VERSION, HOSTTYPE | bind = settings override, else the first IPv4 inside <production subnet> from getaddrinfo, else 127.0.0.1; `SHOWFILE` gives the show name for `ma3_status` |
| (h) `Cmd()` | returns `"OK"` on success, `"Object not found"` for a bad object and for an unknown keyword | `ma3_command` returns this string as `result`; it is the console's verdict, not ours |
| (b) object API | `GetObjApiDescriptor()` returns a table of 167 entries `{name, args, returns}` (saved in `onpc-2.5.1.1-objapi.txt`): `ToAddr(with_name, use_visible_addr)`, `Children()`, `Ptr(i)`, `Count()`, `PropertyCount()`, `PropertyName(i)`, `PropertyType(i)`, `Get(name)`, `Set(name, value)`, `Create/Append/Acquire/Delete(child_index[, undo])`, `Dump()`, `Export`, `Import`, `GetReferences`, `GetDependencies`, `Compare`, plus the UI object functions (`WaitInit`, `UIChildren`, `ClearUIChildren`, `OverlaySetCloseCallback`, `HookDelete`, `ShowModal`, `GetDisplay`) | the generic tools use exactly these names |
| (b) properties | `Fixture 1` has 110 properties incl. `NAME`, `FID`, `CID`, `IDTYPE`, `PATCH` ("1.001"), `FIXTURETYPE`, `MODE`, `NOTE`, `TAGS`, `APPEARANCE`, `POSX/Y/Z`, `ROTX/Y/Z`, `ISMULTIPATCH`, `MULTIPATCHCOUNT`; `h:Get(name)` returns **no value** (not nil) for empty ones, so always wrap as `(h:Get(n))` or `tostring((h:Get(n)))`; `PropertyType(i)` gives `String`, `Handle`, `UInt32`, `Double`, `Custom`, ... | `ma3_object {schema:true}` lists `{name, type}`; handle-typed values are rendered via `:ToAddr()` |
| patch tree | `Patch()` children: `Stages` (1), `FixtureTypes` (26), `Layers` (24), `Classes`, `DmxUniverses` (1024), `IDTypes` (12) ...; `Stage 1.2` = Fixtures (16 top-level entries); fixtures **nest**: `Fixture 88888` (Dimmer Rack) holds 478 children, `Fixture 2000` 401, `Fixture 1100` (Tornado) 22; `Fixture 1` (`Dimmer 1`, patch 1.001) is a child of `Fixture 88888`; `GetSubfixtureCount()` = 3413 | `ma3_fixtures` walks `Patch().Stages[1].Fixtures` recursively and reports `fid`, `cid`, `idtype`, `name`, `patch`, `fixture_type`, `mode`, and `children` per node; "instances" of a multi-instance fixture are its children with `IDTYPE`/`CID` set |
| (e) pool button | `Cmd('Set Plugin "X" Property "Appearance" "Appearance 1"')` returns OK; `plugin:Get("Appearance")` returns nil (no appearance named that way existed); `plugin:Set("Name", ...)` works | v1 shows state in the plugin's **name** (`MCP ON` / `MCP OFF` / `MCP STALLED`); an Appearance is applied only if the show has one named `MA3 MCP` (optional) |
| (c) Timer tasks | a function run by `Timer(fn, 0, 1)` has console context (`ObjectList`, `DataPool` work) and a Timer scheduled 3 s after `Main` returned still ran with context | the server loop runs as a Timer task; `Main` owns only the window and may return |
| (f) overlay | `GetFocusDisplay().ScreenOverlay:Append("BaseInput")` with `TitleBar`/`TitleButton`/`CloseButton`/`UIObject` children rendered a floating box and `IsObjectValid` stayed true for the full 45 s; `GetDisplayByIndex(1).ScreenOverlay` resolves (`Display 1.11`); `GetDisplayCollect()` returns an object (iterate with `:Children()`), not a plain table | overlay is viable; **not yet verified**: survival across a view change or a tap elsewhere (System Events clicks did not reach the GL window), so Task 11's live step checks it by hand and keeps the spec's fallback |
| typing | `osascript` keystrokes into the onPC command line execute commands; `Lua "<one line>"` with single quotes inside runs a chunk | live checks on onPC can be driven from this Mac without a hand on the keyboard |

## Live smoke (Task 10), 2026-11-03

Bundle v0.1.0 imported as Plugin 91 into onPC 2.5.1.1 (show "Christmas 2026", not saved), started
with `Plugin "MA3 MCP"`. Listener confirmed with `lsof` on 127.0.0.1:9800. Over curl: `ma3_status`
returned the show name and version; a request without the PIN got `401`; `ma3_sequences {limit:2}`
returned Sequence 1 "Thank The Lord" (26 cues, Page 6 executor 106 "Sept 13") and Sequence 2.
Claude Code 2.1.295 (`claude -p` with `--mcp-config`) connected on the modern 2026-07-28 path,
called `ma3_status`, `ma3_pages {limit:2}` and `ma3_command {command:"Echo hello from claude"}`
and answered: `Christmas 2026` / `Busking Base, 0 executors` / `OK`. onPC stayed responsive.

Things learned the hard way, now in the code and tests:

- The console calls the plugin's `cleanup` as soon as `Main` returns, so `Main` must stay alive
  (yield loop) while the server runs. The first live start listened for ~0 s and stopped.
- `package.loaded` is shared by every plugin and survives `ReloadAllPlugins`, so a bundle built on
  `package.preload` kept serving the first version's modules after every reload. The bundle now
  carries its own module table and `require` shim and never touches `package`.
- `ReloadAllPlugins` re-reads a component from `shared/resource/lib_plugins/<Path>/<FileName>`;
  `Import Plugin Library` reads from `gma3_library/datapools/plugins/`. The install target copies
  the Lua to both so a reload picks up new code without a re-import.
- rxi json encodes an empty table as `[]`; Claude Code refused `capabilities: {"tools": []}`.
  Every object MCP requires is kept non-empty or encoded by hand.
- Claude Code 2.1.295 validates `tools/list` against the 2026 schema: `ttlMs` without `cacheScope`
  is rejected (`expected "public"|"private"`). The server sends `cacheScope: "private"`.
- A plugin's `Echo`/`Printf` output is invisible from outside; the plugin writes a log to
  `GetPath(Temp)/ma3_mcp.log` and the bundle writes `ma3_mcp_load.txt` (`loaded` or `FAILED: ...`).

## Window (Task 11), 2026-11-03

Built from `BaseInput > TitleBar(TitleButton, CloseButton) + DialogFrame > UILayoutGrid` rows with
`UIObject`, `Button`, `CheckBox`; buttons wired with `PluginComponent = my_handle` and
`Clicked = "<signal name>"` to `signalTable` handlers (MA's own example pattern). Verified live on
onPC with real mouse events (`cliclick`): Regenerate changed the PIN in the settings file; the Lua
checkbox flipped `lua_enabled` as read back through `ma3_status`; Off stopped the listener; On
relaunched the plugin (`CmdIndirect('Plugin "MA3 MCP"')`) and it stayed up. **The overlay survived a
view change** (switched to the 3D view and back while the window stayed on top), so the spec's
fallback window mode is not needed. Screenshot: `docs/images/window-onpc.png`.

Layout facts: `obj[1][i]` addresses row i and `obj[2][i]` column i when setting `SizePolicy`/`Size`;
`UIObject` labels need `ContentDriven = "No"` and `TextAutoAdjust = "No"` to show full text in a
grid cell. After a tap on the window, keyboard input stays with the overlay until the command line
is tapped (typed commands silently go nowhere) — documented for the operator.

## Real console (grandMA3 light, 2.5.1.1), 2026-11-03

Gate zero was passed by the plugin itself, no separate spike needed. Aaron imported v0.1.0 from
a USB stick (`Import Plugin Library "MA3 MCP.xml" At Plugin 91`, `Plugin "MA3 MCP"`); the plugin
found the production address by itself and `ma3_status` from Aaron's laptop returned
`host_type: Console, address: <console-ip>:9800, show: Christmas 2026`. Claude Code 2.1.295 with
the server registered in user scope read status, three sequences with cue counts and a page.
First-run bug found and fixed on the console: the window did not redraw after Off (the redraw
lived in Main's loop, which Off ends); Off now redraws immediately.

Still unverified on the console: `ma3_backup` (saves the show, then copies the file), the
optional pool-button Appearance, and any write through `ma3_command`.

## Real console writes (stage-flip job), 2026-11-03

First write job on the grandMA3 light through the plugin (`docs/jobs/2026-11-03-stage-flip.md`).
Verified by re-reading after each phase:

- `ma3_backup` works on the console: `Christmas 2026_mcp_1103_2358` (6.7 MB) in a few seconds.
- `Store Sequence <n> "<name>"` on an empty programmer creates the sequence with one empty cue and
  the name applied (child count 3 = CueZero, Cue 1, OffCue). No Label pass needed.
- The console strips commas from object names through Store, Label and the object API `Set("NAME")`.
- `Delete Sequence 1 Thru 89` on 22 objects took 6 ms. Deleting a sequence removes its executor
  objects from every page (the executor shell does not survive; `Delete Page 2.106` then returns
  `Object not found`).
- `Delete Page <n>`, `Copy Page <a> At Page <b>` (into a free slot), `Label Page <n> "..."` and
  `Assign Sequence <s> At Page <n>.<e>` all return `OK` and do what they say. `Copy Page` carries
  every executor with its width, height, key and fader settings.
- A freshly assigned executor has HEIGHT 1, KEYPRESS `Temp`, FADER `Master`. Its lower half
  (`Page n.2xx`, class `Proxy`) exists once HEIGHT is 2 and lists no KEYPRESS/FADER in its property
  dump, yet `Set("KEYPRESS","Select")` and `Set("FADER","Master")` on it work and read back.
- `ma3_set` writes land outside any `ma3_command` undo group.
- The plugin stayed responsive through ~130 calls, including batches of 31 and 26 parallel requests.

## Plugin would not start after a console restart, 2026-11-05

Aaron: after powering the console on, the plugin would not start; deleting the pool slot and importing
again fixed it. Read from the running console: `Plugin 36.1` (ComponentLua) has `INSTREAM=false`,
`INSTALLED=false`, `ISRESOURCE=true`, `FILEEXISTS=false`, `FULLPATH=/home/ma/MALightingTechnology/
gma3_2.5.1/shared/resource/lib_plugins/ma3_mcp/MA3 MCP.lua`, with the source only in `FILECONTENT`
(memory). The 2.5 manual: InStream Yes = "the Lua code is saved in the show file and streamed in the
session"; No = "locally saved on the hard drive"; Installed Yes forces InStream No. So after a GUI
import from the stick the code is neither in the showfile nor on the console's disk, and a restart
leaves an empty component. The property cannot be changed on this component: `Set("INSTREAM", true)` reads
back false, `Set Plugin 36.1 Property "InStream" "Yes"` returns `Illegal property`, and `ISRESOURCE`
cannot be cleared (all tried 2026-11-05).

**Root cause: our XML.** `<UserPlugin Name=... Path="/ma3_mcp">` is the form MA's own library plugins
use (`shared/resource/lib_plugins/hw_test/hardware_test.xml` has `Path="/hw_test"`), so the console
makes the component a resource reference into `lib_plugins` and locks InStream. Aaron's Cue Display
plugin on the same console ships `<Plugin Name=...><ComponentLua ... /></Plugin>` with no `Path`, and
its install guide sets InStream so it "travels with the show and survives a console reboot". Fix in
0.2.0-alpha.3: the XML is now a plain `<Plugin>`; after import read the component and, if `INSTREAM`
is not already true, set it (property or plugin editor), then save the show. A first attempt at a
workaround (the plugin writing its own file into `lib_plugins` at start) was built and removed the
same day: it wrote into MA's resource folder to imitate what the proper setting does. Still unproven
until one console restart. On onPC the old form worked only because `make install-onpc` copies the
Lua into `lib_plugins`.

Also 2026-11-05: `Root 14.26` lists the console's 85 window types (WindowPluginPool, WindowSmartView,
WindowSpecialDialog, ...). None hosts plugin-drawn content, so a plugin UI can only be an overlay on a
display; the pool button in a Plugin pool window is the only part that docks in a view. The plugin XML
still says `Version="0.1.0.0"`; bump it with the Lua version.

## Agenda, fixture-type and layout writes proven on the console, 2026-11-05

- Agenda: `Store Agenda n "name"`, `Set Agenda n Property "StartDate" "DD.MM.YYYY"` / `"StartTime" "HH:MM:SS"`;
  events are points in time (no duration); pool names are forced unique (`#2` appended). Job: `docs/jobs/2026-11-05-agenda/`.
- Layout: `Assign Fixture <id[.instance]> At Layout n`, `Store Layout n.m` (empty element), `Set Layout n.m Property
  "PosX" -520`; visibility values are "Hidden"/"Visible". Job: `docs/jobs/2026-11-05-stick-delivery/portman-layout-plan.md`.
- `Set Layout n.<a> Thru <b> Property "Width" 10` works on a range of layout elements (1,926 commands for 960 elements ran in 5.8 s).
- Building a group with a 2D selection grid: `ClearSelection`, then per row `Grid 0/<row>` + `Fixture a Thru b`, then `Store Group n "name"` (600 fixtures on 12 rows, read back correct).
- Fixture types are only writable in the edit copy (`Root 14.10`, exists while the Patch menu is open); the rules MA
  applies before it allows XYZ on a DMX mode are in `docs/jobs/2026-11-05-tornado-xyz/FINDINGS.md`.
