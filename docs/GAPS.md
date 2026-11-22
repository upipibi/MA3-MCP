# Gap ledger: what the MCP cannot see or do yet

Aaron, 2026-11-21: "the MCP needs to see EVERYTHING, and we keep running into issues where it CANT ...
if you find something that you can't do with the MCP, that not only means the MCP needs update, but
that also needs to trigger a further dive into what else might be missing ... we've run into some
pretty BASIC STUFF that the MCP can't do."

This file is the standing answer. It lists every known miss, basic things first, with what each one
waits on. Every session that meets a gap updates it.

## The rule

1. **A miss is a gap.** When a job or a question meets something the MCP cannot read or do, say
   "gap", write it here the same session, and build it. A workaround may finish the job; it never
   closes the gap.
2. **A gap triggers a sweep.** The same session, check the neighbours: every other read and write of
   the same feature (its topic page's "Plugin access" section) and of the same operator view (what
   the desk shows next to it). Each miss found goes in this file. One gap found means the area was
   never checked, so check the area.
3. **Basic first.** Anything an operator sees at a glance or does daily outranks everything else.
4. **Never a desk check for Aaron.** If the plugin cannot read it, the answer is a bench and a build
   (`mcp-must-see-everything` memory). Console safety still holds: prove on onPC, then tests and a
   guard rule, then one first call on the desk outside a service.
5. **A gap closes on the desk**, not on onPC and not in the test suite. Until then its state says
   where it is stuck.

How a gap moves: found > benched on onPC > tool with tests > guard rule > first call on the desk > closed.

## What holds the most back (four things)

| Blocker | What it holds back | Whose move |
| --- | --- | --- |
| ~~The new reads are not on the console.~~ alpha.8 runs on the console and on onPC since 2026-11-21, and every new read has answered on both. | Was: everything built since 2026-11-19. | Done. |
| **Benched reads are not tools yet.** Lua has been on in onPC's window since 2026-11-21 and the first bench ran (below). | Selection, DMX output, fixture values, fader levels as tools; sACN / Art-Net and messages still to bench. | Mine. |
| ~~The plugin shares Aaron's user.~~ Solved 2026-11-21: the `MCP` user on onPC. | Was: any job that selects, sets values or stores. | Done. |
| ~~The object that froze the desk.~~ Found and fixed 2026-11-21 (the address `Geometry `; alpha.8 on both stations). The census then completed on onPC: 629 classes, no hang. | Was: every unread branch. Now each of the 629 classes has an example address and its property list (`.cache/census/onpc-2026-11-21-full.json`). | Mine: turn the census into reads, branch by branch, and open the console guard for what is proven. |

## Basic: what an operator sees at a glance

