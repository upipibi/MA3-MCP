# The console light, onPC on this Mac, parameters, power: what we know, how sure we are

Written 2026-11-08 from the MA help 2.5 (chapters "Device Overview" for the grandMA3 light, keys,
screens, shortcuts, UPS; "grandMA3 onPC" 10 pages; "Control Other MA Devices"; "First Steps"; "System
Overview"). Other device models are skipped. Study: `tools/helpsite/text.py do_console_light`,
`onpc_macos_installation`, `onpc_terminal_app`, `system_parameter_calculate`, `do_ups_battery`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Aaron's console: grandMA3 light [D, C]

- Front: screens 1 and 2 (15.6-inch, 1920 x 1080), command screens 6 and 7 (7-inch, 800 x 480),
  letterbox screens 8 and 9 (1280 x 242: encoder bar with grand master; executor bar with master
  section), level wheel, command area, Xkeys, master area, three executor sections. Screens 4 and 5
  are external DisplayPort monitors. A first extension adds letterbox 10.
- Rear: DMX A-F (5-pin female) and G (5-pin male), DisplayPort 4 and 5, **LTC** in, USB 3.0 and 2.0,
  audio in, **DC remote**, **Ethernet 1-3**, S/PDIF in and out, **MIDI in and out**, desk light,
  powerCON TRUE1 and a power switch.
- **16,384 parameters** (consoles do not add up in a session; processing units do, to 262,144). The
  System Info Details view shows used versus available. Software 2.5.1.1 [C].
- Keys: one help page per key (`key_*`); keyboard shortcuts (ShCuts or F10 toggles them; part of the
  user profile; `KeyboardShortcut` keyword).

## Power and the UPS battery [D]

- Lithium-ion UPS so the show can be saved and the desk shut down after a power loss; not for running
  on battery. On loss: a Power Loss pop-up on every screen (Save and Shut Down, Shut Down, Continue),
  the power icon turns red; **at 50 % a progress bar saves the show and shuts down automatically**.
- MA asks for a battery check before major programming or every two months: new show, power switch
  off, Continue, four minutes on battery, expect about half capacity left; recharge to 3/4 once a year.
- Shutdown: control-bar shutdown menu (shut down, reboot, restart, desk lock), the Power key, or the
  keywords (all refused by the plugin). An unsaved show asks to save first.

## Crash logs and diagnostics [D]

- A crashed station writes a crash log and uploads it to MA's world server the next time it is online
  (server address `0` turns that off). `ListCrashLog` lists them; `CopyCrashLog If Drive n` copies
  them to a stick; `DumpLog` writes the System Monitor to a stick. **Aaron can run these at the desk
  when the stick is in**: a crash log or system monitor dump from the 2026-11-08 freeze, if one
  exists, would name what hung [?: whether a hang without a crash leaves a log].
- The **grandMA3 Terminal** app (installed with onPC) connects to a station: `sysmon <ip>` shows its
  System Monitor read-only, `cmdline <ip>` gives its command line. A read-only System Monitor view of
  the console during a plugin job is a diagnosis option that does not go through the plugin [D; not
  used, needs Aaron's agreement].

## onPC on this Mac [D, O]

- Installed per version as separate apps (`grandMA3 2.5.1` here); folders under
  `~/MALightingTechnology` (`gma3_2.5.1/shared/...`, `gma3_library/...`) [O].
- **Up to five onPC instances can run at once** (Dock menu New onPC Instance, File > New onPC
  Instance, Command+N): a second, clean instance is a safer bench than the one holding a copy of the
  show [D].
- macOS needs Local Network, External Media and Microphone permissions; MA's power advice: no low
  power mode, no sleep on adapter, display never off. Requirements: macOS 14 or later, Apple silicon
  with 8+ cores, 16 GB (24 GB unified memory to join a session with a console).
- onPC Local Settings: MIDI devices and offset, MIDI timecode slot, audio in and out, viz-key, Reset
  Date and Time, Force Login. Clean start: hold Option while opening onPC (all settings to defaults).
- **onPC alone unlocks no output parameters without MA onPC hardware** (limit 4,096 with it): it
  loads and edits Aaron's full show but outputs no DMX here, which is what a bench wants [D].
- RemoteHID: a console's mouse and keyboard can drive another station (onPC on Windows only).

## Plugin access today, and gaps

- `ma3_status` reports the host type (Console / onPC) and version [C]. Not read: parameters used,
  battery state, crash logs. These are questions to answer at the desk, not plugin features.
