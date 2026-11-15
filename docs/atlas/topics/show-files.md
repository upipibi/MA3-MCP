# Show files: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Show File Handling", 7 pages, 5 keyword pages), the
folder-structure and SFTP pages, MA's save tests, the release notes 2.2 to 2.5, our backup tool
(`ma3_backup`, `ma3_save`) and the show-file header reader (`tools/showfile/lineage.py`). Study pack:
`python3 tools/atlas/pack.py "Show File Handling" --terms show,saveshow,loadshow,backup`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What is in a show file [D]

- Patch, fixture profiles, cues, timings, 3D, users and user profiles; since 1.9 also Local Settings,
  Output Stations (DMX ports, SMPTE, MIDI) and DMX Protocols (Art-Net, sACN). Limit **10 GB**.
- **Versions only move forward**: a show saved in a newer version cannot load in an older one; keep a
  copy under a new name before upgrading.
- Timecode slot settings are **not** in the show file [D: timecode page].

## Backup menu (Menu > Backup) [D]

- Drives: internal = Drive 1, first USB stick = Drive 2 (later sticks get higher numbers by connection
  order); select in the menu or `Select Drive 2` (two words). Free space warnings: orange under 15 GB,
  red under 5 GB, a boot warning under 15 GB.
- Load (segments): Show Data (default), Local Settings, Output Stations, DMX Protocols; unchecked
  segments keep what is loaded. Folders: Shows, Backup Shows, Demo Shows, Template Shows; search field.
- Save: Save To (a USB save **also saves to internal**), **Quick Save** (Menu, Quick Save; or Menu
  pressed twice), **AutoSave Interval** (countdown in the title bar), Save As (new name), Edit
  Description. Full-disk and partial-save warnings. Shutdown asks Save / Do not save / Cancel.
- Names: at most **31 characters**; not backslash, double quote, `$ * ? ^ | / : < >` or backtick. (Object names also drop commas [C].)
- New Show: name, segments to clear (Show Data by default, Local Settings, Output Stations, DMX
  Protocols); unsaved changes prompt Save / Do not Save / Cancel.
- **Backups**: up to 10 per show, made automatically on every save, named `<show> Backup <UTC date
  time>`, loadable from Backup Shows; you cannot save into Backup, Demo or Template folders.
  Templates are show files placed in `gma3_library/templateshows` (on a console via SFTP).
- Delete: Backup menu > Delete.

## Show history and description [D, O]

- **Show History** (Load, bottom-left switch): date, version, type, name, description, time zone and
  UTC of every save where version, type, name, time zone or description changed; newest first.
- This is the list `tools/showfile/lineage.py` reads straight from the file header on the Mac, without
  loading the show [O]. It showed `Christmas 2026` was split from `Late 2026` on 2026-10-22 [O].
- Description: typed in the Backup menu, saved with the next save; **Enumerate Show File Name When
  Description Changes** appends a 3-digit number (`/Enumerate` option).
- Export Media on Show Save: copies installed media to the library with the show.

## Folders and file transfer [D]

- Main folder: `grandMA3/` at the root of a USB drive, `~/MALightingTechnology` on a Mac with onPC,
  and `/` when logged in to a console by SFTP (TCP 22; MA documents a fixed login on the File
  Management > SFTP page, and the station's SFTP Access switch in Station Control turns it off).
- Shows and backups: `grandMA3/shared/shows` and `.../backups` on a stick; `gma3_<version>/shared/...`
  on onPC; `/actual/shared/...` on a console. MA warns that changing anything but show files inside
  the version folder can make the software unstable.
- Library (`gma3_library/`): agendas, appearances, certificates, colorthemes, datapools (with
  plugins, macros, presets, sequences and the rest), executorconfigurations, fixturetyperesources
  (gobos, meshes), fixturetypes, inout (artnet, dcremotes, dmxremotes, midiremotes, osc,
  outputconfigurations, sacn), media (images, sounds, symbols, videos), mvr, netkeys, patch
  (dmxcurves, stages), scribbles, userprofiles (cameras, renderqualities, screenconfigurations,
  viewbuttons, views), users. Objects without a folder export to the library root.
- File names must not contain backslash, double quote, `$ * ? ^ | / : < >` or backtick. A stick with
  the pre-1.5 layout gets a migration pop-up (keep old, delete old, not now, never).
- `Drive` addresses drives (`Export Macro 1 If Drive 2`, `Eject Drive 2`; the plugin refuses
  `Eject`).
- Our route for show files off the console is the USB stick (Aaron, 2026-11-08); SFTP from this Mac
  was declined by the permission check and is not used [C].

## Commands [D]

| Command | Options |
| --- | --- |
| `SaveShow`, `SaveShow "Name"` | `/Enumerate`, `/Path` |
| `LoadShow "Name"` | `/All`, `/DMXProtocols`, `/LocalSettings`, `/NoSave`, `/NoShowData`, `/OutputStations`, `/Path`, `/Save`, `/Type` |
| `NewShow "Name"` | `/All`, `/DMXProtocols`, `/LocalSettings`, `/NoShowData`, `/OutputStations`, `/Path` |
| `Menu "Backup"`, `List Menu` | open menus by name |
| `LoadShow "x" If Drive 2 /Path "/test"` | from a stick sub-folder |

The plugin refuses `SaveShow`, `LoadShow` and `NewShow` through `ma3_command` (dialogs stall the screen
thread); `ma3_backup` and `ma3_save` are the save paths [C]. Loading a show unloads the plugin with it.

## onPC start-up parameters [D]

- `SHOW="startshow.show"` loads a show at launch; **`RUNPLUGIN="startplugin.xml"-y`** starts a plugin
  (y = the Lua component number) at launch; `NOLOAD` (empty show, keep device settings);
  `CLEANSTART` (reset device configuration, empty show). No spaces in the show name.
- This answers the roadmap's "auto-start" unknown for **onPC**: the bench could start with the MCP
  plugin running, with no import and no tap. [?] Bench: how to pass it on macOS (`open -a ... --args`).

## Traps (release notes 2.2 to 2.5.1.1, and ours)

- 2.5 fixes: loading a show with corrupted groups could crash; many filters could crash a group store;
  in a session, loading a show from USB on a second console during a master reboot could lose data;
  after a station crash a full show upload was triggered. 2.5 changed user rights None to View and Off
  Mode to Touch Mode on load of older shows.
- Ours: the console's show names (`Christmas 2026`) are Aaron's; jobs back up first (`ma3_backup`
  writes `<show>_mcp_<MMDD_HHMM>`, cut to 31 characters) and never save an old show after loading it
  [C]. The PIN lived in a settings file that followed the selected drive after a stick import (fixed in
  alpha.5/6) [C].

## What we have proven

- `ma3_backup` and `ma3_save` on the console; backup names; lineage reads of 20-plus show files on
  this Mac [C, O].

## To bench on onPC

1. `RUNPLUGIN` on macOS onPC.
2. `SaveShow "x" /Path` on a stick through the guard (refused today on purpose; is it ever needed?).

## Plugin access today, and gaps

- Backup and save [C]. Gap: no tool lists show files on the drives or reads their history; the
  Mac-side lineage reader covers show files copied off the console.