| # | The thing | Today | Waits on |
| --- | --- | --- | --- |
| 1 | What is running, and each current cue | `ma3_playbacks`, built in alpha.7 | the desk |
| 2 | What is in each user's programmer | `ma3_programmer`, built 2026-11-21: empty or not per profile and environment. `{values:true}` exports the contents; proven only on an empty programmer | the desk; one read while a programmer holds values |
| 3 | How many fixtures are selected | in `ma3_programmer` (selection counts) | the desk |
| 4 | Which fixtures are selected, in what order | `ma3_selection`, built 2026-11-21 (`SelectionFirst` / `SelectionNext` / `GetSubfixture`, run on onPC as the MCP user with three fixtures selected). Undocumented `SelectionTable()` also answers | loading alpha.7 on onPC; then the desk (`console_ok` first call) |
| 5 | What a fixture or a universe is sending right now (DMX sheet) | `ma3_dmx`, built 2026-11-21 (`GetDMXUniverse`). Universe 1 address 1 read 70 % and later 29 % on onPC, so the value is live. Not checked: that a session member's values equal what the console sends | loading alpha.7 on onPC; one comparison against a known value; then the desk |
| 6 | What value an attribute has and who owns it (cue, programmer, park, tester, default) | `ma3_values`, built 2026-11-21: per channel the attribute, DMX address, value before and after the masters, default, flags. The owner is not in it. The undocumented `GetProgPhaser(ui_channel, phaser_only)` / `GetProgPhaserValue(ui_channel, step)` read programmer values per channel (they answer `nil` on an empty programmer) | the owner: bench `GetProgPhaserValue` with values in the MCP programmer (Blind on), and the sheet-reading `Grid*` functions |
| 7 | Which channels are parked or held by the tester | counts per universe only (`ma3_universes`) | API bench |
| 8 | Master levels: grand, world, speed, rate, playback, timing, the selected masters | `ma3_masters`, built 2026-11-21 (`Master <pool>.<n>` `NORMEDVALUE`, read on onPC). The branch is show data the guard already allows, so alpha.6 on the desk can read it now with `ma3_children "Master 2" {fields:["NORMEDVALUE"]}` | the desk |
| 8b | Executor fader levels and group master levels | benched on onPC: `GetFader({token=\"FaderMaster\"})` on the assigned sequence or group | add `level` to `ma3_pages` and `ma3_playbacks`, then the desk |
| 9 | Each user's selected sequence, current page, world, at-filter | benched on onPC for the station's own user: `SelectedSequence()`, `CurrentExecPage()`, `SelectedLayout()`, `SelectedTimecode()`. Other users' values unread | tool; object bench in the user profile for other users |
| 10 | Timecode: is a slot running, where is it | `TimecodeSlot n` `TIMESTRING` readable; no tool; a show's running state unread | small tool; bench the running flag |
| 11 | Messages and errors (Message Center) | gap; not in the object tree | API bench (second method, as the roadmap asks) |
| 12 | Who is logged in where, which stations are in the session | users and profiles readable as objects (onPC); no tool; stations unread | tool for users; object bench for stations |
| 13 | Parameters granted and left | gap | object bench |
| 14 | The Oops list as one job entry | `ma3_history` lists it | closed for reading; listed for the record |

## Basic: what an operator sets up and the MCP cannot read

| # | The thing | Today | Waits on |
| --- | --- | --- | --- |
| 15 | sACN and Art-Net rows, sources seen on the network | gap; the path is known from MA's own menus | API bench, guard rule |
| 16 | DMX ports of every station | `ma3_ports`, built in alpha.7 | the desk |
| 17 | Remote inputs (OSC, MIDI, DC, DMX remotes) and what each can fire | gap. Also the open question whether OSC Receive Command is on | object bench of `Remote` objects; device configuration bench |
| 18 | User settings that change what a command does (Single Digit Input, store preferences) | gap; inside the user profile | object bench, guard rule |
| 19 | Views, screens, what is on each display | read on onPC 2026-11-21 for the station's own user: views (`CurrentProfile().Views`), view buttons and windows per screen (`CurrentScreenConfig()`), 85 window types (`ShowData().WindowTypes`). No tool; another user's screens only through the profile objects | tool (`ma3_screens`); guard rule for the console |
| 20 | Executor configurations | which one an executor uses is the executor's `EXECUTORCONFIGURATION` property (read on onPC 2026-11-21); the configurations themselves unread, and `ma3_pages` does not return it | add the property to `ma3_pages`; one object read of a configuration |
| 21 | Timecode slot settings | gap; not in the show file | where they live |
| 22 | Show files on the drives and their history | Mac-side reader only | tool over the proven drive read |
| 23 | Macro variables (user and global) | `UserVars()` / `GlobalVars()` answer on onPC (`UserProfile n.10`, `Root 14.1.6`); listing the variables unread | one object read of each, then a tool |
| 24 | Where a preset or group is used | gap | `GetReferences` bench |
| 25 | Other data pools than the default | bulk tools read `DataPool 1` only | a `pool` argument |
| 26 | Worlds, filters, MAtricks pool, timers, quickeys, recipes, notes, scribbles, shapes, generators, bitmaps, media pools | readable as objects in principle, never read, no tool | one read each on onPC, then bulk tools where he uses them |
| 27 | RDM devices | gap | whether his rig uses RDM |

