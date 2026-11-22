# MA3 MCP — project context

A grandMA3 Lua plugin that makes the grandMA3 light an MCP server. Public personal repo:
https://github.com/upipibi/MA3-MCP (Aaron's, not the Northwoods org). State as of 2026-11-21:
v0.2.0-alpha.8 runs on the console and on onPC, stored in the show file `Christmas 2026`. onPC on this
Mac is the MCP's own station (user `MCP`), and the MCP has programmed its first songs.

**This repo is public.** No console or network addresses, no PIN, no private paths in anything that
gets committed. Raw data read from Aaron's shows (per-show reports, exports, his stage plot, the
production schedule) is git-ignored (the "raw show data" block in `.gitignore`) and backed up to the
project's OneDrive secrets folder (`VS Code/MA3 MCP/` in Aaron's OneDrive, the tier described in the
org's `FILE-ORGANIZATION.md`), same sub-paths (Aaron, 2026-11-05: "we just keep show data in the OneDrive secrets"). `/save` copies
new ignored files under `docs/` there.

## Console safety (read before any console request)

**2026-11-08, during a Sunday service, an unasked automated read job froze the console's screen.**
I ran a "class census" script that walked the whole object tree with `ma3_object` reads. About 700
reads in, one read never returned; plugins run on the console's screen thread, so the GUI froze while
lighting and timecode kept running, and the only way out was a restart mid-service. Aaron: "YOU CAN
NOT DO THIS AGAIN". The rules, which override any plan, roadmap phase or skill:

- **Never run automated, looping or exploratory reads against the console.** No census, crawl, walk
  or "read everything" script, ever, unless Aaron approves that exact job knowing its size and time.
- **Explore on onPC only**, after Aaron has started onPC and the plugin for it. Unknown classes,
  objects, properties and commands are proven there first.
- **onPC is a bench only while it is outside the console's session.** Same 2.5.1 version and the
  default key in every show mean it could join; joining swaps show files (a higher-priority station
  uploads its show to the console). Check onPC's Network menu before benching:
  `docs/atlas/topics/networking-and-sessions.md`.
- **On the console, only proven-safe tools and addresses, only for the job he asked for.**
- **Ask whether a service or rehearsal is running** before any console request on a Sunday, or any
  time he has said "in service". Reads count.
- **Never leave a background process talking to the console.**
- **The object that hung is found (2026-11-21, reproduced on onPC): `ma3_object "Geometry "`**, the
  address a fixture type's geometry collection reports for itself. Resolving it never returns. The
  fix is built (refuse the address, path addresses for such children, proven-keyword rule on a
  console) and is not on a station yet. Record: `docs/research/2026-11-21-freeze-found-and-stress.md`.
  Until the fixed build runs on the console, never send an address that came out of `ma3_children`
  of a fixture type, and still treat unfamiliar classes there as dangerous.

## Resume here (written 2026-11-21, Saturday night, at `/save`)

Aaron stopped for the night: "There are definently some tweaks need to me, but I am impressed. I was
expected a dumpster fire, and you got very close ... /save for now, and we'll continue working on
this later." The show was saved with `ma3_save` at the end; it holds everything below.

1. **First thing next session: his tweaks to the four Nov 29 songs** (Sequences 10-13). He has not
   said which. Ask nothing up front; when he names a tweak, change `docs/jobs/2026-11-21-nov29-songs/
   build.py` or the cue itself, through onPC as `MCP`, and verify with `build.py verify`. Whatever he
   corrects is a lesson for `docs/PROGRAMMING-STYLE.md`.
2. **Stations:** alpha.8 on the console (Lua off) and on onPC (Lua on, user `MCP`, view `MCP`, in the
   console's session). **alpha.9 is released on GitHub (2026-11-22, Aaron: "go ahead and release it as
   alpha.9") and is not on a station:** it is alpha.8 plus one hardening (`Geometry` is refused
   anywhere in an address, not only as the first word; 3,648 tests). The zip is
   `dist/MA3-MCP-0.2.0-alpha.9.zip`. It was a Sunday morning, so nothing was copied to onPC's library
   (`make install-onpc` when he wants it there) and nothing was sent to the console. Stations move to
   alpha.9 only by his import. onPC through `python3 tools/onpc_call.py`, the console through the `ma3`
   connector or `python3 tools/mcp_call.py`. A session started before the import lists old tools on
   its connector until the window is reloaded. If onPC's plugin ever stops answering, end onPC at
   once (`pkill -KILL -f "grandMA3 onPC"`): a stalled station loads the console's session.
3. **Gap work, mine, no ask needed:** `docs/GAPS.md`. Next: turn the onPC census (629 classes) into
   reads; programmer values per channel (`GetProgPhaserValue`); reading sheet cells (`Grid*`); the
   Command Line History text; the item-by-item sweep against the help checklist.
