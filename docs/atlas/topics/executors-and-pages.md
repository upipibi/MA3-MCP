# Executors and pages: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Executors", 5 pages, and 18 linked keyword pages),
39 of MA's system tests (`exec_*`, `page_*`, `special_exec_*`, `fadermaster`, `xkey`), MA's menu code,
the release notes 2.2 to 2.5, and our jobs. Study pack: `python3 tools/atlas/pack.py "Executors"
--terms executor,exec,page,special_exec,fadermaster,xkey`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What they are

- An executor is a handle (key, fader, knob, or on-screen copy) for an object; several executors can
  control the same object; a sequence on an executor still runs from the sequence pool [D].
- Numbering per page [D]:

| Row | Numbers | Hardware |
| --- | --- | --- |
| bottom | 101-190 | button only |
| second | 201-290 | button + fader |
| third | 301-390 | button + knob |
| top | 401-490 | button + knob |
| Xkeys | X1-X8 = 291-298, X9-X16 = 191-198 | buttons |

  A wing is 15 columns (3 sections of 5) x 4 rows = 60; six wings = 360, plus 16 Xkeys = 376 per page.
  Hardware may have fewer (compact: 2 x 5 columns) [D]. Our tools see 390 slots per page [C].
- **Pages:** up to 9,999 per data pool; active executors stay active when the page changes [D].
  `Store Page n "Name"` creates a page; Page+ / Page- create pages as they go [D]. Aaron's weekly
  pages are copies of Weekend Base (`Copy Page 1 At Page n`, then `Label Page n "Nov 8"`) [C:
  stage flip and later; numbers moved, read fresh].
- Page editor (pool, swipe, Edit): Render Style for all executors of the page, Import / Export, and
  every executor's assign menu [D].
- Labels above the executors (the playback bar) take the assigned object's appearance and scribble [D].
- Playback window: on-screen executors, 5x4 to 15x4 (one wing); settings for rows, labels,
  handles, `#Sections` (Auto, 1, 2, 3), Page, WingID [D].

## Executor configurations

- Key and fader setups saved in the Executor Configuration pool; each assignable object type has a
  default configuration (Menu > Preferences and Timings > Executor Config) applied when an object goes
  onto an **empty** executor. Assigning to an executor that already holds something keeps its handles [D].
- Assign menu title bar: Executor Config. select, Load (apply a configuration), Save (store the current
  handles into it). Changed handles show a cyan bar [D].
- Configuration editor: pairs of fader/encoder and key; Recast (push a saved change to every executor
  using the configuration; also the `Recast` keyword); List References; settings Name, Scribble,
  Appearance, Tags, Note, Width, Height (default size of a new executor), ExecConfigType [D].
- This is how Aaron's song executors could be set in one step instead of `ma3_set` per property
  (`HEIGHT` 2, `KEYPRESS` Off, lower half `KEYPRESS` Select, `FADER` Master): a configuration with
  those handles, set as the sequence default, would apply on assignment to an empty executor. [?]
  bench on onPC.

## Assigning

- Keys: `[Assign] [Sequ] 3 [At] [MA]+[Exec] 105`; command: `Assign Sequence 4 At Page 2.301` (the
  page must exist) [D]. Special executors and Xkeys the same way [D]. Used by our page jobs [C].
- Assign menu (Assign + executor key, tap a mini-executor label, or tap in the Playbacks window):
  title bar `Lock Executor` (no changes, playback still works) [D].
- Assignable types: Sequence, Master, Group, Macro, Quickey, Preset, Sound, World, View, User,
  UserPlugin, ScreenConfig, Timer; Empty clears [D]. DataPool picker in the title bar [D].
- **Handle tab:** Fix Executor (same as `Fix`), Render Style (Default / Pool: name, appearance,
  current cue / Executor: cue list), resize by the corners into empty neighbours, move by dragging the
  title (frame flashes green or red) [D].

### Trigger options and functions

- A key: press, release, MA+press, MA+release. An encoder: left, left/right value, right, and the
  same three with MA. A fader: move. With only the plain option set, MA+ still reaches it [D].
- Key and encoder functions: Empty, `<<<`, `>>>`, At (presets), Black (intensity off while held),
  Call (screen configs, macros), DoubleSpeed, FastSync, Flash (on at a virtual 100 % while held),
  Go+, Go-, Goto (pop-up), HalfSpeed, Kill, Learn, LearnSpeed, Load (pop-up), LogIn (users), Off,
  On, Pause, Rate1, ReSync, Select, SelectFixtures, Speed1, Swap, Temp (on while held, cue fades,
  master level), Time (executor time override on/off), Toggle, Top [D]. Some are greyed out per
  object and control (a sequence on an encoder cannot Flash, Black, Temp or Swap) [D].
- **Custom command** per key or encoder trigger: Use Custom Command, with **Add Executor** appending
  the executor (`Store` becomes `Store Page 1.101`) [D].
