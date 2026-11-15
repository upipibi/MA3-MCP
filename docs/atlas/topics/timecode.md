# Timecode shows: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Timecode Show", 11 pages), MA's system tests and
menu code for timecode, the release notes 2.2 to 2.5, our song-timecode job
(`docs/jobs/2026-11-05-song-timecodes/`) and the Cue Display work. Study pack:
`python3 tools/atlas/pack.py "Timecode Show" --terms timecode,tc`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What it is

- A timecode show fires events and moves faders at times on a running clock; the clock is the
  session master's internal time or an external source [D]. Shows live in the Timecode pool [D, C].
- **Timecode slots**: a fixed pool of 16; each can listen to SMPTE (LTC audio), MIDI timecode or
  Art-Net timecode, or generate time itself; a show runs from a slot [D]. Our console: slot 1 at
  `S1<30 fps>`, offset 1h00m00 on new shows [C].
- Aaron's setup: one timecode show per song, same number and name as the song sequence (1-13,
  54-68), one track targeting the song; events are his [C: CONVENTIONS].

## Structure (object tree)

| Level | Class (console) | Address | Evidence |
| --- | --- | --- | --- |
| Show | `Timecode` | `Timecode n` (`DURATION`, `TCSLOT`, `FRAMEREADOUT`, offset) | [C] |
| Track group | `TrackGroup` | `Timecode n.1` | [C] |
| Marker track | `MarkerTrack` | `Timecode n.1.0`, markers `Marker` (`TIME`) | [C] |
| Track | `Track` (`TARGET`) | `Timecode n.1.1` | [C] |
| Time range | `TimeRange` (`START`, `DURATION`, `SPEEDFACTOR`) | `Timecode n.1.1.1` | [C] |
| Sub-track | `CmdSubTrack` (events) / fader sub-tracks | `Timecode n.1.1.1.1` | [C] |
| Event | `CmdEvent` (`TIME`, `CUEDESTINATION`, `EXECUTECOMMAND`, token) | `Timecode n.1.1.1.1.m` | [C] |
| Slot | `TCSlot` under `TimecodeSlots`; `TIME` = seconds x 2^24, `TIMESTRING` like `2h00m04:14` | `TimecodeSlot n` | [C] |

`Store Timecode n "name"` + `Assign Sequence n At Timecode n.1.1` creates the group, marker track,
track and one time range; `Store Timecode n.1.1` first makes two ranges [C]. Our reads:
`ma3_timecode {timecode}` (events with absolute times) [C].

## The timecode viewer [D]

- Window or pop-up editor (edit a pool object). Normal mode shows; **Setup** mode edits.
- Setup toolbar: Select Target (Time Ranges or Events); tools Select, Add, Minus, Move, Resize;
  selection Cut, Copy, Paste; Add Event at cursor, Add Multiple Events (interval), Add Marker (named),
  Quick Marker (+M, no name: useful while recording).
- Playback toolbar: start, previous marker (M<<), Stop, Pause, Play (listen to the slot and replay),
  next marker (>>M), end, **Record** (records executor actions into the show).
- Left columns for groups and tracks: Lock, No, Name, **Play** (mark to mute a track or group),
  **Rec** (mark to protect from recording), Appearance, Note, Tags, **Target**.
- Text mode columns: Name, TrackGroup, Track; for time ranges Start, Duration, Speed Factor (scales
  time, default 1); for events **Time** (inside its range), **AbsTime** (range start + time: when it
  fires), **Fade Override**, **FaderValue** (recorded fader steps), **Token** (the action),
  **Cue Destination** (Go+ with no destination fires the next cue), **Status** (for Flash and the
  like), **Execute Command** (cue commands on replay; default Yes; `---` = not overridable, only with
  Playback and Record = All Events).
- Text Mode All / Tracks / Selected / Markers, filtered by Selection Target. Views Text, Timeline, Both.
- Settings: which show (or `<Link Selected>`), cursor field (shows the slot fps), **offset field**,
  Last Event (Off / Track / All), Cursor Mode (Page / Center), timeline display toggles.
