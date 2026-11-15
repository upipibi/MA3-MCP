# Plugins and the Lua API: what we know, how sure we are, what to use next

Written 2026-11-08 from the MA help 2.5 (chapter "Plugins", 159 pages: 129 object-free and 20 object
functions documented), MA's shipped `gma3_api_meta.lua` (106 object-free functions with signatures),
our onPC facts (`docs/research/2026-11-onpc-facts.md`), and the plugin's own code (26 of the
documented functions in use). Study pack: `python3 tools/atlas/pack.py "Plugins" --terms lua,plugin`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Plugins in a show [D, C]

- Plugin pool objects with settings Name, Scribble, Appearance, Tags, Note, Lock, Author, Version,
  Path, **UserRights** (needed rights to run it); one or more **ComponentLua** rows: FileName,
  FilePath, Installed (refresh from the library file; sets InStream to No), IsResource (internal
  library, not stored or streamed), **InStream** (code saved in the show and streamed in a session),
  SyntaxError, Full Path, File Exists. `ReloadAllPlugins` re-reads library files.
- **Our rule from the console**: the plugin XML stays plain `<Plugin>` + bare `<ComponentLua Name
  FileName>`; `Installed` / `LoadOnDemand` make it a library resource that is not stored in the show
  and does not survive a restart [C: `docs/INSTALL-CONSOLE.md`].
- Running: tap, `Plugin n` (first component), `Plugin n.<component>`, executors and view buttons;
  `Plugin "MA3 MCP" "quarantine"` passes an argument [C].
- Export writes the XML plus `.lua` files for InStream components (base64 inside the XML otherwise);
  import needs all files in `gma3_library/datapools/plugins`.
- The help says Lua 5.4.8; **onPC 2.5.1.1 reports `Lua 5.5`** and we test on 5.5 with 5.4 as a check
  [O]. `HelpLua` writes `grandMA3_lua_functions.txt` to the library (the plugin refuses it: it is
  meant for the operator). MA does not support plugins and warns they may need rewriting on updates.

## How commands run [D, C]

- `Cmd(string[, undo])`: runs in the **Lua task, synchronously**, returns "OK", "Syntax Error" or
  "Illegal Command"; this is what `ma3_command` uses [C].
- `CmdIndirect(string[, undo[, target]])`: queued to the **Main task**, asynchronous, returns
  nothing; the target can be a display (`GetDisplayByIndex(2)`). `CmdIndirectWait`: Main task,
  synchronous for the command but not blocking Lua.
- `CreateUndo(name)` / `CloseUndo(handle)`: one Oops for everything passed the handle [C].
- Plugin Lua runs on the screen thread: a hung API call freezes the GUI (2026-11-08) [C].

## Functions that close gaps found in this study [D; all ? until benched on onPC]

| Gap (topic page) | Function |
| --- | --- |
| Refused keywords rely on our shortcut table (`networking-and-sessions.md`) | `GetTokenName(short)` returns the console's own full keyword for a shortcut: verify the table on onPC, then use it as a second check |
| A command that opens a dialog stalls the plugin | `GetTopModal()` returns the top modal pop-up, if any: check after a command, report instead of waiting |
| Guard bench needs a frame-time measure (`system-and-messages.md`) | `GetDebugFPS()` (frames per second) |
| "Where is this preset used" without a pop-up (`presets.md`) | `obj:GetReferences()`, `obj:GetDependencies()` |
| User and global variables (`macros.md`) | `GetVar(UserVars(), name)`, `GetVar(GlobalVars(), name)` |
| Unsaved changes before a job (`show-files.md`) | `NeedShowSave()`, `GetShowFileStatus()` ("NoShow", "ShowLoaded", "ShowSaving", ...) |
| Which cue is live, what the selection is (`operate-fixtures.md`) | `GetCurrentCue()`, `SelectedSequence()`, `Selection()`, `SelectionCount()`, `GetExecutor(n)` |
| What a fixture outputs right now (`dmx-io-and-priorities.md`) | `GetDMXValue(address[, universe, percent])`, `GetDMXUniverse(n[, percent])` (nil when the universe is not granted) |
| Polling for changes (Cue Display scans at 5 Hz) | `HookObjectChange(fn, object, plugin)` calls back on change; `Unhook`, `DumpAllHooks` |