## Found by the 2026-11-21 sweeps (not in the first list)

| # | The thing | Today | Waits on |
| --- | --- | --- | --- |
| 36 | Who the plugin works as, and that user's page, selected sequence, layout | `ma3_user`, built 2026-11-21 | loading alpha.7 on onPC; the desk |
| 37 | Station health: CPU, memory, temperatures, frame rate | gap. `GetSample("CPU")` = 1.4 and `GetDebugFPS()` = 60 answer on onPC; memory and temperature read 0 there. Would have shown the 2026-11-08 freeze coming | tool; the desk for real sensors |
| 38 | Which build runs (version, git hash, compile date) | gap. `BuildDetails()` answers on onPC | add to `ma3_status` |
| 39 | Desk lock and open pop-ups | gap. `DeskLocked()`, `GetTopModal()`, `GetTopOverlay()` answer on onPC | add to `ma3_status`; a pop-up is what stalls a command |
| 40 | Values stored in a preset, as data | export only. `GetPresetData(handle)` / `GetPresetDataFast` exist | bench the table's shape |
| 41 | What is on a screen: windows, and the cells of any sheet (fixture sheet, sequence sheet) | half done 2026-11-21: windows and their pixel rectangles read through `GetDisplayByIndex(1)` / `UIChildren()` / `AbsRect` on onPC (used to check the MCP view); the stored side reads as `CurrentScreenConfig().ScreenContents[screen]` (`ViewWidget` X, Y, W, H). Sheet cells not read yet. `GetDisplayCollect`, `GetScreenContent`, `UIChildren`, `GridGetDimensions`, `GridGetCellData({r,c})` (text and colours of a cell) exist | bench on the MCP user's own screens; this is also how the playground gets checked |
| 42 | The Command Line History text | `ma3_history` says `lines_supported` false. `GetTextScreenLineCount()` = 8192 and `GetTextScreenLine()` = 1590 answer on onPC; `obj:GetLineCount()` / `GetLineAt(n)` read lines of a text object | find which object holds the lines; then `ma3_history` returns them |
| 43 | Any object's full property list with read-only flags | `ma3_object {schema:true}` gives names and types; `PropertyInfo(i)` adds read-only and the enum name | add to the schema output |
| 44 | Every command keyword | from the help only. `GetTokenNameByIndex(i)` walks the console's own table | bench; feeds the guard's keyword list |
| 45 | Every Lua function of the running build | done: 197 object-free and 167 object functions with MA's argument text, `docs/research/onpc-2.5.1.1-api-functions.txt`. About 55 object-free and 90 object functions are in neither the help nor MA's meta file | read the list before saying "no function exists" |
| 46 | Messages between stations and plugins | `OpenMessageQueue`, `SendLuaMessage(station, channel, table)` exist, undocumented | understand before use; could carry onPC-to-console plugin calls |

## Basic: what the MCP cannot do

| # | The thing | Why | Way out |
| --- | --- | --- | --- |
| 28 | Work without touching Aaron's programmer, selection and command line | closed 2026-11-21 for work sent through onPC as the `MCP` user | "The MCP user" below |
| 29 | `Store` safely while he programs | Store takes his programmer | until 28: copy an empty object (proven 2026-11-21), and `ma3_programmer` first once it is on the desk; then make `ma3_command` refuse a Store while `plugin.programmer_empty` is false |
| 30 | Change the patch on its own | fixture types and patch need the Patch menu open on the desk and his save | 28 may change this: a second station can open its own patch [?] |
| 31 | Import from the stick by command | failed 2026-11-08, not understood | onPC bench |
| 32 | Create timecode events | unproven | onPC bench |
| 33 | Put `ma3_set` writes in the job's undo group | tool limit | `undo_group` argument on `ma3_set` |
| 34 | Update itself on the console | stick and GUI import; the PIN changes each import | settings fix offered 2026-11-05, unanswered |
| 35 | Program cues, fire playback | by Aaron's rule, not a limit | his decision if that changes |