4. **Open with Aaron:** whether flow control dropped after onPC was killed (asked three times,
   unanswered: ask once more, then drop it); ladder layout tweaks ("a later issue", his to raise); the MCP playground beyond the one view
   (layouts, appearances). **Closed:** the GitHub pre-release: declined 2026-11-21 ("we just keep it local
   for now"), then asked for the next morning; alpha.9 is published as a pre-release. The next
   release is again his to raise, with his number.
6. **Written just before a compact (2026-11-21, 23:00). What a fresh context must not get wrong:**
   - Everything is pushed as of the alpha.9 release commit (2026-11-22).
   - Jobs and exploring reads go through onPC as `MCP` (`python3 tools/onpc_call.py <tool> '<json>'`);
     undo groups of those jobs are in the MCP user's Oops list, so "undo" is mine to send, by group
     name (`nov29-10` .. `nov29-13`, `nov29-12-fix`, `dimmer-rows`, `mcp-view`, `mcp-user`).
   - The console is still never a bench: no census, no first call on an unknown class there.
   - To program a song: `docs/PROGRAMMING-STYLE.md` (last two sections) and
     `docs/jobs/2026-11-21-nov29-songs/README.md`. Status copies with `"ForceRelease"`, holds empty,
     one donor song per new song, values from the current show only, never from an old rig.
   - Local, git-ignored, also in OneDrive: his song exports and my look sheets
     (`docs/research/shows/christmas-2026-study/`); re-export before trusting them, he edits daily.
   - Reply format: his global rules (label-first headings, tight budgets, no emojis, fun fact last).
5. **Study agents:** he wants them kept going (two at a time, Sonnet, offline only). Next topics are
   in "The gap rule" below.

## State at 2026-11-21, 21:00 to 22:30 (the evening, newest first)

- **DONE 2026-11-21, 22:30: the four Nov 29 songs are programmed** (Sequences 10-13, 25 / 24 / 18 / 32
  cues), built from his own cues on this rig and verified cue by cue. **Waiting on his run-through**:
  I cannot see the stage. Record, my calls and the weakest part (the second half of King of Kings):
  `docs/jobs/2026-11-21-nov29-songs/README.md`. A change is an edit of `build.py` and a re-run on a
  cleared sequence. Saved with the show at `/save`.
- **How it came about, kept for the method** (2026-11-21, 22:15): "Once I'm done programming, I want
  you to program the Nov 29th weekend." That lifts "cues are Aaron's" for Sequences 10-13 only (Thank The Lord,
  This Is Our God, Manger to the Cross, King Of Kings/Angels We Have Heard on High; already on Page 5
  `Nov 29`, 106-109, one empty cue each). Wait for him to say he is done programming.
  - **His correction the same night:** "you should be learning from my cues, and old shows, likely
    we've done these songs before too. Figuring out how I start, end, where I put fixture, colors,
    phasers ... you need to learn how to do that", and "fixtures have moved since past shows. So you
    need to apply the why behind the past shows, not hard values. And you need to look at my current
    show to see where im moving fixtures and when." So: **do not ask him how a song starts or ends;
    read it.** Do not copy values from old shows.
  - **Learned and written down:** `docs/PROGRAMMING-STYLE.md`, "How a song is built on the Christmas
    2026 rig" (looks, colour, each family's job, where and when tilt moves, phasers, fades), from full
    exports of his ten finished songs. All four Nov 29 songs were done before; his earlier cue lists
    (the energy map of each) are in `docs/research/shows/2026-11-21-nov29-songs-earlier-cue-lists.md`
    (local). Tools: `tools/song_looks.py`, `tools/song_vocab.py`.
  - **Method:** cue list from this year's Planning Center arrangement (`song_prep`, plan 91338104),
    energy words from his earlier cue list of the same song, looks from this rig's vocabulary. Each
    stored cue is a status copy of the cue in his current show that plays the same role
    (`Copy Sequence <a> Cue <n> At Sequence <b> Cue <m> /CopyCueSource "Status"`, proven on onPC), so
    values, positions and phasers are his and current. Holds stay empty, as he leaves them. Not yet
    decided with him: which finished song each new song borrows its palette from.
  - I cannot see the stage: he judges the result on a run-through.