- Fader functions: Master (intensity, `FaderMaster`), X (crossfade current to next, `FaderCrossFade`),
  XA / XB (two-fader crossfade, mode in sequence settings), Temp, Rate, Speed, Time [D].
- MA + a fader or an Xkey is not a trigger: MA + an Xkey runs the keyword printed on it [D].
- Encoder resolution per encoder (Step Size 0.01 % to 100 %, a second resolution on MA + encoder
  when MA has no function, Invert Encoder) [D].
- Configuration pop-up in the assign menu: Insert New, Delete, List Reference, Recast Config
  (functions only, not width and height), Load, Save [D].
- Edit Setting tab = the object's settings pop-up (some settings only live there, for example a speed
  master's SpeedScale); Edit tab = the object's editor for sequences, macros, views, screen configs [D].

### Assigning functions by command [D]

- `Assign <Function> At Page p.e` or `Assign <Function> At Executor e`; secondary (MA) function:
  `Assign Pause At Page 8.405 /MA`; faders: `Assign FaderRate At Executor 209`.
- **Assigning a key function by command removes that key's release ("unpress") function**; the assign
  menu does not [D].
- An empty fader needs a property: `Set Page 1.201 Property "Fader" "Empty"` [D]. We set `FADER`
  `Master` and `KEYPRESS` with `ma3_set` in the weekly page job [C].

## Running playbacks and the Off menu [D]

- Running Playbacks window (Add Window > More): Sequences, Macros, Timecodes, Presets, Timers, Sounds,
  All; Touch Mode None / Off / Select; Hold List; Started by (user) and My Playbacks Only; counts x/y
  per tab; Sheet Style shows the Trigger column (what started it).