- Timecode encoder bar: Cursor, Marker, Track, TimeRange, Event (token or fader value), Start,
  Duration.

## Track groups, markers, tracks [D]

- Track groups are children of the show and hold tracks; markers belong to the track group.
  `Select Timecode 1.2` selects track group 2 of show 1. Delete: Delete + tap.
- Markers: vertical lines through all tracks of the group; name, appearance (needs a duration to
  show), note, tags; added in Setup with Selection Target = TimeRanges at the cursor.
- A track holds time ranges; ranges hold events; sub-tracks hold fader positions. Track targets:
  Sequence, Sound, Timecode, Timecode Slot, Preset, Group, Master (list continues below).
  Each track should have a target; changing the target of a track with events **breaks the events** [D].
- **Sub-tracks** hold fader movements; only created by recording (moving a fader or knob while
  recording); with Auto Start/Stop on, moving a master to and from zero also records cue events [D].
- **Sound track**: a sound pool object as target shows its waveform and plays with the show; no events
  on it; a warning icon marks a corrupt file [D].
- **Time ranges**: a new track gets one range the length of the show; ranges may overlap; events are
  children of a range and their Time is relative to the range start (AbsTime = range start + Time),
  so a repeated group of events can live in one range copied around; deleting a range deletes its
  events [D].

## Events [D]

- An event carries a **token** (the action) executed when the cursor reaches it; some tokens have a
  status (Flash On/Off).
