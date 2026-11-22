# Cues and sequences: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Cues and Sequences", 19 pages, and the 40 keyword
pages it links), MA's own system tests and menus shipped with onPC 2.5.1.1 (67 tests), the release
notes 2.2 to 2.5, and our own jobs. Study pack: `python3 tools/atlas/pack.py "Cues and Sequences"
--terms cue,cuepart,sequence,tracking,playback`.

Evidence marks: **[D]** documented in the MA help · **[M]** used in MA's own shipped Lua ·
**[O]** proven on onPC · **[C]** proven on the console · **[?]** not proven.

## What it is

- Values live in presets or cues; cues live in sequences; executors are handles that play a
  sequence back [D]. All sequences sit in the sequence pool (`Sequence n`) [D, C].
- A cue has at least one step (more than one = a phaser) and at least one part: **part 0 exists
  in every cue; all values are actually stored in parts** [D]. Extra parts are sub-cues with their own
  timing that always trigger with their cue [D].
- Every sequence has an automatic **Cue Zero** (can store defaults for none, dimmers or all
  attributes of the sequence's fixtures, per sequence setting) and an **OffCue** whose timing is used
  when the sequence is turned off; OffCue has Release on by default [D]. Our tools report both and
  exclude them from `cue_count` [C].
- Cues can hold hard values, preset references and recipes [D]. Aaron's songs use hard values (they
  stay valid for the life of a stage design) [C: CONVENTIONS].
- **Shared data:** two sequences can share cue content and cue settings (not sequence settings),
  e.g. a light and a video programmer each with filters on one shared sequence [D].
- Input filter (what may be stored) and output filter (what plays back) per sequence: a world or a
  filter [D].
- Sequence pool: Executor Style display, pool action, per-object "object action" [D].

## Tracking (the rules everything else rests on)

- Only changes are stored; a value tracks until changed, released, or the tracking stops [D].
- **Blocked** value: stored again with the same value as the tracked one; protects that cue from
  earlier changes. `Unblock Sequence n` (optionally `Cue m`) removes redundant blocked values [D].
- **Release** column (cue setting): from this cue on, tracked values are released from the sequence;
  the attribute goes to another sequence's value (priority decides) or to its default [D].
  Storing with `/Release` empties the cells instead of storing values [D].
- **Tracking off** (sequence setting): tracked values become releases [D].
- **Cue Only** (`/CueOnly`, `/CO`, store options, Store Cue pop-up): stores the programmer into the
  target cue only and blocks the old values in the next cue (part chosen by three rules: part 0;
  a part with the same name; a part already holding that feature group). Not into the last cue [D].
- **Tracking Distance** (cue column): track only to and including cue N (absolute, survives
  renumbering of the cue) or to cue number + delta (Δ+; moves when the cue is renumbered) [D].
- **Tracking Shield** (store mode `↑0` or `>0`): when storing or copying, keeps future cues' look by
  blocking the old tracked values in the next cue where the dimmer rises from 0 (`↑0`) or is above 0
  (`>0`) [D].
- **Break** (cue column): a filter or world (static filters only) that stops *new or changed*
  tracking from passing that cue, without releasing what already tracks (unlike Release) [D].