- **22:00: alpha.8 runs on both stations** (Aaron imported it on onPC; the show's plugin pool is
  shared, and the console's plugin restarted on it). The fix is proven on onPC: `Geometry ` refused,
  the object readable by path, and **the full census completed: 2,099 calls, 629 classes, no hang**.
  onPC is logged in as `MCP`, Lua on, in the session. Not done on the console: any census (it stays
  forbidden there); the console's alpha.8 has only answered `ma3_status`.

- **21:30: stress test, on Aaron's word** ("do all the things you need to do while I program ... I'd
  rather you stress test things now"). Console: first calls of every new read passed, and a load
  test of proven reads passed (median 12 ms at 6 a second, the rate cap refuses cleanly). onPC: the
  census found the freeze (`Geometry `) and **left onPC's plugin stuck: it needs Aaron to restart
  onPC and the plugin, Lua on; then log it in as `MCP` again** (`CmdIndirect('LogIn "MCP"')` through
  `ma3_lua`) and call `View 1`. At its next start the plugin should quarantine the stuck call by
  itself: check `ma3_status {log:true}`.
- **A stalled onPC loads the console's session.** Fifteen minutes after onPC's plugin stuck, Aaron saw
  "flow control is maxed out" on the desk; I killed onPC (`pkill -KILL -f "grandMA3 onPC"`, TERM is
  ignored). So: anything that can hang runs on onPC only while it is **outside** the session, and a
  plugin on onPC that stops answering means end onPC at once. Through onPC-in-session, proven calls
  only, as on the console. onPC is not running now.
- **alpha.8 = alpha.7 + the freeze fix**, built 2026-11-21 21:50 and placed in onPC's library
  (`gma3_library/datapools/plugins/MA3 MCP.xml` + `.lua`, and `lib_plugins/ma3_mcp/`); 3,635 tests
  pass. Aaron loads it on onPC himself ("I'll load the plugin onpc when you place it in the right
  folder"). I took his go-ahead as a yes to the number alpha.8. The console still runs alpha.7.

- **alpha.7 runs on the console and on onPC** (Aaron loaded it on both the evening of 2026-11-21;
  `ma3_status` on each). onPC: Lua on, logged in as `MCP`. Console: Lua off.
- **Every new read ran against the live show on onPC:** `ma3_user`, `ma3_programmer`,
  `ma3_selection`, `ma3_values`, `ma3_dmx`, `ma3_masters`, `ma3_playbacks`, `ma3_universes`,
  `ma3_ports`, and `ma3_groups` gives fixture addresses again. On the console: `ma3_playbacks` and
  `ma3_universes` ran (same answers as onPC). **Not yet called on the console:** `ma3_programmer`,
  `ma3_ports`, `ma3_masters` (new branches there) and the four API reads (`console_ok`). They wait
  for a moment right after a show save, not while he is programming; onPC covers them meanwhile.
- A VS Code session started before the import still lists the alpha.6 tools on its `ma3` connector:
  call the new ones with `python3 tools/mcp_call.py <tool> '<json>'` (console) or
  `python3 tools/onpc_call.py` (onPC) until the window is reloaded.
- Still unproven: `ma3_programmer {values:true}` on a programmer that holds values (every programmer
  was empty at each read).

## The gap rule (Aaron, 2026-11-21, third time: "we've run into some pretty BASIC STUFF that the MCP cant do")

Setting up the Nov 22 songs I had to work around `Store` because the plugin could not read his
programmer. His rule, which stands for every session: **a thing the MCP cannot see or do means two
jobs, not one: (1) the MCP gets the update, and (2) the same session does a wider dive into what else
is missing around it.** One-offs will happen; basic things must not. The ledger is `docs/GAPS.md`:
read it at the start of any plugin work, add every miss to it the session it is found, basic things
first. A workaround may finish a job and never closes a gap. Never hand him a desk check.

- **Built 2026-11-21 (in alpha.7; on both stations since alpha.8 the same night):** `ma3_programmer` (every user's programmer and
  selection; `plugin.programmer_empty` says whether a Store from the plugin would take values).
  Proven on onPC by object reads only, on empty programmers; `{values:true}` (export of a part) has
  never seen a programmer with values. Also `ma3_masters` (level of every master; the branch is show
  data, so alpha.6 on the desk can already read it with `ma3_children "Master 2"`). 3,508 tests pass
  on 5.5 and 5.4; build is in the onPC library. Nothing is committed (waits for `/save`).
- **Until it is on the desk:** make empty sequences by `Copy Sequence <empty> At Sequence <n>`, not
  `Store` (`docs/CONVENTIONS.md`, "Cues are Aaron's").
- **The MCP user exists (Aaron: "yes to the MCP users", 2026-11-21).** `User 9` `MCP` (Admin) on
  `UserProfile 7` `MCP`; onPC on this Mac is logged in as it, in the console's session, Lua on.
  Proven the same night: a command sent through onPC's plugin changes the console's show, and runs
  on MCP's own command line, programmer, selection and Oops list, not Aaron's. **Send jobs and
  exploratory reads through onPC** (`python3 tools/onpc_call.py <tool> '<json>'`, which reads onPC's port and PIN
  from its settings file; also registered in Claude Code user scope as `ma3_onpc`, live after a
  window reload), and keep the console's plugin for
  what only the desk knows. This replaces the 2026-11-19 "nothing that writes on onPC" line. Record
  and syntax: `docs/GAPS.md`, "The MCP user".
- **His direction for it:** "I want the mcp user to be your full playground, with views, windows,
  layouts, appearences, the whole thing." Started 2026-11-21: the profile has one view, `MCP`, on
  onPC's screen 1 (plugins, users, Oops, system monitor, command line history, fixture sheet,
  layout); the 12 factory views are gone. Record and the window syntax: `docs/jobs/2026-11-21-mcp-view.md`. My rule for shared pools: MCP objects are
  named `MCP ...` and numbered from 9000 up; nothing of his is edited for it.
- **API reads benched on onPC with Lua on, then built into alpha.7:** `ma3_selection`, `ma3_dmx`,
  `ma3_values`, `ma3_user` (refused on a console until a supervised first call with `console_ok`),
  plus the `ma3_groups` `sf####` fix (`GetSubfixture` was never taken from the console's globals).
  3,588 tests pass on 5.5 and 5.4. **onPC still runs alpha.6 from the show**, so until alpha.7 is
  loaded these reads go through `ma3_lua` on onPC (bench scripts show the calls: `docs/GAPS.md`).
  The build's own function list (364 functions, many undocumented, among them programmer values per
  channel and reading the cells of any sheet): `docs/research/onpc-2.5.1.1-api-functions.txt`.
  Read it before saying a function does not exist.
- **Two study agents ran 2026-11-21 (Sonnet, offline only), both finished:** the Lua API catalogue
  (`docs/atlas/topics/lua-api-functions.md`) and his programming patterns counted across the two old
  show reports (folded into `docs/PROGRAMMING-STYLE.md`, "Counted across the two old shows"). Aaron
  wants study agents like these kept going ("have a subagent working on learning about the console
  ... another learning how I program"): two at a time, Sonnet, offline only, per the
  `dispatching-research-agents` skill. Next topics: the 145 undocumented functions; the old shows'
  raw exports once more show files come off the console by stick.
- **Asks open with Aaron:** none on the plugin (alpha.7 is loaded). The ladder layout: "needs tweaked, but thats a later issue" (2026-11-21); wait for him.

## 2026-11-19: "the MCP NEEDS TO BE ABLE TO SEE EVERYTHING" (Aaron, twice, angry)

Asked why ladders 7 and 8 are multicolor "by default", I sent him to the desk four times (Off menu,
CueAbs layer, sACN tabs, users) because the plugin had no tool for any of it. His rule now: **a thing
the plugin cannot read is a plugin gap to close, not a check to hand to Aaron.** Say "gap, building
it" and build it. Memory: `mcp-must-see-everything`.

- **Built, not on the console: plugin 0.2.0-alpha.7** = alpha.6 + `ma3_playbacks` (`src/tools/live.lua`;
  running sequences, current cue, fade, executors). Uses only `HasActivePlayback()` / `CurrentChild()`,
  the calls Cue Display makes at 5 Hz on the console. 3,388 tests pass on 5.5 and 5.4; installed in the
  onPC library. Needs the stick and Aaron's import to reach the console (before the 12-08 freeze).
- **Bench list for the rest of live state:** `docs/research/2026-11-19-live-state-bench.md`. Needs
  onPC started by Aaron, Standalone (not in the console's session), plugin on; I drive it with
  `ma3_lua` over HTTP. Order: Parameter List by fixture, DMX output, network DMX in/out, programmer
  (all users), who-owns-this-value, park and tester, selection, masters, session.
- **Ladders 7 and 8, state of the question:** patch clean (LEDs of ladder 7 and 6 identical in every
  property); only `Right DF 50 Haze` running (read from Cue Display's `/api/state` on the console,
  port 8090: it lists every running sequence); Art-Net all unicast (Aaron). Best lead, **not yet
  read**: stored per-channel Default values in the Parameter List (`Store Default`, MA help
  `patch_parameter_list`), which would be exactly "multicolor by default". The read
  (`ma3_object Root 14.9.9.<n>`, proven address) was stopped by the session's permission
  classifier on 2026-11-19; it needs Aaron's go or a permission rule. Index for FID 20308 is not
  known: entries run in subfixture order (entry 900 = FID 4201 = subfixture 893; FID 20308 =
  subfixture 1666; estimate near 3,989, find by a few reads). Documented reset, unproven by us:
  select the fixtures, give the colour attributes any value, `Store Default /Remove`.

**Later 2026-11-19 (Aaron turned bypass permissions on, "go ahead and check"; started onPC + plugin):**

- **Ladders 7 and 8: SOLVED the same evening.** The console's own output configuration has DMX port
  **XLR G set to In on universe 7** (merge on, priority LTP), and ladders 7 and 8 were patched on
  universe 7, so whatever feeds port G drove them until a programmer value took over. Evidence:
  `ma3_object "DMXUniverse 7"` on the console = `PORTIN true`, and `Root 22.1.1.1.1` (read on onPC, which
  is in the console's session and shows every station's ports) = `MODEG In`, `XLRG 7`, `PRIOG LTP`;
  ports A-F are Out on universes 51-56. Aaron had already moved both ladders to universe 11
  (`Fixture 20308` now `11.001`; universe 7 `USED 0`, universe 11 `USED 100`). Aaron confirmed the same evening: "I moved 7 and 8 to universe 11 and that
  fixed the issue". Not known: what is plugged into port G. Also: both onPC stations (this Mac and a second one in the booth) carry the command-wing
  default **port C = In on universe 3**, where the Portmans are patched; harmless unless a real wing
  with a DMX feed is attached. Earlier dead ends, for the record: stored Defaults: stored Defaults (Parameter List entries for
  FIDs 20308, 20318, part of 20331/20332/20403 and ladder 6's 20293: every colour channel `DEFAULT
  FFFFFF`, dimmer `000000`, `HIGHLIGHT FFFFFF`, no default preset; a sample, not all 400); the second
  user's programmer (`UserProfile 1.1.1.3`, read on onPC: `Part Zero` 297 bytes, same as profile 5's);
  the groups (816-818 identical in shape); other data pools (only `Default` and `Preview`).
- **New proven reads (console):** `ma3_object "DMXUniverse <n>"` gives `USED` (fixtures), `COARSEPARAMS`,
  `PORTOUT` / `PORTIN` / `PORTRDM` (a physical port of some station is mapped to it), `PARKEDCOUNT`,
  `TESTERCOUNT`, `GRANTED`, `MERGEMODE`. Universe 1 has 71 parked channels (the relays). **Read this
  first for any "why does this fixture do that by itself" question.** Device configuration (onPC only so
  far; the console guard refuses `Root 22`): `Root 22.1` = OutputStations by type (`Console`, `onPC`, `PU`,
  `NetworkNode`), each station (`IP`, `MAC`, `INMYSESSION`, interfaces) with one `OutputConfiguration`
  (`MODEA..G`, `XLRA..G` = universe, `MERGEx`, `PRIOx`, `FAILUREMODEx`, MIDI and timecode ports);
  `Root 22.2` = DMXProtocols (sACN, Art-Net), not read yet. **Built the same evening into alpha.7:
  `ma3_universes` and `ma3_ports`** (`src/tools/live.lua`), with a guard rule for
  `DeviceConfigurations > OutputStations` only, readable by `ma3_ports` alone (`guard.READ_RULES`: no address
  reaches it, so `ma3_set` cannot write port settings; found by the `/save` security review) (3,434 tests pass on 5.5 and 5.4; in the onPC library,
  not on the console). First call of `ma3_ports` on the desk: once, outside a service.
- **Aaron, 2026-11-19: "im not taking the onpc session out, figure out whatever it is you are working
  on, stop bugging me about it".** onPC stays in the console's session; that is his call. So on onPC:
  single read-only object reads are fine, nothing that writes, no experiments with commands, and no
  more asks about its session. Lua is off there, so API-function benches wait for a time he has Lua on.
- **Parameter List facts (console):** `Root 14.9.9.<n>` returns the entry with `INDEX` n-1. Four entries
  per ladder LED in the order Dimmer (virtual, no `COARSE`), R, G, B. Ladder 7 = index 3609-3808
  (FID 20308 dimmer = 3609), ladder 8 = 3809-4008, ladder 6 ends at 3608. Properties: `DEFAULT`,
  `HIGHLIGHT` (hex, 24 bit), `COARSE`, `CHANNELNAME`, `FID`.
- **Where the programmer lives (onPC):** `UserProfile <n>.1` = Environments (`Normal`, `Preview`);
  `UserProfile <n>.1.1.3` = class `Programmer` (sequence-like), child `ProgPart` "Part Zero" (`Programmer 0`);
  `.1` and `.2` are `Selection` objects (`COUNTTOTALSELECTED`), `.4` `AtFilter`. `Cmdline 2` = `User 2` /
  `UserProfile 1` exists on every station (console and onPC list the same two): a standing second
  command line, not a second person.
- **onPC on this Mac is IN the console's session** (`Root 5`: the console's session, `STATUS Connected`,
  not session manager, Lua off, plugin alpha.6 from the show). A second onPC station is in the
  session too.
- `Root 14.12 Output`, `Root 14.15 DMXRoot`, `Root 14.21 PlaybackTable` are empty containers to the
  object API (no children, no useful properties): live output needs the API functions, not the tree.
- **Plugin bugs found:** `ma3_children` on `UserProfile 1.1.1` fails with "attempt to call a nil value
  (method 'GetClass')" (`console.child_summary` needs a guard for children that are not objects);
  `ma3_groups` on the console now returns members as `sf1666` instead of FIDs (`GetSubfixture` not
  answering there, or the lookup broke in alpha.6): check on the bench.
- **Done 2026-11-19, 22:10: ladder LEDs in Layout 1** (Aaron: "are you ready with that new layout with the
  pixles?"). The shape came from the place groups he built that evening (701-706 legs, 709 `Curve`, 710
  `Platform Top`), not from a sketch. 650 cells in a new `Ladder LEDs` box under `Infini Bars` and `Tornado`;
  the 14 dimmer tiles moved to one row in the `Key` box. Backup `Christmas 2026_mcp_1120_0407`, undo group
  `ladder-layout`, verified from a fresh export. **Waiting on his reaction** to my calls
  (legs as 5 x 10 snakes, which top line is front, ladder 11 and 22 skipped LEDs parked in grey):
  `docs/jobs/2026-11-19-ladder-layout/README.md`; a change is a re-run of `ladders.py`.
- **Done 2026-11-19: groups 608 / 609** (odd and even Tornado yokes), record in
  `docs/jobs/2026-11-19-tornado-odd-even/`. MAtricks `XGroup` cannot give each interleaved half its own
  0-360 spread (Aaron tried it; my first answer was wrong): a group with its own grid can.

## Earlier resume list (written 2026-11-19, Thursday night, at `/save`)

Aaron stopped for the day ("lets stop here for today /save"). The show was saved with `ma3_save` at the
end (it holds groups 608 / 609, the ladder layout and his own evening's programming). The console runs
alpha.6; alpha.7 is built and tested but only in the onPC library.

1. **First thing next session: his reaction to the ladder layout.** Three guesses are waiting on him
   (legs as 5 x 10 snakes with LED 1 on top; ladders 12/13 as the rear line; ladder 11 and the 22 skipped
   LEDs parked in grey). Each fix is a re-run of `docs/jobs/2026-11-19-ladder-layout/ladders.py`. Also not
   seen by me: how 8 and 9 px cells look on the desk, and whether the two-row grids of 608 / 609 chase per
   Tornado row.
2. **alpha.7 to the console** needs the stick and his import (before the 2026-12-08 freeze). Offer a
   GitHub pre-release only when it has run on the desk; the version number is his call.
3. **Live-state reads still to build:** `docs/research/2026-11-19-live-state-bench.md`. Two plugin bugs
   to fix on the way (`ma3_children` on programmer objects; `ma3_groups` returns `sf####` on the console:
   the ladder job mapped sub-fixtures to FIDs through `ma3_fixtures` instead).

## Earlier resume list (written 2026-11-14, Saturday, before a compact)

**Confirmed 2026-11-14 with one `ma3_status` (through `tools/mcp_call.py`; the session's `ma3`
connector was refusing connections):** the console runs plugin **0.2.0-alpha.6**, Lua off, show
`Christmas 2026`. Aaron imported it himself. Not a service day; he is programming at the desk.

Aaron's list after the compact, in his order ("prepare for me to compact, then ..."):

1. **DONE 2026-11-19 (Thursday, Aaron at the desk):** `ma3_status` = alpha.6, Console, Lua off,
   `Christmas 2026`. Refused live: `Lua`, `Lu`, `Plugin "MA3 MCP" "quarantine"`, unquoted `$foo`,
   `Echo ...; Lua ...` (chained), `List StationSettings` ([console-guard]). Deliberately NOT sent to
   the desk: `Reboot`, `R`, `ma3_object "Root 19"` (a guard failure there would reboot the desk or
   read the suspect branch); covered by `make test` (3,352 pass, `test/guard_test.lua`). Original note:
   **Make sure the fixes for the console crash are in place.** Check without touching unknown
   objects: `ma3_status` (version, Lua off); a refused command never reaches the console, so
   `ma3_command "Reboot"`, `"R"`, `'Plugin "MA3 MCP" "lua on"'` and `ma3_object "Root 19"` should
   each come back refused; `Plugin "MA3 MCP" "quarantine"` at the desk lists the quarantine.
   Report what was checked. The object that froze the desk is still unknown (onPC bench).
2. **DONE 2026-11-14 (live patch confirmed; show save by Aaron still to confirm):** Aaron re-imported both curves from onPC in the console's session and all 11 dimmers came back on their own (record: the job README). Original note: **His dimmer curves are missing again** (Aaron, 2026-11-14), after being restored and saved on
   2026-11-08. First find out why before restoring: read the curve pool and the 11 channels'
   `DMXCURVE` by FID (`docs/jobs/2026-11-08-dimmer-curves/README.md` has the addresses and the
   method; `docs/atlas/topics/dmx-curves.md` has the restore procedure). Suspects: the freeze
   restart loaded an older save or a backup; or the patch save did not stick. Ask Aaron what he
   loaded since. Restoring is a patch change: shown plan, his go, Patch window open, backup first,
   and saving the patch clears the Oops list.
3. **Keep learning the console and everything he has programmed** while he keeps programming.
   On the console: only proven bulk reads for the show (`ma3_sequences`, `ma3_pages`, `ma3_groups`,
   `ma3_presets`, `ma3_macros`, `ma3_fixtures`, `ma3_timecode`, `ma3_cue_timing`), paced, one job at
   a time, never a crawl of unknown objects. He edits while I read: read fresh, never write
   unasked. Fold findings into `docs/PROGRAMMING-STYLE.md` and the topic pages.

**Later the same night (2026-11-14):** curves restored (Aaron re-imported both from onPC in the
console's session; the 11 dimmers came back by themselves; backup `Christmas 2026_mcp_1114_2340`).
Aaron's show save after it is not yet confirmed. Learning pass started: sequences, four songs' cue
timing and page 8 read; findings in `docs/PROGRAMMING-STYLE.md` ("Christmas 2026 as of 2026-11-14").
Highest Praise's `-> Follows` cues 2, 13, 18 are Go instead of Follow: a slip, **not to be fixed
unless Aaron asks** (the name is Hog's follow-cue convention). Timecode: onPC has no LTC input; the
house LTC over Dante goes through Aaron's own SMPTE to MIDI app (`../SMPTE <-> MIDI/`, mesh session
`smpte-midi`), which is swapping in LTCKit and, on Aaron's yes, adding an Art-Net timecode output with
MTC / Art-Net toggles so the console itself can chase it (`docs/research/2026-11-14-ltc-plugin-feasibility.md`:
a plugin cannot do it). Next on that: bench Art-Net timecode into onPC, then the console with his go.

2026-11-19: `ListCrashLog` at the desk said "no crash log files found" (a freeze leaves none);
Aaron moved on ("Lets move on from this"). OSC: Aaron says input is enabled; per-line Receive
Command not yet checked (he moved on; raise again only when the SendOSC gap is worked on).

Still open (re-lead each reply until answered): whether OSC "Receive Command" is on per line; how `Christmas 2026`
was made; the roadmap's six decisions; the Cue Display timecode check. Not known: whether the MA3
stick still holds alpha.5 (it must not be imported).

## Earlier notes (2026-11-08)


**Dimmer curves: restored 2026-11-08 (console, live patch confirmed).** The previous show
`Late 2026 2` had two DMX curves (`Rear House`, `Seat Lights`) on 11 dimmers; `Christmas 2026` had
lost the pool entries and with them every assignment. Rehearsed on onPC, then run on the console:
Aaron imported the two curve files in the Patch window (command-line import from the stick failed,
open item), I set the 11 channels, he saved the patch. Record, facts and the open items in
`docs/jobs/2026-11-08-dimmer-curves/README.md`. Still unknown: which step of making `Christmas 2026`
from `Late 2026 2` dropped them (ask Aaron). Lesson of the day, now in `docs/research/2026-11-onpc-facts.md`:
an unknown keyword in front of a name stores a fixture while the patch is the destination; no syntax
experiments on a loaded show without showing the command first.

`tools/mcp_call.py` takes `MA3_MCP_URL` / `MA3_MCP_PIN` to talk to onPC on this Mac (its PIN is in
the onPC plugin window) without touching the console connector.

**Later the same day (2026-11-08, during the second service): I froze the console.** Aaron asked for
a systematic study of the MA help ("every feature, menu, setting, toggle") compared against what we
have, and a fast way to sort large amounts of show data. I downloaded the help (1,574 pages) and,
without asking, started a "class census" script against the live console. One read never returned
and the GUI froze mid-service (playback and timecode kept running); Aaron had to restart. He turned
both plugins off. His words: "YOU CAN NOT DO THIS AGAIN" and "We can NOT allow the MCP plugin to
behave in a way that allows it to crash the console". Rules: "Console safety" above. Facts:
`docs/research/2026-11-onpc-facts.md`, last section.

- **Built, not installed: plugin 0.2.0-alpha.6, the console guard.** Aaron approved it 2026-11-08
  ("console guard approved"), including Lua off at every start on the console. Allow-list by class
  path on a console, call journal + automatic quarantine after a stall, 8 requests/s cap, bounded
  dumps, runaway-Lua stop, `;`-chained commands checked segment by segment. Added the same day while
  studying the help (holes the study found):
  - refused keywords matched with MA's shortcuts (`Lu` = Lua, `R` = Reboot), and the list now covers
    restart, shut down, software, session, login and menu commands (`Reboot /NoConfirmation` was
    possible before);
  - unquoted parentheses (text-input pop-up) and unquoted `$variables` (unchecked expansion) refused;
  - on a console, object keywords that reach outside show data refused (`StationSettings`, `View`,
    `CurrentUserProfile`, ...);
  - a client can no longer reach the plugin's own arguments (`lua on`, `quarantine clear`) through
    `ma3_command`.
  Design: `docs/superpowers/specs/2026-11-08-console-guard-design.md` (addenda at the end of section
  1). 3,352 tests pass on 5.5 and 5.4; installed in the onPC library (`make install-onpc`).
- **Next for alpha.6:** onPC bench (install, start, then find
  the object that hung by walking the suspect branches on onPC with the journal on); only then the
  stick for the console.
- **alpha.5 is on the MA3 stick (`datapools/plugins/`) and must not be imported**: it turns Lua on
  by default and has no guard. Replace it with alpha.6 next time the stick is here.
- **Plugins on the console: both OFF** since the freeze (Aaron). Do not ask to start them for
  research; the console is for his jobs.
- **Help study: done offline (2026-11-08, evening).** Every chapter of the MA help 2.5 is studied
  into a topic page with evidence marks (`docs/atlas/topics/INDEX.md`); the `ma3-console` skill
  routes questions to them. `docs/atlas/topics/keywords.md` is a generated index of all 444
  keywords (`python3 -I tools/atlas/keywords.py`). The checklist (`docs/atlas/CHECKLIST.md`) now
  counts the topic pages: 2,204 of 7,533 items named, 441 ticked; ticks need the onPC census (R)
  and desk use (P). What the study left for the bench is in each page's "To bench on onPC" and in
  the roadmap's unknowns ledger.
- **Show-file lineage:** a `.show` file's header lists its save history (name + time per save).
  It showed `Christmas 2026` was split from `Late 2026` on 2026-10-22, and `Late 2026 2` came from a
  later `Late 2026` save (2026-10-31): the dimmer curves were most likely made in between, so
  nothing "dropped" them. Script: `tools/showfile/lineage.py`. The body is MA's packed binary format
  (not parsed). Unconfirmed with Aaron.
- **Show files leave the console by USB stick:** Aaron copies them "later this week" (2026-11-08);
  SFTP is not the route for now.
- **Aaron's read of the curve job:** "I didn't feel you were confident in your existing knowledge
  about the curves and how to fix it." The gap was knowledge, not a missing data point. Answer:
  study a feature's help chapter completely before a job on it (`docs/atlas/`), starting with DMX
  curves (`docs/atlas/topics/dmx-curves.md`).
- Still open from earlier today: the Cue Display grid check with timecode and a song; the roadmap's
  six decisions.
- **Asks for Aaron from the study (not yet answered):** with the stick in, run `ListCrashLog` /
  `CopyCrashLog If Drive 2` / `DumpLog` at the desk for any trace of the freeze; whether his console
  has OSC "Receive Command" on (anything on the network could then run commands, plugin or not);
  before any onPC bench, onPC must be Standalone or in its own session, never the console's.

- **How Aaron has been working with me on the console (his actual practice this session):** he asks
  for a specific change in a sentence and expects it done: backup first, one undo group, verify from
  a fresh read, then tell him the choices I made and how to undo. He reacts and I adjust ("those are
  small ... default size"). I stopped to show a plan only where the job was big or destructive
  (stage flip, first Portman layout). Deleting, rewriting cues, or patch changes still need a shown
  plan and a go. Save the show only when he asks or as part of `/save`.
- **He edits the show himself between my jobs** (Layout 1, and by this evening the pages: Weekend
  Base is Page 1, Christmas 1-5 are Pages 8-12). Always read fresh before planning and check the
  plan still matches right before sending. Layout rules are in `docs/CONVENTIONS.md`, "Layouts".
- **Open, none urgent:** one console restart with the USB stick out (proves both plugins survive);
  the items under "Open items". Tornado XYZ is closed. The `Test` LEDs stay out of group 706. Cue
  Display on the console still reports 2.0.0 (same code as 2.0.1).
- **Reply format:** his global rules (label-first headings, tight budgets, no emojis, fun fact
  after a rule) plus this session's writing rules: short sentences, no em-dashes, links as
  `[text](relative/path)`.

## Read first

- `README.md`: what it is, tools, install, build.
- `docs/GAPS.md`: what the MCP cannot see or do yet, the rule when a new miss turns up, the MCP user,
  the API reads benched on onPC. Read before any plugin work.
- `docs/atlas/README.md` + `CHECKLIST.md`: every item of the MA help (7,533) checked against what we
  know, can read and have proven; the open items are the to-do list. Rebuild with `tools/atlas/checklist.py`.
- `docs/atlas/topics/`: deep pages per feature, every statement with its evidence (DMX curves first).
  MA's own Lua (system tests, API metadata, menus) ships with onPC at
  `~/MALightingTechnology/gma3_2.5.1/shared/resource/`: read it before guessing any syntax.
- `docs/research/2026-11-08-fast-show-analysis.md`: how to sort many shows fast (show database, lineage, onPC snapshot).
- `docs/ROADMAP.md`: the standing plan toward Aaron's goal ("access, control, and insight to every
  single bit of this console"), with the digging protocol and the unknowns ledger. Every session
  that moves it forward updates its ledgers.
- `docs/CONVENTIONS.md`: how Aaron's showfile is organized. Every job reads it. No open questions.
- `.claude/skills/ma3-console/SKILL.md`: the map to everything we know about the console (topic
  pages, MA's own Lua, the help download); use it before any console question or job plan.
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
| Plugin on the console | **0.2.0-alpha.8 since 2026-11-21** (console and onPC; alpha.7 ran for an hour before it), imported by Aaron on onPC, Lua off on the console (confirmed by `ma3_status`). GitHub: 0.2.0-alpha.9 is the newest pre-release (2026-11-22; alpha.8 plus one hardening, not on a station). |
| Cue Display plugin (`../MA3 Cue Display/`) | Fixed and re-imported as `Plugin 38`, verified; released as 2.0.1 (the console copy still reports 2.0.0 until the next import). Details in that project's CLAUDE.md. |
| Stage model | Imported from Capture as MVR; Aaron switched its 3D selection off himself. |
| Portman layout | 90 elements + box in Layout 1. Aaron re-arranged them (master with two hexes stacked below); scaled to 45 x 45 to fit the default 1920 x 1080 area. |
| Agenda | 15 entries for the Christmas 2026 run (`Agenda 14-28`). |
| Q40 block in Layout 1 | 11 panels at default 50 x 50, master to the left of its 2 x 2, three rows from today's rig, in the slot between `R1` and `Key`. |
| Group 706 `Ladder LEDs` | All 600 ladder LEDs, one ladder per selection-grid row. Aaron confirmed the number and that the `Test` set stays out. |
| Tornado XYZ | Closed: not possible for a five-head bar as one fixture, and Aaron dropped it (2026-11-05). |
| Tornado rings and yokes in Layout 1 | Ring masters with 960 ring sections as tiny rings, yoke masters with 120 yoke sections as cells, each in a column hanging below its master, rows 200 apart (Aaron's own re-spacing of the rings set that pattern). Verified. |
| Release | 0.2.0-alpha.9 published on GitHub as a pre-release (2026-11-22). The stations run alpha.8. `make release` writes `dist/MA3-MCP-<version>.zip`; bump `M.VERSION` in `src/main.lua` and `Version` in `plugin/MA3 MCP.xml` (0.2.0.N) together. |
| Timecode pool | 28 shows, one per song, same number and name as the song sequence (1-13, 54-68), each with one track targeting the song. No events yet. |
| Cue Display grid view (timecode + fades) | 2.1.0 runs on the console (after a bundler fix) and is on GitHub as a pre-release; timecode rolling and a running song still to be checked on Sunday 2026-11-08. |

Job records:

| Folder | What |
| --- | --- |
| `docs/jobs/2026-11-03-stage-flip.md` | Song pool cleared and rebuilt from Planning Center, November pages, Weekend Base. |
| `docs/jobs/2026-11-05-stick-delivery/` | Plugin alpha.3, Cue Display, stage MVR (`strip_layers.py`), Portman layout (`portman-layout-plan.md`, `plan_portmans.py`, `run_portmans.py`). `README.md` is the day's log. |
| `docs/jobs/2026-11-05-tornado-xyz/` | `FINDINGS.md`: the rules MA applies before it allows XYZ on a DMX mode, and why the Tornado cannot have it. Scripts for the scratch-copy build. |
| `docs/jobs/2026-11-05-agenda/` | The agenda entries and the proven Agenda syntax. |
| `docs/jobs/2026-11-05-tornado-rings-layout/` | Ring sections arranged against their masters in Layout 1 (`rings.py`). |
| `docs/jobs/2026-11-05-tornado-yokes-layout/` | Yoke sections under their masters, same pattern (`yokes.py`). |
| `docs/jobs/2026-11-05-portman-resize/` | Portman block scaled to 0.9 to fit the default layout area (`resize.py`). |
| `docs/jobs/2026-11-05-ladder-group/` | Group 706 `Ladder LEDs`: all 600 ladder LEDs, one ladder per selection-grid row. |
| `docs/jobs/2026-11-05-q40-layout/` | Q40 block in Layout 1: old show's look, today's rig arrangement from patch positions (`q40.py`). |
| `docs/jobs/2026-11-05-song-timecodes/` | One timecode show per song (PCO 1-13, Christmas 54-68) with a track on the song sequence; proven Timecode syntax. |
| `docs/jobs/2026-11-19-tornado-odd-even/` | Groups 608 `Yoke Sections Odd` / 609 `Yoke Sections Even`: every other yoke of 606 on a two-row grid, for opposing tilt chases; why MAtricks XGroup does not do it. |
| `docs/jobs/2026-11-19-ladder-layout/` | Ladder LEDs (650 pixels on the platform) drawn in Layout 1 from his place groups; dimmer tiles moved to the `Key` box (`ladders.py`). |
| `docs/jobs/2026-11-21-nov29-songs/` | Sequences 10-13 programmed from his own cues (status copies per role, holds empty); `build.py` plans, runs and verifies. |
| `docs/jobs/2026-11-21-mcp-view.md` | The MCP user's one view on onPC and how windows are made by command (`Store ScreenContent`). |
| `docs/jobs/2026-11-21-dimmer-rows/` | Dimmer tiles back in his two rows, in a `Dimmers` box between `Era` and `R1` (both tightened); first job sent through onPC as the MCP user. |
| `docs/jobs/2026-11-21-nov-22-weekend.md` | Four songs for Nov 22 (Sequences 14, 15, 16, 18) on Page 4.106-109; made by copying an empty sequence so his programmer is never stored. |
| `docs/jobs/2026-11-08-dimmer-curves/` | Two DMX curves and 11 dimmer assignments lost between show files, restored from the old file; where MA keeps curves, the Parameter List quirk, proven Patch-window command syntax, the stick-import open item. |

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

## Cue Display grid view (timecode + fades): on the console, Sunday test pending

Aaron wants the Cue Display page (`../MA3 Cue Display/`) to also show timecode and fades. Paused
2026-11-05 afternoon, resumed that evening ("lets continue working on the cue display plugin").

**Decided, in his words:** show timecode slot 1 and slot 2; "the fades for any cue running"; one
frame at a fixed size so a single OBS crop never changes ("one big piece for one single OBS crop");
inside it the boxes pack tight from the centre; "ideally it's just song and key sequences"; from
the first mockup, "I think B, but can we have 8 slots of sequences instead of 4" (B = the block:
timecode clocks on top, sequence boxes below).

He then picked "B2 please": 1280 x 800, two boxes across, four rows, the big text. Then, on seeing
it: "Can everything stay where it is? ... time code always at the top ... always that 4 x 2 grid,
just with placeholders until a sequence occupies it? So things don't move around and shuffle as
sequences fire?" That overrides "pack from the centre": clocks pinned to the top, eight slots
always drawn, a sequence keeps its slot while it runs (my rule, in the design: previous slot if
empty, else lowest empty slot; a ninth waits; a stopped one leaves a placeholder at once).

**Approved and built (2026-11-05, late evening).** He answered "approved" to the five-point
summary (the `/grid` address with the old views untouched; sequences 1-89 in fixed slots; the fade
bar is the programmed fade and does not follow the executor time fader; timecode good to a frame
or two; the console timecode check needs him). Design, plan and code are in the Cue Display
project (`docs/superpowers/specs/2026-11-05-grid-timecode-fades-design.md`, `.../plans/
2026-11-05-grid-timecode-fades.md`); its CLAUDE.md Status has the verified and unverified lists.
One rule changed while building, in the design: a sequence that starts counts its first cue's
fade; only sequences already running when the plugin starts get no countdown. The final review
was mine, not a fresh reviewer's. `./run-fake-console.sh 1200 grid` in that project serves the
real page at `http://127.0.0.1:8090/grid`. He chose 2.1.0. The first build shut itself down on
the desk (the console's shared `package.loaded` served it 2.0's modules; fixed in that project's
`build.sh`); the rebuilt 2.1.0 runs. What is left is listed under "Resume here".

**My calls, shown in the mockups but not confirmed by him:** timecode as `HH:MM:SS:FF`; a stopped
slot stays in place, greyed, labelled stopped; each box = sequence name, cue number, cue name, a
bar that fills while the fade runs with a seconds countdown, then `fade N s`; a 0 s fade reads
`snap`; a ninth running sequence is not shown; which sequences count = running sequences numbered
1-89, configurable (last year's effect sequences 36-41 sat in that range too). Not yet shown or
asked: frame anchored at the page's top-left so a window capture crops the same at any window
size; a new URL for this view with the three existing modes left alone; whether delay and out-fade
matter to him.

**Console facts for the build:** `TimecodeSlot n` has `TIMESTRING` (`2h00m04:14`) and `TIME`
(seconds x 2^24). Slot 1 read the same value three times in a row, so live update while rolling is
still unverified. Cue fades are in the cue's Part 0 (`ma3_cue_timing` shows in/out fade, delays,
trigger). The plugin scans at 5 Hz, so a fade countdown would be timed from the moment the plugin
sees the cue change (up to 0.2 s late) using the cue's stored fade; it would not know about
executor time (`USEEXECUTORTIME` is true on his song sequences) or a rate master. Say so in the
design. Smooth timecode needs the page to run its own clock between samples.

**Mockups:** the brainstorming skill's visual companion, started with the Cue Display project as
its directory. Screens are in `../MA3 Cue Display/.superpowers/brainstorm/<session>/content/`
(`frame-shapes.html` = three shapes, `block-eight.html` = the two eight-slot blocks, `grid-b2.html` = B2 packed, `grid-fixed.html` = the look to build: fixed slots with placeholders); clicks land
in `state/events`. The server exits after 4 hours idle; restart it with the same project dir.
Brainstorming skill gate: no product code until he approves the description (in chat for a small
change, a written design otherwise). Version bump is his call.

## Tornado XYZ (closed 2026-11-05)

Aaron dropped it ("I think we're done with tornado xyz"). The record is
`docs/jobs/2026-11-05-tornado-xyz/FINDINGS.md`: MA allows XYZ on a DMX mode only with Pan on the outer
axis, a tilt axis with zero rotation relative to it, and the tilt pivot on the pan axis; and it
creates the XYZ controls for one pan/tilt pair per fixture, so a five-head bar cannot have it. The
only route would be splitting each bar into single-head fixtures. Do not reopen unasked.

## Open items

- Aaron asked 2026-11-05: could the MCP plugin be its own user, so Claude does not share his command
  line and screens? Not researched. Known: the plugin's commands run on the command line of the
  user who started it (`Root 20.1` lists `Cmdline 1` = User 5, `Cmdline 2` = User 2). Idea to test:
  a dedicated user/profile and the plugin started from a second station logged in as that user.

- **The PIN changes on every import** (2026-11-05 twice, 2026-11-06 with alpha.4), which costs a round trip each
  time and risks the lockout. Fix offered to Aaron, not yet answered. Background: the PIN was different after Aaron went Christmas 2026 -> Christmas 2025 -> back on 2026-11-05 (he
  said it is fine; `last_backup` was also empty, so the settings file was written fresh). Worth a
  look when next in the plugin: write settings to a temp file and rename; never regenerate when the
  file exists but fails to parse; do not count requests without an Authorization header toward the
  lockout; answer OAuth discovery/registration paths with a plain 404.

- Verified on the console: `ma3_commands` (2026-11-05, Portman layout), `ma3_export`, `ma3_history`
  (`lines_supported` is false on 2.5.1.1: the console does not expose command-line text lines),
  `ma3_timecode`, and the `from`/`to` filter on `ma3_sequences`.

- **alpha.4 pacing fix, built and verified on the console 2026-11-06** (timings under "Resume
  here"; only the desk's feel during a long read is unconfirmed). alpha.3 yielded once per
  50 pool slots visited, empty slots included, and one bare `coroutine.yield()` costs a console
  frame (about 31 ms, measured): the Page pool's 9,999 slots cost 6.2 s empty, so at 17 pages
  `ma3_sequences` used its whole budget building the executor index and returned nothing. alpha.4
  yields by elapsed time (`console.pace`, `SLICE_SECONDS` = 10 ms in `src/console.lua`), never
  returns `partial` without a row, starts the row budget after the index, adds
  `executors:false`, and makes `ma3_pages` budgeted with `{page:n}` reading one page. Regression
  tests in `test/tools_bulk_test.lua` and `test/console_pace_test.lua`; the fake console now has
  `yield_cost` and `work_cost`. If Aaron reports the desk stuttering during reads, lower
  `SLICE_SECONDS`. `ma3_commands` still yields
  every 10 commands on purpose (left alone; it is proven as it is).
- The optional pool-button Appearance is unverified on console hardware (`ma3_backup` is verified).
- Closed in alpha.6 (2026-11-08): the console does run `;`-chained commands (MA's example macro
  `Macro 2; Echo "..."`), so `ma3_command` now checks every segment and refuses page/executor ranges
  inside commands. Still worth an onPC check that the console's own parser splits the same way.
- Gap noted 2026-11-08, not fixed: `SendOSC` is allowed, and an OSC line with Receive Command on
  pointed back at the console would run its payload on the command line unfiltered. Decide with
  Aaron once we know whether his console has OSC Receive Command on (`remote-in-out.md`).
- Unproven on onPC: that the console resolves keyword shortcuts the way the help documents them
  (`R` = Reboot, `Lu` = Lua); the refusal assumes it does. Also: a macro a job runs (`Macro 5`) can
  still contain any keyword; jobs read macros, they do not run them.
- From the 2026-11-14 /save security review (below its confidence bar, bench on onPC): the guard
  treats both `'` and `"` as quotes; if MA quotes only with `"`, a single-quoted span could hide `;`,
  `(`, `$` or a refused keyword from the checks. And `calls_self` compares only the first number after
  `Plugin` (`Plugin 1 + 38`); `in_request` in Main still refuses the plugin's own arguments.
- `ma3_set` writes are not part of a `ma3_command` undo group; a job that sets executor
  properties should say so in its report. Idea: let `ma3_set` take `undo_group` too.
- Review minors deferred (see git history of the fix pass): no 4 MB response cap, `ma3_pages`
  ignores the time budget, bad-PIN rows not red, undo groups never closed by a client stay open.
- Future idea Aaron mentioned: build a simple song sequence from his existing programming. Not a job yet.