- Off menu: press Off twice; tapping turns off; buttons turn off all of a type; **Everything Off**.
- [?] Whether the running list is readable as objects (it would answer "what is running and who
  started it" without screen scraping). Cue Display reads sequence state directly [C].

## Special executors [D]

- The grand master knob and the keys, knobs, faders, encoders and wheels of the custom and master
  areas; assigned by default to masters; assignable like any executor (sequences, masters, plugins,
  groups, macros, worlds, views).
- Custom Master Section window (control bar icon, or Add Window > More): labels, hardware, Go+ / Go- /
  Pause for the selected sequence, Display Mode Text and Symbol / Text / Symbol / Auto.
- Special executor 5 is the grand master by default; its knob press can take a key function.

## Command reference for this chapter [D]

| Keyword | Syntax and notes |
| --- | --- |
| Executor | default function Select; unsupported functions pass to the key, fader or assigned object. `Delete Executor 205` removes the **assignment only**; `Delete Executor 205 Cue 3` deletes a cue of the assigned sequence; `Select Page 4.102`; `Set Executor 201 "Key" = "Flash"` |
| Page | `Page 2`, `Page "Ray"`, `Label Page 2 "Ray"`, `Next Page`; a page must exist before it is called; `/Tab` |
| At | `FaderMaster Sequence 1 At 30`; `At Cue 3` (selection takes cue 3's values); destination At source |
| Call | `Call ViewButton 2.1`, `Call Macro 2`; `/Screen` |
| FaderMaster | `Assign FaderMaster At Executor 204`; `FaderMaster 205 At 50 Fade 5` (only sequences and presets fade the master; others snap); `/Type` |
| FaderCrossFade (A/B) | `Assign FaderCrossFade At Executor 302`; `FaderCrossFade Sequence 5 At 10` |
| FaderRate, FaderSpeed, FaderTemp, FaderTime | `FaderRate Sequence 1 At 100` (= 1:1); `FaderSpeed Sequence 2 At BPM 6`; `FaderTemp Sequence 2 At 42`; `FaderTime Sequence 5 At 10` |
| Fix | `Fix On Executor 101 Thru 105`, `Fix Executor 103` (toggle) |
| LogIn | `LogIn "User" "password"` (assignable to a key) |
| Off | stops an executor; also knocks values out of the programmer: `Off Sequence 1`, `Off Fixture 2 + 4`, `Off Loaded` |
| Recast | `Recast Configuration n` pushes a configuration's handles to every executor using it; `Recast Preset 21.1` (absolute layer only) |
| /MA | secondary function: `Assign Pause At Page 8.405 /MA` |

Commands that move a fader or fire playback (`FaderMaster ... At`, `Go+`, `Off`, `Kill`, `Swap`)
change the live stage. Jobs never send them; reading executor state is enough for every job so far.

## What MA's own tests add (39 tests) [M]

- Executor handle properties MA sets by command: `Width`, `Height`, `Key`, `Fader`, `Encoder`,
  `EncoderLeft`, `EncoderRight`, `MAKey`, `EncoderLeftCommand`, `EncoderRightCommand`,
  `EncoderLeftAddExecutor`, `EncoderRightAddExecutor`; for example `Set exec 201 property "Height" = 3`,
  `Set exec 201 property "Fader" = "Temp"`, `Set exec 301 property "EncoderLeft" = "Go-"`,
  `Set exec 401 property "MAKey" = "Toggle"` [M]. On the console we have read and set `HEIGHT`,
  `WIDTH`, `KEYPRESS`, `FADER`, `OBJECT` [C]; [?] whether `Key` is an alias of `KEYPRESS` (bench).
- Executor configurations by command: `Set Configuration 1 Property "Height" 2` [M].
- Pages: `Store Page 2`, `Store Page n "Name"`, `Copy Page 1 At Page 3` [M, C], `Move Page 1 At Page 2`,
  `Insert Page`, `Delete Page 1` [M].
- Executors: `Move Exec 101 At Exec 102`, `Move Executor 202 + 203 At 301`, `Fix Exec 101`,
  `Fix Off Exec 101`, `Assign Flash Exec 201`, `Assign FaderMaster At Exec 202`,
  `Assign Master 3.2 At Exec 107`, `Export Exec 101 "name"` (sequence, preset, group, macro, world,
  plugin, view, master assignments all export) [M].
- **MA's tests send `Delete Page 1 Exec 1 Thru`, `Delete Page 2 Thru` and `Delete Page 1.1 Thru /nc`.**
  On Aaron's console a Page/Executor range hung the desk (2026-11), and the plugin refuses `Thru`, `+`
  and `*` on page and executor addresses. MA's test shows are tiny; Aaron's has 9,999 page slots of
  390 executors. Never copy those forms; delete pages one by one.

## Traps and MA bugs worth knowing (release notes 2.2 to 2.5.1.1) [D]

- Fixed in 2.5.1.x: in a session, executor functions Select, SelectFixtures and Call (of a plugin)
  did not work; `Goto DataPool 1 Page 1.205 Cue 5` went to the wrong cue; exporting an executor could
  lose the first character of a handle in its custom command; widened executors opened the assign
  menu only on the original cell.
- Fixed in 2.5: **Lua `FromAddr('14.14.1.12.1.101')` on executors could crash the software**;
  `Move DMXUniverse 492 Thru 882 At 100` then Oops could freeze the UI; an empty handle (`Store #[]`)
  could crash; several custom commands on one executor displayed only the last but ran all; custom
  commands on special executor 5 did not run; keyboard shortcuts ran commands under desk lock;
  double-tapping an executor configuration in the assign menu overwrote it; a valid command could
  report "illegal property" yet still run (so an error reply does not prove nothing happened).
- 2.5 features: **`Locate`** (`Locate Page p.e`, or hold List and tap an executor) finds where an
  object is assigned and cycles through its pages; Render Style per page; `FaderMaster Group * At 100
  /Type "Positive"`; Program Time and Executor Time readouts are now seconds.
- 2.4: executor configuration editor; MSC (MIDI Show Control) maps executors with start indexes per
  row; MSC can set fader positions with a time.
- Executor configurations exported from 1.2 or older cannot be imported [D].
- Our rules: never a range (`Thru`, `+`, `*`) on Page or Executor addresses; the plugin refuses them
  (`[unsafe-range]`) [C].

## Procedures

**Weekly page (proven, 2026-11-03 onward) [C]:** read the pages fresh (numbers move), `Copy Page <Weekend
Base> At Page <next free>`, `Label Page n "Nov 8"`, `Assign Sequence s At Page n.106` to `.109`, then
per new executor `HEIGHT` 2 and `KEYPRESS` Off on the 1xx, `KEYPRESS` Select and `FADER` Master on
its lower half (2xx). `ma3_set` writes are not in the undo group (say so in the report).

**Better, to bench first [?]:** an executor configuration that holds Aaron's song-button handles,
set as the default for sequences, would make every `Assign Sequence ... At Page n.10x` come out right
in one command, and `Recast Configuration` would fix every page at once if the handles change.

## What we have proven

- Reading: `ma3_pages` (budgeted; `{page:n}` reads one page), `ma3_sequences` executor index,
  `ma3_object` on `Page n.e` (`OBJECT`, `KEYPRESS`, `FADER`, `WIDTH`, `HEIGHT`) [C].
- Writing: Copy Page, Label Page, Assign Sequence At Page, `ma3_set` on executor properties [C].
- A Page/Executor range once hung the console (refused in code since) [C].

## To bench on onPC (none of this on the console)

1. `Key` versus `KEYPRESS`, and every handle property from MA's tests: read an executor with
   `ma3_object {schema:true}` before and after `Set Exec 201 Property "Key" = "Pause"`.
2. An executor configuration with Aaron's handles; set it as the sequence default; assign a sequence
   to an empty executor; read back.
3. `Recast Configuration n` across two pages.
4. `Locate Page p.e` output (does it return anything readable to the plugin?).
5. Whether the running playbacks list is readable as objects.

## Plugin access today, and gaps

- Can read: pages, executors and their assignments and handle properties; can write by command [C].
- Gaps: no tool lists executor configurations or reads which configuration an executor uses
  [? object path]; running playbacks and "who started it" are not read; special executors' paths
  are unmapped [?].
