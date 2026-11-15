# System windows, Message and Status Center: what we know, how sure we are, how to use them

Written 2026-11-08 from the MA help 2.5 (chapter "System", 10 pages; keyword pages `MessageCenter`,
`ListReference`, `Park`, `Preview`, `Load`), and the release notes 2.2 to 2.5.1.1. Study pack:
`python3 tools/atlas/pack.py "System" --terms user,session,message,systemmonitor,info`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

These are the console's own health and diagnosis windows. They matter to us twice: they are how
Aaron (and later the plugin) can see what went wrong, and some of them measure the very thing the
console guard protects (the GUI's frame time).

## Date, time, location [D]

- Menu > Settings > Date and Time: Session Time (manual when not NTP), Location (time zone,
  longitude, latitude: these drive the agenda's Dawn, Sunrise, Sunset, Dusk modes), Daylight Info,
  Time Server (Extern TimeSync Mode NTP or None; NTP gives UTC, the time zone makes it local).
- **The IdleMaster or GlobalMaster station sets the session time**, whatever NTP the others use.
- On onPC for macOS: do not change the Mac's system time while onPC runs (time conflicts).
- Clock Viewer: Session Time (Digital, AM/PM, dates, time to or since Dawn, Sunrise, Sunset, Dusk),
  Time Zone, **Timecode** slot (or the selected one), **Timer** (with start, pause, stop); digit
  colour, appearance, Show Fractions.

## System Info and System Monitor [D]

- System Info window (Add Window > More): Realtime (**milliseconds of work per DMX frame**),
  **Timing** (time to render the screens: MainLoop, Swap, End per display), CPU, Memory, CPU / GPU /
  Sys temperature and fan (console light shows all of these), Details (serial number, build date),
  HDD, Network (expected versus connected stations).
- **Use for the guard bench**: the Timing view shows the GUI's frame time live, so a plugin read that
  stalls the screen thread should show as a MainLoop spike [?: confirm on onPC that a plugin call
  appears there].
- System Monitor: the station's background log (command feedback, warnings, errors, system changes);
  red background when scrolled away from the latest line.

## Info window and ListReference [D]

- Tabs Referenced by, Depends on (with Depth, for embedded presets), Note. `ListReference Group 1`;
  bare `ListReference` lists every reference in the show in a pop-up. Link Type Fixed or Selected
  Sequence; Window Mode shows the notes of the current, next, or all cues (or macro lines).
- 2.2 fixed: switching the Window Mode in the Info window could crash. **ListReference opens a window
  or pop-up**: through the plugin it is a dialog risk [C: our dialog rule; ?: test on onPC].

## Message Center [D]

- Envelope icon on the command line; categories **System, Command Line, Power, MA-Net, USB, Chat** (USB
  and chat stay on their own device); priorities Information (green), Warning (yellow), Error
  (brown), Alert (red). Each list shows time, sender (name and IP), category, priority, message.
- Messages worth knowing: "Current onPC status changed from Connected to IdleMaster", "Console
  disconnected unexpectedly", "Stage bounding box is irregular", **"Failed to perform an
  initialization during a showfile load"** (corrupt show: load a backup), "No world server
  connection", battery and power messages, **"Out of video memory. Please save your show file and
  restart"** (close the 3D viewer if it repeats).
- Notifications per category: None, Notification (corner), Pop-up (centre of every screen);
  Timed (5 s) or Permanent.
- `Call MessageCenter` confirms all; `Call MessageCenter "MA-Net.Errors"`, `".Warning"`, `"Power."`.
  **Confirm, Unconfirm and Delete cannot be oopsed.**
- The Message Center is `Root 1` (`MessageCenter`) in the object tree [C: root census]. Reading it is
  the obvious way for the plugin to answer "what is the console complaining about" [?: not read yet;
  bench on onPC, and never confirm or delete messages for Aaron].

## Status Center [D]

Icons on the command line, set per user profile (Never, On Activity, Always; blink None, Once,
Always; some by My / All profiles):

| Group | Statuses |
| --- | --- |
| Programmer | Highlight, Lowlight, Solo, Blind, Preview, Timecode Record, Recipe Editing, Grand Master not full, World Masters, Group Masters, Grand Rate not 1:1, Pause at End |
| Filter | a filter other than 1, a world other than 1 |
| Universe / Patch | Parked (blue), DMX Tester, **Not Enough Parameters** (Overload when the DMX refresh slows), No Fixtures Patched, **Patch Open** (`ext` when open on another station) |
| More | World Server, Encoder Bar, **Phasers** (phaser workload bar), **Flow Control** (network workload 0-255) |
| Hardware | Battery, USB Network, ShowData, CPU, Memory, temperatures, fan, disk space |
| Toggles | Keyboard Shortcuts |

"Patch Open" is the state our fixture-type and curve jobs depend on (`Root 14.10` exists only then):
a tool could check it before a patch job instead of asking [?: find where the status lives].

## Park [D]

`Park Fixture 1` (all DMX channels of the fixture hold their value), `Park Fixture 1 At 50`, `... If
FeatureGroup 1`, `Park DMXUniverse 2`, `Park DMXUniverse 1.20`; `Unpark`. A blue P marks universes
with parked channels. Park acts on output at once; Aaron's Relays macro and group 1100 are the only
parking we know of in his show [C: our macro reads].

## Release-note traps [D]

- PSR of a show with illegal fixture-type information could freeze the software and need a full
  install (fixed 2.5); a crashed station rejoining a session forced a full show upload (fixed 2.5);
  importing a user profile with EditRecipe on could crash (fixed 2.4); several pop-ups open at once
  could freeze the software (fixed 2.2).

## Plugin access today, and gaps

- `ma3_status` reports host, show and version [C]. Gaps: no tool reads the Message Center, System
  Info timings or statuses; all three are read-only candidates for the next plugin round, bench first.
