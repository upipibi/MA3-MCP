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
| (d) addresses | `socket.dns.getaddrinfo(socket.dns.gethostname())` lists every local IP (127.0.0.1, 127.0.0.2, 10.11.4.219 on this Mac); `Root().maNetSocket` has HOSTNAME, PRIMARYIP ("No Cable" here), INTERFACE, STATUS, SHOWFILE, VERSION, HOSTTYPE | bind = settings override, else the first IPv4 inside 10.11.0.0/20 from getaddrinfo, else 127.0.0.1; `SHOWFILE` gives the show name for `ma3_status` |
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

## Gate zero on the real console (Task 2, Aaron)

(to be filled when Aaron runs `spike/gate-zero`; see its README)