Known bugs (fixed in alpha.7, 2026-11-21: `ma3_groups` returned `sf####` instead of FIDs): `ma3_lua` answers HTTP 500 when the returned table mixes number and text keys; `ma3_children` fails on a child that is not an object (`UserProfile n.1.1`, slot 5);
`ma3_groups` returns `sf####` instead of FIDs on the console.

## The MCP user (created 2026-11-21 on Aaron's yes)

`User 9` `MCP`, rights Admin, on its own `UserProfile 7` `MCP`. onPC on this Mac is logged in as it
and stays in the console's session. Aaron, the same night: "I want the mcp user to be your full
playground, with views, windows, layouts, appearences, the whole thing."

Proven 2026-11-21 (onPC 2.5.1.1 in the console's session, plugin alpha.6 on both):

- A command sent by the plugin on onPC changes the show the console holds: `Store UserProfile 7 "MCP"`,
  `Store User 9 "MCP"` and a scratch `Store Sequence 9990` / `Delete Sequence 9990` were each read
  back on the console.
- After `LogIn "MCP"` on onPC the plugin kept running, and it types as `User 9` on `UserProfile 7`:
  own programmer (empty part, 297 bytes), own selection, own current page (`Page 1`), own Oops list.
  The console's command line and Oops list showed none of it (its last command stayed Aaron's own
  `Select Page 4`).
- Syntax that works: `Store UserProfile <n> "<name>"`, `Store User <n> "<name>"` (comes up Admin, on
  `UserProfile 1`), `Set User <n> Property "profile" "14.19.<profile no>"` (the numeric address, as
  MA's own test does; the name form answers OK and changes nothing; `Assign UserProfile At User` is
  `Illegal object`). `LogIn` is refused by `ma3_command`; it went through `ma3_lua` as
  `CmdIndirect('LogIn "MCP"')`.

What this changes:

- **Jobs go through onPC as `MCP`.** A Store no longer takes Aaron's programmer, a selection no
  longer moves his, and a job's commands stay off his command line and out of his Oops list. Rows
  28 and 29 are closed for work done this way.
- **Reads go through onPC too**, with one limit found the hard way on 2026-11-21: a call that hangs on
  onPC does not freeze the desk's screen, but the stalled station backs up the session (the console
  showed flow control at maximum until onPC was killed). So through onPC-in-session: proven calls
  only. Anything that can hang needs onPC outside the session.
- **onPC has no console guard and Lua can be on**, so every API read benched below works there today
  through `ma3_lua`, before any new tool exists.
- Shared pools are still shared. A layout, appearance, group or preset the MCP makes is in Aaron's
  pools. My rule until he says otherwise: MCP objects in shared pools are named `MCP ...` and take
  numbers from 9000 up; nothing of his is edited for the playground.