- Recorded events show where they came from: timed or follow cue, a command (beside the diamond: run by
  the event; inside: run by the triggered cue), Auto Start/Stop from a fader, Off When Overridden, a
  macro, a toggle, DMX / MIDI / DC remote. Red command icon = commands disabled (Execute Command No,
  or the sequence's Command Enable off).
- **Manually added cue events only trigger follow cues, timed cues and cue commands when the show's
  Playback and Record setting is Manual Events** [D]. Manual Events is the default [D], so Aaron's
  hand-placed events in songs with follow cues behave; a show switched to All Events would replay only
  what it recorded. [?] read `PlaybackAndRecord` on his shows once onPC is up.

## Timecode slots [D]

- 16 slots (the settings list shows TCSlot 1 to 8 for a show's source); edited, never added, copied,
  deleted or moved. **Slot settings are not part of the show file and are not sent to other stations
  in the session.**
- Generator per slot: `Select`, `On` / `Go+` (start at the current time), `Pause` (stop, keep the
  time), `Off` (stop and reset) on `TimecodeSlot n`. The clock window's buttons do the same without
  command-line feedback.
- Slot editor: Label (Name, Scribble, Appearance, Tags, Note); Settings: Pre Roll (signal must run
  this long before use), After Roll (keep running this long after an external signal stops), Source IP
  (read-only), User Bits (do not change unless the timecode supplier says so), Restart Option for
  toggle (Continue / Reset); Generator: start time, end time, looped, frame unit; Colors (external,
  generator, after roll, off); Format (Default = user profile Time Readout, `10d11h23m45`,
  `251h23m45`, `10.11:23:45`, `251:23:45`).
- Cue Display reads `TimecodeSlot 1` and `2` every frame (`TIME`, `TIMESTRING`) [C]; whether `TIME`
  moves while the slot runs is still unverified [?].

## Creating a show and recording [D]

- Store or Edit on an empty pool object creates a show with default settings (Edit opens the pop-up
  editor, which lacks some viewer tools).
- **TC Slot** (show setting): `<Internal>` (runs from a Go on the show), `<Selected>`, or a slot.
  A new show starts Internal [D]; ours read slot 1 [C: our shows were made by command 2026-11-05;
  [?] check whether `Store Timecode` picked slot 1 or a user default].
- Record: `Record` keyword or the record button (Setup); with the time running, executor actions are
  recorded into tracks per target (sequence, preset, sound, group master, master, timecode, slot);
  stop with Stop or `Off` on the show. Recorded tracks land in the same group and range by default.
  With Record Remote Events and Playback and Record = All Events, cue-triggered actions (follows,
  cue commands) are recorded too.
- Manual: New Track Group (comes with one track and a range), New Track, set Target, then add
  events at the cursor or with the Add tool; Add Multiple Events with a count and interval. Sub-tracks
  cannot be made by hand.

## Show settings (EditSetting on the pool object, or Settings in the viewer) [D]

| Section | Setting | Values and what it does | Property (MA tests) |
| --- | --- | --- | --- |
| Label | Name, Scribble, Appearance, Tags, Notes | | `Name` |
| Time | TC Slot | `<Internal>`, `<Selected>`, a slot | `TCSlot` [M] |
| Time | Offset TC Slot | shifts the whole show: an event at 1m00 with offset 1h00m00 fires at 1h01m00 incoming. MA's advice for long shows: one show per number with its own hour (1h, 2h, ...) | |
| Time | Duration | length; with Auto Start/Stop it stops shows reacting outside their range | `Duration` [M] |
| Time | Cursor | current position | |
| Playback | Auto Start | starts when time arrives inside the show's range | |
| Playback | Auto Stop | stops when the time signal stops | `AutoStop` [M] |
| Playback | Loop Mode | for Internal time at the end: Loop / Pause / Off | `LoopMode` (`"Off"`) [M] |
| Playback | Switch Off | Playbacks Off (turn off what the show started) / Keep Playbacks | |
| Playback | Assert Previous Events | Yes asserts events before the cursor (jump in mid-song) | |
| Playback | Toggle Restart Option | Continue / Reset (renamed in 2.5 from Restart Option) | |
| Display | Time Display Format, Frame Readout | readout only (24, 25, 30, 60 fps or seconds) | |
| Other | User Bits | do not change unless the supplier says so | |
| Other | Lock | no edit or delete; play and copy only | |
| Record | Record Go | as Go (Go+, no assert) / as Goto(Status) (asserts) | |
| Record | Playback and Record | **Manual Events** (default: only user actions; follows run from the sequence; later cue-command edits are respected) / All Events (records and replays everything; cue commands frozen at record time, Execute Command shows `---`) | `PlaybackAndRecord` [M] |
| Record | Record Remote Events | record remote-triggered actions regardless of the global setting | |

Defaults for new shows: Menu > Preferences and Timings > Timecode. Global: Timecode Events Recording
From = Single User (default, only the user who started recording) or All Users [D].

## External time sources [D]

- SMPTE (LTC) and MIDI timecode: Menu > Connector Configuration: SMPTE Mode In/Out and the slot it
  feeds (`SMPTE TC`); MIDI TC Mode In / Out / In & Out & Thru and its slot. Several stations can feed a
  slot: the first to receive wins; with several in Out mode, the master transmits.
- Slot settings show the Source IP of the station providing time; "No Cable" can mean no network on the
  MA-Net interface, no show running on that slot, or time running on another slot.
- Art-Net timecode: Menu > DMX Protocols > Art-Net, Timecode tab; 16 streams by stream ID; Interface
  and Enable Input must be set.
- Received signals show an icon and a play mark on the slot; times in green.
- **onPC on a plain computer has no LTC input** [D]: SMPTE/LTC enters only through an LTC port
  (consoles, onPC command wing XT, I/O Nodes); onPC Local Settings' Audio In Device is the sound
  input (BPM, sound triggers), not a timecode reader. For onPC, LTC arriving as audio (for example a
  Dante channel) must be converted first: to MIDI timecode on a virtual MIDI port (macOS IAC Driver),
  picked in onPC Local Settings as MIDI In Device with a MIDI Timecode Slot; or to Art-Net timecode.
  Mac converters that read LTC from an audio input and send MTC: Lockstep, Source-LTC (Reader mode),
  LTCast (2026-11-14 web search, none tested) [?].

## Commands [D, M]

| Command | Use |
| --- | --- |
| `Store Timecode n "Name"` | new show [C] |
| `Assign Sequence n At Timecode n.1.1` | target the first track (creates group, track, range) [C] |
| `Select Timecode 1.2` | select track group 2 |
| `Record Timecode 3`, `Record Off ...` | record [D, M] |
| `Go Timecode n`, `Off Timecode n`, `Pause` | play internal time; Off ends it (and with Switch Off = Playbacks Off, its playbacks) [M] |
| `Top Timecode 1` | cursor to the start [D] |
| `Go TimecodeSlot 1`, `Off TimecodeSlot 1`, `Pause TimecodeSlot 1` | generator [D, M] |
| `EditSetting Timecode n` | open the settings pop-up [D] |
| `Set Timecode n Property "Duration" 1 "AutoStop" 0`, `... "LoopMode" "Off"` | settings by command [M] |
| `Set <track> Property "Target" "" /NC` | clear a track's target [M] |

**Building events by command (MA's own test #33162) [M]:**

```
Store Timecode n "Name"
Store Timecode n.1                     (track group)
Assign Sequence s At Timecode n.1.1    (track with target)
Store Type "CmdSubTrack" Timecode n.1.1.1
cd Timecode n.1.1.1.1                  (the command sub-track)
Store Property "Time" 12.5 "AbsTime" 12.5 "Token" "Go+"     (one per event)
cd root
```

Event properties MA reads and writes: `Time`, `AbsTime`, `RawTime`, `Token`, cue destination; the show
has `RawDuration` [M]. [?] On onPC: the token names, how to set `CueDestination` by command, and
whether this works on a show made with `Store Timecode` alone (our shows already have a range). This
is the route to place Aaron's events from a list (for example from Planning Center song sections)
without the editor; it writes his show, so it needs his go.

## Traps and MA bugs (release notes 2.2 to 2.5.1.1) [D]

- 2.5.1.1: in a session, recording on the master console entered events once per station.
- 2.5.1.0: remote events were recorded even with Record Remote Events off.
- 2.5: masters could not be recorded or assigned to tracks; an event moved to the last frame did not
  always fire; an OSC feedback loop to itself in TCP mode froze the UI during playback; Fade Override 0
  could not be typed into an empty cell; the TCSlot column in user profiles stopped at 8.
- 2.4: creating the first timecode in a session from the viewer disconnected every station; some cue
  commands did not run when a MIDI-timecode event triggered the sequence; Add Multiple Events could
  fire cues several times; record mode replayed differently from play mode; slots went from 8 to 16.
- Timecode XML exported from 1.3 or older cannot be imported.

## What we have proven

- Shows 1-13 and 54-68 created by command with one track on the song sequence [C]; `ma3_timecode`
  reads events with absolute times [C]; `TimecodeSlot n` `TIME` and `TIMESTRING` readable [C].
- Not yet: a song running from timecode with the grid view watching (planned for the Sunday test);
  `TIME` moving while a slot runs [?].

## To bench on onPC

1. Read every show setting's property name (`ma3_object {schema:true}` on a Timecode), especially
   `PlaybackAndRecord`, offset, Auto Start, Switch Off, Assert Previous Events.
2. The event-building recipe above on a scratch show and sequence; set a cue destination; play with
   the generator (`Go TimecodeSlot 1`) and confirm the cues fire.
3. Generator start time versus the show offset (does slot 1's generator start at 1h00m00?).
4. Watch `TimecodeSlot 1` `TIME` while it runs (settles the Cue Display question).

## Plugin access today, and gaps

- Can read shows, tracks, ranges, events, slots [C]; can create shows and targets by command [C].
- Gaps: no tool for slot settings (not in the show file: where do they live? [?]); event creation by
  command is unproven; timecode playback state (running, cursor) not read by a tool [?].
