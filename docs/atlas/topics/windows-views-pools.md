# Windows, views, menus, pool operations: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Windows, Views, and Menus", 16 pages; keyword pages
`View`, `ViewButton`, `ScreenContent`, `/Screen`, `Move`, `Exchange`, `Insert`, `Copy`, `Lock`,
`Unlock`, `Delete`, `Oops`), MA's page and view system tests, and the release notes 2.2 to 2.5.1.1.
Study pack: `python3 tools/atlas/pack.py "Windows, Views, and Menus" --terms view,screen,pool`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

**Screens belong to the operator.** Windows, views and view buttons live in Aaron's **user profile**
(screen configurations), not in the data pool, and the plugin types on his command line [C: Root
20.1]. A view call or `Delete ScreenContent` through the plugin rearranges the screens he is
running the show on. Never without his ask.

## Screens, windows, views [D]

- Screens are the monitors; each user profile has screen configurations holding window layouts and
  view-button assignments. A new show has six factory views on the big screens' view buttons.
- Add Window (tap an empty area): tabs Common, Data Pools, Presets, Pools (show data: Appearances,
  Data Pools, Gels, Scribbles, Tags, Timecode Slots, Universes, Users; media; user profile: Cameras,
  Encoder Bars, Render Qualities, Views), Tools (sheets, programmer tools, viewers: 3D, Agenda, Clock,
  Layout, MAtricks, Phaser, RDM Devices, Sound, Timecode), More (bars, playback windows, Command Line
  History, Help, Info, Message Center, Oops, System Info, System Monitor, Trackpad), All. Delete Screen
  clears a screen; Configure opens Configure Display.
- Windows snap to a grid, cannot overlap, have minimum sizes; double-tap the title bar to maximise.
- **Views** (View pool, user profile): store with `Store View 15 "layout" /Screen "1,2"` (a pop-up
  picks screens; optional screenshot when one screen), recall with `View 2` (lands on the screen it was
  stored on, or where the command line has focus; `/Screen "2"` forces one). Assign: `Assign View 4 At
  ViewButton 1.7`, `Assign View 9 At Page 3.291` (views on executors). Update = store again. View
  properties: Name, Scribble, Appearance, `ScreenContentMask` (1-127), `RequestedW`, `RequestedH`
  (1-327); the view editor lists its windows as `ViewWidget` rows.
- `ViewButton 2.4` calls the button's object (default: the focused screen); `Assign User "Guest" At
  ViewButton 1.1`, `Delete ViewButton 1.4`, `Label ViewButton 2.5 "Layout"`.
- `ScreenContent <screen>.<window>`: `Delete ScreenContent *.*` (every window on every screen),
  `Delete ScreenContent 1.*`, `Set ScreenContent 1.1 "W" "12"` (width in half columns); `/AutoFit`.

## Window settings [D]

- MA logo in the title bar opens settings; tabs differ per window. Save / Load store named preferences
  (per user profile); Delete Window. Edit Title Bar picks which settings get title-bar buttons
  (order, Load Defaults, Delete All).
- Shared settings worth knowing for reads: **Link Type** (Fixed with Fixed Target, Selected, **LastGo**:
  follows the last sequence that got Go+, Go-, Goto, Load, On, Select, Top, Temp, Flash, Toggle,
  Pause), Readout (Auto, Natural, Percent, PercentFine, Physical, Decimal8/16/24, Hex8/16/24), Sheet
  Mode, Layer, Follow Preview, Cue Only (track and content sheets), Merge Cells, Fixture Graphic,
  Time and Frame format, Speed readout, Page (playback, command wing bar, Xkeys windows), Wing ID,
  Show Title Bar (both MA keys reveal it), Mask tab (sorting, ID types, Show Notes) and Mask Buttons
  1-16 (filters and worlds as sheet masks).
- Pool settings: First Index, Show Empty, Appearance, Pool Columns, Font Size, **DataPool** (a pool
  window can show another data pool), colours, **Use Object Action**, and a default pool action
  (At, Call, SelFix and so on; see `presets.md`).

## Main menu [D]

`Menu "MenuSelector"` opens it by command. Entries: Patch, Live Patch, Connector Configuration, Desk
Lights & Color Theme, Network, In & Out (DC, MIDI, DMX remotes, OSC, PSN), DMX Protocols, Settings
(User Configuration, Date and Time, USB Configuration, Software Update, Touch Configuration, Extension
Configuration, Local Settings), Backup, Quick Save, Show Creator, **Preferences and Timings** (Cues,
Sequences, Presets, Timecodes, Layout Elements, Keyboard Shortcuts, Executor Config., Timings, Masters,
Groups, Global; defaults apply when new objects are created). Display pop-up: Delete This Screen,
Delete All Screens, Configure Display, Set Dialogs to This Display, Set Dialog Positions to Default.
**Menus are dialogs**: a plugin command that opens one stalls the plugin (our hazard list) [C].

## Pool operations (every pool) [D]

| Command | What happens |
| --- | --- |
| `Store Group` (no number) | stores at the first empty slot; with nothing to store, an empty object |
| `Edit Image 3.2` | creates the object and opens its editor (a dialog) |
| `Move Macro 5 At 20` | **if 20 is taken, the occupant moves one up, and so on until a gap**: a cascade renumbers neighbours |
| `Exchange Macro 1 At Macro 3` | swaps two objects (Move twice on the keypad) |
| `Insert View 42 At 10` | inserts before 10; 10 and up shift one number until the next gap |
| `Copy Sequence 1 At 22` | copies; an occupied target is overwritten after a pop-up (our tools add `/NoConfirmation`, so **no pop-up**) |
| `Lock Appearance 4`, `Unlock ...`, `/Recursive` | user lock (orange, UL); system lock (red, SL) and position lock (grey, PL) cannot be lifted; copying a user-locked object unlocks the copy |
| `Delete View 42 Thru 90` | MA "keeps the look" (a deleted preset's values go into its cues); Oops restores the objects but **may not restore links** |
| `Oops` / `Undo` | last command-line action, selection or programmer change |

A big red lock on a pool object is not a lock: another user is editing it (object ownership).

## Traps

- Move and Insert renumber objects that cues, macros (by number) and executors may point at. Use
  handles or names in macros; check references before any pool reshuffle [D].
- Copy onto an occupied slot overwrites silently through the plugin [C: tool adds `/NoConfirmation`].
- 2.4 fixed: Exchange on executors bigger than 1 x 1 addressed the wrong executor; swiping Pages in a
  2D phaser encoder bar could crash [D].

## Plugin access today, and gaps

- No tool reads screens or views; the view pool sits in the user profile (`ShowData > UserProfiles`),
  which the console guard limits to the profile list itself [C: guard rules]. Reading Aaron's view
  set would need a guard rule and an onPC bench first.