- **Assert** (cue column): None / Assert (tracked values act as stored, with their original timing) /
  X-Assert (with this cue's timing) [D].
- **Allow Duplicates**: several parts of one cue may hold the same attribute; the highest part wins [D].

## The sequence sheet (columns = cue and part properties)

The sheet shows cues and parts as rows; most cells are editable and every edit changes the show [D].
Columns [D], with the object property names we have read on the console where known [C]:

| Column | Meaning | Property |
| --- | --- | --- |
| Lock | `UL` user lock (protects content and settings); `PL` system lock | `LOCK` [C] |
| No / Part / Name | cue number, part number, name ("cmd" marker when a command is active) | `NO` (thousandths: 1000 = Cue 1) [C], `NAME` |
| Trig Type | Go (needs Go+, Goto, Go-, >>>, <<<, Kill), Time (after the previous cue was *triggered*), Follow (after the previous cue *finished* its transition), Sound (one of 22 bands), BPM | `TRIGTYPE` [C] |
| Trig Time | time for Time; extra wait for Follow | `TRIGTIME` [C] |
| Duration | longest fade plus delays; read-only; used by Follow | |
| CueIn Fade / CueIn Delay | fade and delay for rising dimmers and all non-snap attributes | `CUEINFADE`, `CUEINDELAY` (Part 0) [C] |
| CueOut Fade / CueOut Delay | fade and delay for falling dimmers; default "None" = same as In | `CUEOUTFADE`, `CUEOUTDELAY` (value `CueTiming` when linked) [C] |
| Snap Delay | when snap attributes change | `SNAPDELAY` [C] |
| Release, Break, Assert, Allow Duplicates, Tracking Distance | see Tracking | |
| Sync, Speed Master, Speed Scale, Morph, Delay To Phase | phaser behaviour; a cue's speed master beats the sequence's | |
| Transition | fade path (see Cue Timing) | |
| "<Preset type>" Fade / Delay | per preset type timing for the cue | |
| Command / Command Enabled / Command Delay | command run on the GlobalMaster, IdleMaster or standalone station when the cue triggers | `COMMANDDELAY` [C] |
| Note | multiline note | `NOTE` |
| MIB Preference, Mode, Target, MultiStep, Fade, Delay | Move In Black | `MIBMODE` [C] |
| Indiv Fade / Delay / Duration | read-only summary of individual attribute timing | |
| Appearance, Individual Timing (Default or Normalized), Tags | | |

- If an OffCue gets a trigger type, Wrap Around is disabled, and the reverse [D].
- Executor time or a manual crossfade overrides stored cue timing; the sheet header then shows
  yellow text and `!` next to the time [D]. Aaron's song sequences have `USEEXECUTORTIME` on [C].
- Sheet settings that matter for reading: Track Sheet mode (values per attribute), Cue Only for edits,
  Layer, Readout, Countdown, Link Type (Fixed, Selected, LastGo) [D].
- **Content sheet**: the values stored in one cue (Current, Previous, Next or a Manual cue), parts in
  frames with Show Parts, "DUP" marks duplicate data in another part, Show Tracked hides tracked
  values [D]. The plugin's equivalent is `ma3_export` of the sequence plus `tools/cue_values.py` [C].

## Sequence settings (each user profile has defaults: Load from Default / Save as Default) [D]

| Section | Setting | Values and what it does |
| --- | --- | --- |
| Label | Name, Scribble, Appearance, Tags, Note | shown in the pool and on the executor label |
| Label | Prefer Cue Appearance | the current cue's appearance replaces the sequence's on executor and layout |
| Label | Executor Display Mode | Data / Appearance / Data and Appearance |
| Start | Auto Start | playback On when the master leaves zero |
| Start | Auto Stop | playback Off when the master reaches zero |
| Start | Master Go Mode | None / Go / On (reload current cue) / Top; only when Auto Stop is off |
| Start | Auto Fix | active executor stays fixed across page changes; unfixed when switched off |
| Start | Cue Zero Mode | Off (default) / All Used Attributes / Only Used Dimmers |
| Start | Auto Stomp | an absolute value stomps a phaser from another playback |
| Playback | Tracking | on/off (off turns tracked values into releases) |
| Playback | Wrap Around | Go+ after the last cue returns to the first; off when the OffCue has a trigger |
| Playback | Release First Cue | puts Yes in the first cue's Release column |
| Playback | Restart Mode | First Cue / Current Cue / Next Cue |
| Playback | Cue Command | Enabled (per cue) / Force No / Force Yes; Temp fader and crossfader never run cue commands |
| Playback | XFade Reload | crossfader must return to 0 before the next crossfade |
| Playback | Output Filter | world or filter; one per sequence (all its executors share it) |
| Playback | Priority, Soft LTP | see Play back cues |
| Playback | Playback Master | an inhibitive master for this and other sequences |
| Playback | XFade Mode | Split (A/B as current/next masters) / AB (up/down crossfaders) |
| Playback | Object Action | None, Pool Default, Select, Flash, Go+, Temp, Toggle, Goto, Load, Top |
| Speed | Rate Master, Rate Scale, Speed Master, Speed Scale, Speed from Rate | individual or a global speed master; scales are fixed multipliers |
| Protect | Input Filter | what may be stored |
| Protect | Swap Protect, Kill Protect | ignore Swap / Kill |
| Protect | Include Link Last Go | on by default; off keeps the sequence out of LastGo sheets |
| Protect | Use Executor Time | the Exec Time master overrides stored timing (on for Aaron's songs [C]) |
| Protect | Off when Overridden | turns itself off once another sequence owns all its attributes |
| Protect | Lock Sequence | no changes; playback still works |
| MIB | MIB | Enabled (per cue) / Never / Force Early / Force UponGo / Force Late |
| MIB | MIB Mode | None / Early / UponGo / Late, for cues set to Default |

Property names behind these settings are not yet mapped one by one. [?] Map on onPC: read a
sequence with `ma3_object {schema:true}`, toggle each setting in the pop-up, read again.
Known on the console: `USEEXECUTORTIME` [C].

## Storing, updating and copying cues

- Default store target is a cue in the selected sequence; Store + an empty executor creates a new
  sequence, assigns it with defaults and stores Cue 1 [D].
- Second store without a number opens a pop-up: Create Second Cue, Overwrite, Merge, Remove,
  Release, Cancel, plus tracking (Tracking, Cue Only) and Shield options. The pop-up appears only if
  store options do not decide; through the plugin `/NoConfirmation` is added and options must be
  explicit [D, C].
- Cue numbers have three decimals (42 = 42.000; 5.2 comes after 5.11); range 0.001 to 999999.999 [D].
  The tools report thousandths (1000 = Cue 1) [C].
- `Store Cue n Sequence s` = `Store Sequence s Cue n`; `Store Cue n Executor e` stores into the
  executor's sequence [D]. Thru, + and - make ranges [D].
- Timing while storing: `Store Cue 4 CueFade "6" CueDelay "1"`; `CueFade 6/3` = in 6, out 3 [D].
- Labels while storing: `Store Cue 2 "Name"`; `Store Cue 2 + 4 "BO Scene 1"` numbers the labels;
  `Store Cue "BO*" /Merge` stores into every cue whose name starts with BO [D].
- Parts: up to 256 per cue; `Store Cue 2 Part 10`; one attribute in one part per cue unless Allow
  Duplicates (highest part wins) [D].
- Relative cues: `Store Cue Next /Merge`, `Store Cue Previous /Merge`, `Store Cue Next 3`; `Store Cue +`
  makes the next free whole number after the active cue (then .1, .01, .001; "Illegal index" when no
  room); `Store Cue + 0.5`, `Store Cue - 0.4` compute from the active cue [D].
- Overwrite removes what the cue held (tracked values from earlier cues are unaffected); Merge adds,
  new values win [D]. Store Remove removes the attributes active in the programmer [D].
- **Update** (key flashes when an active cue and programmer values exist): Update menu lists cue
  parts; Sequence Update Mode = Original Content Only (updates values where they were stored, possibly
  an earlier cue) or Add New Content; Sequence Mode filter All / Selected / Last Go [D].
- **Copy**: `Copy Cue a At b`; pop-up: Content / Status (incl. tracked) / Look (status where the
  dimmer is above 0, only the dimmer where it is 0); Tracking or Cue Only; Dimmer Cue Only; shield [D].
- Jobs never create, edit or delete Aaron's cues (CONVENTIONS); the plugin creates empty song
  sequences only (`Store Sequence n "Title"`) [C].
- **Copying a cue between sequences, proven on onPC 2026-11-21 (scratch sequence, MCP user)** [O]:
  `Copy Sequence 1 Cue 6 At Sequence 9990 Cue 4 /CopyCueSource "Status"` copies the whole look
  (tracked values included: 6,027 value nodes); `"Content"`, which is also what a bare copy does,
  copies only what the cue itself stores (5,403). Name, trigger and in-fade come along. A cue of his
  can be empty of values (`Pre Chorus` in Sequence 1 holds none), so a section's look is its status,
  never its content. No programmer and no output are involved.
- A status copy holds only what its source sequence had touched by that cue. In a new order, values
  from an earlier cue track through it: add `/CopyCueDestination "ForceRelease"` (or `"ForceDefault"`)
  so they are released [O, Sequence 12 on 2026-11-21; exported as `Absolute="Specials:Release"`].
  Empty cue: `Store Sequence b Cue m` from an empty programmer. Fade: `Set Sequence b Cue m Part 0
  Property "CueInFade" 2`. Trigger: `Set Sequence b Cue m Property "TrigType" "Follow"` [O].
- Copy details: Existing Values tracking into Destination = Retain / Replace With Release / Replace
  With Default; buttons Copy / Overwrite / Merge / Cancel [D]. Ranges: `Copy Cue 1 Thru 4 At Cue 11`
  keeps gaps (1,2,4 -> 11,12,14) unless a cue is in the way (then 11, 11.1, 11.3, fewest decimals);
  reversed Thru or mixed + ignores gaps [D]. Copy/Cut + Paste: content only, no options [D].
- **Cue recipes** (per cue part, Show Recipes in the sheet): lines with selection, values, MAtricks,
  filter, timing, phase and grid; editing a line auto-cooks with Merge Low Priority (lines without a
  group do not); `Cook <object>` with `/Merge`, `/MergeLowPriority` (default), `/Overwrite`,
  `/Remove`; without an option a pop-up asks; recipe values carry a green marker [D].

## Store settings and preferences (per user; hold Store about 1 s) [D]

| Area | Options |
| --- | --- |
| Data Source | Programmer (default) / Output (what leaves the desk, masters included) / DMX (incoming, patched channels only, non-default values) |
| Use Selection | Active For Selected / All For Selected / Active (default for programmer) / All (default for Output and DMX) |
| If Not Empty | Ask (factory default) / Overwrite / Merge / Remove / Release |
| Cue | Tracking / Cue Only; Dimmer Cue Only; Shield tracked values (Off, ↑0, >0) |
| Grid | Merge Mode: Append X / Off |
| Store | Look (all attributes of fixtures above 0 %, only the dimmer of fixtures at 0 %) |

Save Preferences / Load Preferences in the pop-up title bar. Default cue timings live in Menu >
Preferences and Timings > Cues (cue timings, preset timings, MIB preferences) [D]. These settings
change what a `Store` through the plugin does; a job that stores must say which options it passes
rather than rely on the user's preferences [?: no store job has run with options yet].

## Playing cues back

- A cue only runs through its sequence; a sequence need not be on an executor [D].
- `Go+` (next Go cue; `Go+ Cue n`; follows and timed cues continue), `Go-` (previous; with a cue number
  no follow-ons), `Goto Cue n` (also **asserts** tracked values, with Assert/X-Assert rules), `Load`
  then `Go+` (`Go+ Loaded` fires several sequences together), `Pause` (fades, delays, phasers; again
  to resume), `Top` (first cue), `<<<` / `>>>` (jump with Playback Timings, default 0 s; no follows) [D].
- `Goto Cue 4 Sequence 6` = `Goto Sequence 6 Cue 4`; `Go+ Executor 101` acts on whatever the
  executor holds [D]. Temporary timing: `Goto Cue 5 Fade 2` [D].
- **Priorities** (sequence setting), highest first: Super (above the programmer), Swap (intensity LTP
  above HTP), HTP (highest intensity wins, other attributes LTP), Highest, High, LTP, Low, Lowest [D].
- **Soft LTP**: when a second same-priority sequence takes over through its master, On fades from the
  old value with the master, Off jumps to the master-scaled value. Needs both sequences active; no
  effect with both masters at 100 % [D].
- None of this has been sent through the plugin. Cue Display reads running state (sequence on/off,
  current cue) every frame [C]; the MCP plugin has no playback tool and jobs never fire cues.

## Move In Black (MIB)

- Per cue part: tracking sequences preposition attributes of fixtures that will fade in from zero [D].
- Dimmer value **Hold** (calculator Specials, `Hold` keyword) behaves like 0 % without triggering MIB [D].
- KnockIn MIB (user profile): Off (only changed attributes go to the programmer) / Post (MIB'd
  attributes are activated so a store keeps the look) [D].
- MIB Fade priority: cue part, then attribute in the fixture type, then show global; MIB Delay: cue
  part, then global. Times come from the future cue where the dimmer opens [D].
- Columns: MIB Preference 0-100 (Never 0, Worst 1, Bad 25, Normal 50 default, Good 75, Best 100);
  MIB Mode Default / None / Defined (with MIB Target) / Early / UponGo / Late; MIB MultiStep Running /
  Paused; MIB Fade; MIB Delay [D]. Global MIB times and transition: Preferences and Timings > Timings [D].
- Sequence MIB overrides show in yellow with `!Late!` style marks in the column [D].

## Cue timing

Priority from lowest to highest: general cue times, feature group (preset type) times, individual
attribute times, Executor Time at the moment the cue fires, the rate [D].

- Six general times per part: CueIn Fade, CueIn Delay, CueOut Fade (falling intensities; default =
  in fade), CueOut Delay (default = in delay), Snap Delay, Command Delay (the only command delay) [D].
- Commands: `Cue n CueInFade t` (also CueOutFade, CueInDelay, CueOutDelay, SnapDelay, CommandDelay);
  `Cue 3 CueFade 5/8` (in/out), `Cue 4 CueFade 7` (out linked: "None"), `CueFade /3 CueDelay 1/` on the
  active cue [D]. Reading them: `ma3_cue_timing` [C].
- Feature group Fade/Delay columns default to the cue in time; falling intensity always uses CueOut
  Fade, never "Dimmer Fade" [D].
- Individual times come from the programmer at store; the Indiv columns show the maximum [D].
- Executor Time master: when on, replaces stored fade and delay; position read when the cue fires;
  sequences opt out with Use Executor Time off [D].
- Rate: scales running fades without changing stored times; `*` before affected times, `*Stopped`,
  `*0`; executor label shows 1:1, 1:∞, Stopped; `Rate1` resets [D].
- **50 timing masters** (0-10 s) can stand in for CueIn/Out Fade/Delay and feature group times:
  `Cue 3 CueDelay "Timing2"`, `Assign Master "Timing"."Timing1" At Page 1.216`, `Goto Cue 3 Fade
  "Timing3"`; read when the cue fires [D].
- Default cue timings: Preferences and Timings > Cues; Playback Timings (Goto, Go-, >>>, <<<) in
  > Timings, `CueTiming` = use the stored time [D].
- Transition per cue part: Linear (default), Slow, Slow+, Fast, Fast+, SCurve, Swing-, Swing, Swing+ [D].

## Renumbering and deleting

- **No command renumbers cues**; only the sequence sheet (select numbers, Edit, type). Order cannot
  change; a collision pushes later cues on [D]. So the plugin cannot renumber cues today [?: a Set of
  the cue's number property might; bench on onPC].
- `Delete Cue n` opens a pop-up (Tracking / Cue Only, Dimmer Cue Only, Shield); the last cue deletes
  without it (unless the sequence is running) [D]. Through the plugin `/NoConfirmation` is added, so
  the pop-up's defaults apply silently [C: the tool adds it] [?: which defaults].

## Command reference for this chapter (from the keyword pages) [D]

| Keyword | Syntax and notes |
| --- | --- |
| Assign | `Assign Sequence 1 At Sequence 2` **shares data** (not a copy); undo sharing: `Copy Sequence 2 At Sequence 3`, `Delete Sequence 2`. `Assign Appearance 1 At Sequence 2 + 3 + 4`; `Assign Off Tag "x" At Sequence 3` |
| Block / Unblock | `Block Cue 5 If Fixture 4 FeatureGroup "Position" EndIf`; without cues: the selected sequence; without filters: all fixtures, all attributes |
| CommandDelay | `Store Cue 3 CommandDelay 4`; `Cue n CommandDelay t` |
| Cook | `Cook Preset 1.1`; options /Merge, /MergeLowPriority, /Overwrite, /Remove, /Restart |
| Copy | default object type is Cue; options /CopyCueDestination, /CopyCueSource, /Default, /Look, /Merge, /NoConfirmation, /Overwrite, /Release; `Copy Group 2 At 6 Thru 8` |
| CueFade, CueDelay | `Cue 1 Thru 4 CueFade 5`; `CueFade 6/12`; `CueFade 3/` (in only); `Cue 1 CueFade 1h22m56.3`; arithmetic: `CueFade * 2`, `CueFade - 3` (on the current cue of the selected sequence) |
| CueInFade, CueInDelay, CueOutFade, CueOutDelay | `Cue 1 Thru 4 CueOutFade 5`; Out times only act on falling dimmers |
| Cut / Paste | `Cut Preset 4.1` then Paste: a move |
| Delete | `/NoConfirmation` |
| Fix | `Fix On Executor 101 Thru 105`; `Fix Executor 103` toggles |
| <<< / >>> | `<<< Sequence 3`, `>>> Executor 103`, `>>> Page 4` (every sequence on the page), `>>> Page 5.211`. Our plugin refuses Page ranges; never send `Page n` alone through these without a reason |
| Go+, Go- | `Go+ Executor 101`, `Go+ Macro 2`, `Go- Executor 101` |
| Goto | `Goto Cue 105 Executor 104`, `Goto Cue 10 Executor 201 Fade 2`, `Goto Cue Next`, `Goto Sequence 42 Cue Previous`; a given fade overrides cue timing |
| Hold | `Hold` on selected fixtures' dimmer: 0 % without MIB |
| Kill | `Kill Executor 102`: Go+ on it and switch off every other playback not Kill Protected. Dangerous in a service |
| Label | `Label Sequence 12 "Name"`; a free-standing number in the name is enumerated across several objects; no name opens a pop-up |
| Label (more) | forbidden characters in names: `\ " $ & * ? , . ; ^ { \| } ~` (we saw commas dropped [C]); `Label Fixture 1 Thru 10 "Mac700 1"` numbers them; `Label Preset "Color"."Red" "Dark Red"`; without an object: the current or given cue of the selected sequence, or the sequence when it is off (`Label 42` is ambiguous: avoid) |
| Load / Loaded | `Load Executor 114 Cue 5`, `Load +2 Executor 114`, `Load Previous Executor 114`; `Go+ Loaded`, `Off Loaded` |
| + / - | lists and relative values: `Delete Cue 1 + 2`; `At + 5`; `- Fixture 5 Thru 7` removes from the selection; `At - 10` (space = relative) |
| Next / Previous | fixture stepping; `Next Page`; `Load Next`; `/Wrap` |
| Part | `Store Cue 3 Part 2`, `Delete Cue 1 Part 3` |
| Paste | `Copy Cue 5` then `Paste Cue 15`; `/Date`; the pasted object includes edits made to the source after copying |
| Pause | toggles fades, timecode shows, macros: `Pause Executor 201` |
| Rate1 | `Rate1 Executor 105` |
| Sequence | options /CreateSecondCue, /DMX, /Merge, /Output, /Overwrite, /Programmer, /Release, /Remove, /Selection; `Block Sequence 5` |
| SnapDelay | `SnapDelay 4` on the current cue |
| Store | default object Cue in the selected sequence; first free pool slot when no number (First Index window setting moves it); options /Active, /ActiveForSelected, /All, /AllForSelected, /Ask, /Auto, /AutoFit, /CreateSecondCue, /CueOnly, /DMX, /Embed, /ForceGlobal, /Global, /GridMergeMode, /InputFilter, /KeepActivation, /Look, /MAtricks, /Merge, /NoConfirmation, /OddEven, /Output, /Overwrite, /PhaserData, /Programmer, /Recipe, /Remove, /Screen, /ScreenOnly, /Selective, /TrackingShield, /Universal, /Wait; `Store Cue 1 Thru 10 + 20 Thru 30` |
| Swap | `Swap Sequence 5`: plays it and pulls every other fixture's dimmer down (not Swap Protected). Dangerous in a service |
| Top | `Top Executor 105`, `Top Executor 105 Fade 3`, `Top Timecode 1` |
| Update | options /AddNewContent, /ForceGlobal, /Global, /InputFilter, /OriginalContentOnly, /Selective, /Universal; `Update Cue Previous 2`, `Update Cue - 0.1` (existing cues only) |
| /CueOnly | values `On`, `Off`, `OnDefaultNew`, `DimmerOnly`, `DimmerOnlyDefaultNew`: `Store Cue 6 /CueOnly "DimmerOnly"`; used by Cue, Delete, Store, Update |

## What MA's own tests add (67 cue and sequence tests, 2.5.1.1) [M]

The help is not the whole truth; these forms are what MA's automated tests send and check:

- **Cues can be renumbered by command**, despite the help ("there is no command or keyword to
  renumber cues"): `Set Cue 1 Thru 4 Property "No" 11`, `Set Cue 3 Property "No" "2.1"`,
  `Set Cue 1 Th 4 Property "No" "1.001"`; and `Move Cue 1 At 3`. Moving parts: `Move Cue 1 Part 2 At
  Cue 2 Part 0`, `Move Cue 2 At Sequence` [M]. [?] bench on onPC before any use; renumbering Aaron's
  cues is a cue rewrite and needs his go.
- **Several properties in one Set**: `Set Cue 3 Property "Assert" "X-Assert" "CueFade" 1`;
  `Set Cue 2 Property "MIBMode" "Early" "MIBFade" 0 "MIBDelay" 0`;
  `Set Cue "OffCue" Property "Command" "Fixture 1 At 50" "CommandDelay" 1 "CueFade" 0.7` [M].
  Even `Store Cue 2 Property "Assert" "X-Assert" "CueFade" 1` [M].
- Cue property names MA uses: `No`, `TrigType`, `TrigTime`, `TrigSound`, `CueFade`, `CueDelay`,
  `CueInFade`, `CueInDelay`, `CueOutFade`, `CueOutDelay`, `Release` (`1`), `Assert` (`"Assert"`,
  `"X-Assert"`), `TrackingDistance` (number or `""`), `AllowDuplicates`, `Break`
  (`Set Cue 5 Property "Break" At + Filter "Only Dimmer"`), `Command`, `CommandEnabled`,
  `CommandDelay`, `MIBMode`, `MIBFade`, `MIBDelay`, `Transition`, `Lock` [M].
- Break and filter assignment by command: `Assign World "All" At Cue 3`,
  `Assign Filter "Only Dimmer" At Cue 3` [M].
- Sequence property names: `Priority`, `RestartMode` (`"First Cue"`, `"Current Cue"`, `"Next Cue"`),
  `WrapAround` (`"No"`), `CueCommand` (`1`), `KillProtect`, `OffWhenOverridden`, `PlaybackMaster`,
  `SoftLTP`, `SpeedMaster`, `SpeedScale` [M].
- Show-wide playback timings: `Set ShowData.ShowSettings.DefaultPlaybackSettings Property 'TimingGoto'
  'CueTiming'` (also `TimingGoBack`) [M].
- Store preferences by command: `Set StorePreferences Property "ChannelFilter" "Active For Selected"`
  [M]. They live in the user profile, which the console guard refuses to read today
  (`ShowData > UserProfiles` is not on the allow-list): prove on onPC, then allow the
  `StorePreferences` branch so a job can check them before storing.
- Other forms: `Lock Cue 1` / `Unlock Cue 1`; `Extract Cue 1` (break preset links into values);
  `Cleanup Sequence Thru /NC`; `Selfix Sequence n`; `Export Cue 1 "name"`, `Export Sequence`,
  `import lib "<file>.xml" at <address> /NC`; `Off Seq Thru`; abbreviations `st`, `th`, `f`, `del`,
  `seq`, `exec`, `/nc` are all accepted [M].
- MA sends `Off Seq Thru` and `Off Exec Thru` in tests; our plugin refuses `Thru` on executor and
  page addresses on purpose (a range there hung the console in 2026-11). Never copy those.

## Traps and MA bugs worth knowing (release notes 2.2 to 2.5.1.1) [D]

- Fixed in 2.5.1.0, so they **can still bite on older shows or other desks**: `Goto DataPool 1 Page
  1.205 Cue 5` went to the wrong cue; cue commands with parentheses did not always run; in a session,
  many bump or follow sequences fired quickly could leave the output stuck; cue durations were wrong
  when a cue contained recipes (affects Follow timing); opening a sequence editor flooded the system
  monitor with Lua errors.
- 2.5 changes: Sync, Speed Master, Speed Scale, Morph and Delay To Phase are now sub-columns of a
  **Phaser** column in the sequence sheet; OSC commands separate sequence names and cue numbers with
  `;` instead of a space; Swap, Flash, Black and Temp can be applied to pool objects by keyword then
  tap-and-hold; tapping in Running Playbacks selects.
- 2.5 known limitation: **Recast only recasts presets into cues if the preset link is in the absolute
  layer.**
- 2.4: Preview mode (Prvw + a sequence) plays cues isolated from the output; storing or updating in
  normal mode can change live output (updating a running or earlier cue with tracking); Store into a
  pool with First Index set (for example 195) creates at that slot; `Unlock Sequence 1 /Recursive 1`;
  phaser recipe properties by command: `Set Cue 1 Part 0.1 Property "FadeX" "0 Thru 5"`,
  `Set Sequence 1 Cue 1 Part 0.1 Property "FadeFromX" "4"`.
- Our own rules (CONVENTIONS, console guard): never send Thru, + or * on Page or Executor addresses
  (`Off Page Thru`, `>>> Page 4` style ranges); Kill and Swap switch off other playbacks: never during
  a service; through the plugin every Delete, Store, Copy, Move, Assign, Off gets `/NoConfirmation`
  so dialogs never stall the screen thread [C].

## What we have proven

- Reading: `ma3_sequences` (with cues, executor index, `from`/`to`), `ma3_cue_timing` (Part 0
  fades, delays, trigger), `ma3_export` + `tools/cue_values.py` (values inside cues),
  `ma3_object` on sequences, cues and parts [C].
- Writing: `Store Sequence n "Title"` (empty song sequences), `Label Sequence n "Title"` (commas are
  dropped), `Delete Sequence 1 Thru 89` (stage flip), `Assign Sequence n At Page p.106` and the
  executor properties after it, `Assign Sequence n At Timecode n.1.1` [C].
- Never done by a job: storing, editing, deleting or renumbering Aaron's cues (CONVENTIONS).

## To bench on onPC (none of this on the console)

1. Sequence settings to property names: read a sequence with `ma3_object {schema:true}`, change each
   setting in the pop-up, read again. Record every name and value form.
2. `Set Cue n Property "No" m` and `Move Cue a At b` on a scratch sequence: does tracking, timecode
   targeting and executor state follow?
3. What `/NoConfirmation` chooses for Delete Cue (Tracking or Cue Only) and for Store into an
   existing cue (Ask, so which default?).
4. `Set Cue n Property "Break" At + Filter "..."` versus `Assign Filter ... At Cue n`.
5. Read `StorePreferences` (where it lives, its properties) so jobs can check them before a store.
6. `ShowData.ShowSettings.DefaultPlaybackSettings`: read its properties.

## Plugin access today, and gaps

- Can read: sequences, cues, parts and their properties; values inside cues (export); executor
  assignments; history. Can write any of the above by command [C].
- Gaps: no playback tool (deliberately: jobs never fire cues); store preferences unreadable on the
  console (guard); no tool reads the running state the way Cue Display does (current cue, fade
  progress) though the object properties exist [?]; renumbering is possible by command [M] but
  unproven.
