# Workspace, command line, Oops: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Workspace", 31 pages, 40 keyword pages), MA's
encoder system tests and Oops menu code, and the release notes 2.2 to 2.5.1.1. Study pack:
`python3 tools/atlas/pack.py "Workspace" --terms commandline,command_line,encoder,user_profile,clock,info,oops,keyboard`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## The command line the plugin shares [D, C]

- The prompt shows the user name, then the **default keyword** in yellow brackets (`[Fixture]`).
  **A bare number is read with that keyword**: Fixture, Channel, Universal, Houselights, NonDim,
  Media, Fog, Effect, Pyro, MArker, Multipatch, PSR (custom ID types can be renamed). Plugin commands
  always name the object type, never rely on the default [C: our rule; D: the mechanism].
- `ChangeDestination` (`cd`) replaces the default keyword with the destination path in the prompt.
  **The plugin runs on the operator's command line** (`Cmdline` of the user who started it, Root
  20.1), so a `cd` the plugin leaves behind changes how Aaron's next typed command is read. Every
  `cd` in a job ends with `ChangeDestination Root` in the same request [C: the line is shared; D: cd].
- Command Line History holds up to 2,048 lines; entries can be copied or executed again. The command
  line is synchronised across every command-line input at one station.
- The network icon on the command line: red Standalone, black Startup, grey IdleMaster, light blue
  GlobalMaster, green Connected. A numbered circle is a hidden progress bar (for example an update
  being sent). Message Center icons show there too.
- Desk lock: MA + MA + Pause, keyboard Pause or F9; unlock the same way or tap four screen corners.

## Oops [D]

- `Oops` (alias `Undo`) cancels the last command-line action, the last selection, or the last
  programmer change. The Oops menu (Add Window > More > Oops) lists completed actions; undo the latest
  one or a contiguous block ending at the latest. Filters (user configuration): Create Oops, Oops
  Views, Oops Programmer, Oops Selection. Oops Confirmation: Always, Main (store, move, delete), Never
  (default).
- **All Oops entries are cleared when the patch changes or a show file loads.** A job that changes the
  patch, and any job before it, can no longer be undone with Oops; the backup is the only way back.
  This applies to the curve restore of 2026-11-08 and to every future patch job [D].
- `/NoOops` (`/NU`) runs almost any command without an Oops entry. Some actions cannot be oopsed at
  all (2.4 notes: confirm and unconfirm, among others; multicast base address changes; PSR) [D].
- Oops in a session can fail while another station is changing the show (an error appears).
- Release-note traps: oopsing a large `Move DMXUniverse` range could freeze the UI (fixed 2.5);
  Oops in some editors closed the editor instead (fixed 2.4); Oops after a mesh delete did not restore
  the model link (fixed 2.5).
- The plugin's undo groups ride on this mechanism: one Oops reverts a `ma3_commands` group; `ma3_set`
  writes are not in it [C].

## Screens and bars [D]

- Configure Display (Menu, or Configure in Add Window) per screen: Show Title Bar (onPC), Show
  Control Bar, background appearance, user-area width and height, Scale (onPC and external screens),
  Show Feedback (a note when the show is saved), view bar, command line, encoder or playback bar,
  Wing ID. A user area larger than the screen gets an orange frame and scroll bars.
- Console screens: 1-3 main, 4-5 external, 6-7 command screens (7 shows the Xkeys playback bar),
  8-12 letterbox screens (fixed content: encoder bar and grand master, playback bar and master section,
  custom section). onPC shows up to seven displays (display 1 always on).
- Control bar (hidden on console screens by default): shutdown, main menu, command section (F3),
  Masters window (F4, or `Menu MasterOverlay`; tabs Master Controls, Group, World, Speed, Playback,
  Timing masters), Playback Controls (F5), custom master section, help, At filter.
- Gestures: tap, hold, zoom, two-finger scroll, three-finger scroll of an oversized user area,
  drag and drop, **two-finger edit** (Precise Edit user setting changes it in sheets).
- Trackpad window: mouse mode (own cursor on screens 1-5) or pan/tilt mode with invert options.
- Encoder bars: per-user-profile pool; bar 1 is system-locked (copy it as a template). Bar > banks >
  pages > up to five dual encoders; each bank can run a command when entered and switch the Special
  Dialog tab. `Select EncoderBar 2`, `Select EncoderBank "Show"."Song 2"`, `On EncoderBank 2 If
  Filter 5`. Red text in the editor = an assignment no patched fixture can use.
- Colors: system colours, coloured indicators, colour themes, and a theme compare tool (Desk Lights &
  Color Theme > Compare).
- Temporary filtering (yellow filter row) in the patch, agenda, layout editor and similar grids.

## Programmer keywords from this chapter [D]

| Keyword | Effect |
| --- | --- |
| `Blind` (toggle) | programmer output suppressed |
| `Full`, `Zero`, `Normal` (At twice), `Hold` (dimmer 0 that blocks MIB) | dimmer values on the selection |
| `Default`, `Fixture 2 At Default FeatureGroup 2`, `Store Default` (`/Remove`) | defaults; Store sets new special values |
| `ChannelFunctionDefault` | every attribute to its first channel function's default |
| `Highlight`, `Lowlight`, `Solo` (toggles), `Store Highlight`, `At Highlight` | special values; Solo blacks out everything not selected |
| `Release`, `Remove` | release (back to default) or remove (track from before) values for storing with merge |
| `Deactivate Attribute "Pan"` | inactive values are not stored |
| `SelectFixtures Executor 101`, `SelectFixtures Preset 1.1` | select what an object contains (repeat activates, then deactivates) |
| `Fixture 1 At Cue Next` / `Cue Previous` | pull values from neighbouring cues |
| `Locate Group "FireWorks"`, `Locate Page 3.201`, `Locate Reset /KeepPage` | blink an object in its pool or executor; Esc cancels |
| `Help Macro`, `Keyboard "English"`, `List Keyboard` | help pop-up, keyboard language |
| custom ID keywords (`Channel`, `Houselights`, `NonDim`, `Media`, `Fog`, `Effect`, `Pyro`, `MArker`, `PSR`) | select by that ID type |
| `Fixture 4 Multipatch 2`, `Patch Fixture 2 Multipatch 3 42.6` | multipatch instances |

Every row except Help, Keyboard and Locate changes the programmer or the stage; none belongs in a
plugin job during a service.

## Plugin access today, and gaps

- The plugin reads command-line history availability (`ma3_history`: `lines_supported` false on
  2.5.1.1) [C]. It does not read the Oops list; an Oops-list read would let a job confirm its group
  landed as one entry [?].
