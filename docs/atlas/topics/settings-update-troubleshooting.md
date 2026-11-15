# Local settings, software update, troubleshooting: what we know, how sure we are

Written 2026-11-08 from the MA help 2.5 (chapters "Local Settings", "Update the Software" 9 pages,
"Troubleshooting" 5 pages; keyword pages `Version`, `CancelSoftwareUpdate`). Study packs:
`pack.py "Local Settings"`, `pack.py "Update the Software"`, `pack.py "Troubleshooting"`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

None of this is plugin work. It is here so a question about the desk's state gets a grounded answer,
and so a job never touches it by accident.

## Local settings (console only) [D]

Menu > Settings > Local Settings: Audio Out Device, **Force Login** (login pop-up at start),
mouse cursor size and speed. onPC has its own onPC Local Settings instead.

## Software update [D]

- Every device with a version above 1.0 sees and updates the others on the network; `Version` prints
  the running version. Packages: `grandMA3_stick_v<ver>.zip` for consoles, onPC packages for Windows
  and macOS, Windows hardware images, viz-key / net duct.
- Console from a stick: the `EFI` and `ma` folders and `update.scr` sit at the stick's root (not in a
  sub-folder); the boot menu offers saving shows to the stick first and the mode choice (grandMA3 or
  Mode2). **Formatting resets the IP address to DHCP.**
- Network update from onPC: copy the zipped package (not unzipped) into `installation_packages`.
- Downgrades come from MA's archive. Failures: broken package, installing from the zip, a worn stick,
  a bad USB port or cable.
- **Shows are tied to versions**: PSR needs the same version (`show-creator-and-psr.md`) and the
  session needs the same first three numbers (`networking-and-sessions.md`). Aaron's console and this
  Mac's onPC both run 2.5.1 [C]. The plugin refuses every software command [C: alpha.6].

## Troubleshooting [D]

- **Clean start**: hold Ctrl while choosing the mode at boot (console, replay unit, PU; external
  keyboard if none built in); on macOS hold Option while opening onPC. Boots with no show loaded and
  **all user settings reset to factory defaults**. For a show that loads but misbehaves.
- Station or wing does not connect: clean start; power-cycle the wing; USB port, cable, OS updates or
  power settings, a broken onPC install.
- **Panic macro** (factory macro library, import it by name): resets a long list of general
  settings at once: ClearAll for every user, command line to Root, web remote, Remote HID, RDM,
  agenda, all remotes, OSC, PSN, MSC, Art-Net and sACN in and out **off**, world 1, filter 1, Freeze
  and Preview off, **plugins, sequences, timecodes, executors, macros and timecode slots off**, group
  master modes off, every master to 100 %, rate and speed defaults, programmer and executor time off,
  readouts and wheel defaults, all universes requested and set to HTP, encoder bar 1, the UI
  reloaded, default colour theme, multicast base reset, unused attributes deleted. MA: save first,
  never during a live show [D]. Our rule: a job never imports or runs it; if Aaron's show has a macro
  called Panic, treat it as live-dangerous [C: rule].

## Plugin access today, and gaps

- `ma3_status` reports the software version [C]. Nothing else here is read or written.