Still open: what happens when this Mac sleeps or leaves the building (the server is then gone; the
console's plugin is the fallback); onPC must stay below the console in session priority; whether
onPC as `MCP` can open its own Patch menu while he works (row 30); the playground itself (views,
windows, layouts, appearances for the `MCP` profile) is not built yet, and needs row 19 (reading
views and screens) first.

## API reads benched on onPC (2026-11-21, `ma3_lua`, read-only, as User 5 then as MCP)

All answered, none hung: `Selection()`, `SelectionCount()`, `SelectionFirst()`, `Programmer()`,
`ProgrammerPart()`, `CurrentUser()`, `CurrentProfile()`, `CurrentEnvironment()`,
`CurrentScreenConfig()`, `SelectedSequence()`, `CurrentExecPage()`, `SelectedTimecode()`,
`SelectedLayout()`, `SelectedTimer()`, `SelectedFeature()`, `MasterPool()`, `DeviceConfiguration()`,
`NeedShowSave()`, `GetShowFileStatus()` (`ShowDownloaded` on a session member), `GetTopModal()`,
`DeskLocked()`, `GetDebugFPS()`, `GetSubfixtureCount()` (3,647), `GetRTChannelCount()` (11,618),
`GetUIChannelCount()`, `GetAttributeCount()` (830), `CmdObj()` (its `User`, its `Destination`),
`UserVars()`, `GlobalVars()`, `GetExecutor(104)` (executor and page), `GetCurrentCue()`,
`GetSelectedAttribute()`, `GetTokenName("Sto")` = `Store`.

- **DMX output:** `GetDMXUniverse(11, false)` returns 512 values; `GetDMXValue(1, 1, true)` = 70.
- **A fixture's channels:** `GetRTChannels(fixtureHandle, false)` gives the channel indexes (4 for a
  ladder LED); `GetRTChannel(i)` gives `fixture`, `subfixture`, `dmx_channel`, `dmx_default`,
  `dmx_highlight`, `dmx_lowlight`, `patch` (`coarse`, `fine`, `ultra`, `break`) and `info`
  (`value_before_master`, `value_after_master`, `normed_phaser_time`, `flags`: `solo`, `highlight`,
  `lowlight`, `group_master`, `additive_master`). `GetUIChannel(i)` gives `attr_index`,
  `logical_channel`, `sf_index`, `flags` (`is_dimmer`, `dmx_invert`, `snap`, ...).
- **Fader levels:** `object:GetFader({token="FaderMaster"})` returns the level and a table
  (`normed_value`, `enabled`, `flash_active`, ...) on a sequence and on a group; `FaderRate` works too.

Plugin bug met on the way: `ma3_lua` fails with HTTP 500 when the returned table mixes number and
text keys (its renderer turns `"1"` back into a number). Not proven on the console: any of the above.

## Sweeps done

| Date | Trigger | What was checked | Found |
| --- | --- | --- | --- |
| 2026-11-21 | `Store Sequence` would take Aaron's programmer; the plugin could not read it | the "Plugin access" notes of all 37 topic pages, the live-state bench list, the open items in `CLAUDE.md` | this file: 36 rows; `ma3_programmer` and `ma3_masters` built the same session. Not yet checked against the atlas checklist item by item (7,533 items, 441 proven): that is the next sweep |
| 2026-11-21 | Lua turned on in onPC's window | read-only benches of 60 API functions on onPC (three passes), as User 5 and as MCP | rows 4, 5, 6, 8b, 9, 23 moved from "gap" to benched; `ma3_selection`, `ma3_dmx`, `ma3_values`, `ma3_user` built; found the cause of `ma3_groups` returning `sf####` (the plugin never took `GetSubfixture` from the console's globals), fixed with a test |
| 2026-11-21 | the first two sweeps | a Sonnet agent read all 152 Lua help pages and MA's meta file: `docs/atlas/topics/lua-api-functions.md` (about 185 rows, each gap row matched to a call). Then `GetApiDescriptor()` / `GetObjApiDescriptor()` on onPC gave the build's own list | rows 36-46. The agent's "no function exists" for programmer values, messages and screen contents was wrong against the build's list: the functions exist, undocumented |
| 2026-11-21 | alpha.7 loaded on both stations | every new tool called once against the live show on onPC; `ma3_playbacks` and `ma3_universes` on the console | all nine answered; rows 1-5, 8, 16, 36 now work on onPC (`Be Glad` cue 5 running, dimmer 611 at 10 %, 134 live addresses on universe 1). `ma3_groups` members of a multi-part fixture list the part number (`1`, `3`), the address is right |
| 2026-11-21 | Aaron: "I'd rather you stress test things now" | first console calls of all new reads; the 2026-11-08 census again on onPC with a log line before each call; a load test of proven reads on the console | the freeze: `ma3_object "Geometry "` (call 706, same place as on the console); fix built with tests; console load test clean. `docs/research/2026-11-21-freeze-found-and-stress.md` |