Each is a read, but none is proven on the console; the guard's rule applies: onPC first, then a
code change that lists it as allowed.

## Other documented functions worth knowing [D]

- Identity and host: `HostType()`, `HostSubType()`, `HostOS()`, `SerialNumber()`, `BuildDetails()`,
  `ReleaseType()`, `ConfigTable()`, `Time()` (seconds since start).
- Handles and addresses: `Addr`, `AddrNative`, `FromAddr`, `ToAddr`, `HandleToInt/Str`,
  `IntToHandle`, `StrToHandle`, `IsObjectValid`, `ObjectList(selection string)`, `ClassExists`,
  `IsClassDerivedFrom`, `GetClassDerivationLevel`.
- Show objects: `Root()`, `ShowData()`, `ShowSettings()`, `DataPool()`, `Patch()`, `MasterPool()`,
  `DeviceConfiguration()`, `CurrentUser()`, `CurrentProfile()`, `CurrentEnvironment()`,
  `CurrentExecPage()`, `CurrentScreenConfig()`, `Programmer()`, `ProgrammerPart()`,
  `SelectedLayout/Timecode/Timer/Feature()`, `FixtureType()` (only inside the patch).
- Patch and channels: `AddFixtures(table)`, `CreateMultiPatch`, `CheckDMXCollision`,
  `CheckFIDCollision`, `GetSubfixture(n)`, `GetSubfixtureCount()`, `FirstDmxModeFixture`,
  `GetRTChannel(s)`, `GetRTChannelCount`, `GetUIChannels`, `GetUIChannelIndex`, `GetAttributeCount`,
  `GetAttributeIndex`, `GetAttributeByUIChannel`, `GetChannelFunction(Index)`, `GetPresetData`.
- Files: `GetPath`, `GetPathOverrideFor`, `GetPathSeparator`, `GetPathType`, `DirList`, `FileExists`,
  `Export` / `ExportCSV` / `ExportJson` / `Import` (Lua tables to and from files).
- User interface (**all open pop-ups or draw on the operator's screens; never from the plugin's
  request path**): `MessageBox`, `Confirm`, `TextInput`, progress bars (`StartProgress`,
  `SetProgress...`, `StopProgress`), `DrawPointer`, `CloseAllOverlays`, `GetTopOverlay`,
  `GetUIObjectAtPosition`, `SetLED`, `GetButton`, `KeyboardObj`, `MouseObj`, `TouchObj`.
- Object methods: `Children`, `Count`, `Ptr`, `Get`, `Set`, `Dump`, `Export`, `Import`, `GetClass`,
  `GetChildClass`, `GetFaderText`, `SetFader`, `GetUIEditor`, `GetUISettings`, `HasActivePlayback`
  (deprecated for `IsRunningPlayback` in 2.4).
- `Timer(fn, seconds, count[, done[, handle]])` repeats a function; `DeskLocked()`; `Echo`, `ErrEcho`
  (System Monitor), `Printf`, `ErrPrintf` (command line history).

## Plugin access today, and gaps

- In use: Children, CloseUndo, Cmd, CmdIndirect, Count, CreateUndo, DataPool, DirList, Echo, Export,
  Get, GetClass, GetDisplayByIndex, GetFocusDisplay, GetPath, GetSubfixture, HostType, IsObjectValid,
  ObjectList, Patch, Printf, Ptr, Root, Set, ShowData, Timer [C: code].
- Next candidates, in order of value: GetReferences, GetTokenName, GetTopModal, NeedShowSave,
  GetDebugFPS, GetVar; each needs an onPC bench and a guard entry first.
