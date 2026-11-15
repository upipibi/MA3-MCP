# Users, user profiles, ownership: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Single User and Multi User Systems", 5 pages, 9
keyword pages), nine of MA's user and user-profile system tests, and our console reads (`Root 20.1`
command lines). Study pack: `python3 tools/atlas/pack.py "Single User and Multi User Systems" --terms
user,session`. Networking and sessions in detail: the Networking chapter (not yet studied).

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Users and user profiles [D]

- A **user** is a login: name, scribble, appearance, note, tags, optional case-sensitive password,
  **profile**, **screen configuration**, **rights**, keyboard. Users live in the User pool (logged-in
  users have a green bar); edit in the pool or Menu > Settings > User Configuration.
- A **user profile** holds the working state: **programmer content, selected sequence, current page,
  views, cameras, encoder bars, screen configurations** and preferences. Two users on one profile
  share all of it; different profiles give separate programmers and selections, while the stage
  output and show data are shared.
- Single-user session (full tracking backup): every station logged in as the same user, same
  programmer and views. Multi-user: several users with their own profiles; output is shared.
- **The Admin password resets to empty when a show loads**; Guest's password cannot be changed.
- Rights, high to low: **Admin** (everything), **Setup**, **Program** (no full Patch, Live Patch
  allowed), **Presets** (update existing presets, Store /Merge; no new objects, no cue content edits),
  **Playback** (run the show, no store), **View** (views and log in only). MA's test proves a user
  with low rights cannot `Store Sequence` and checks `Group "DIM" At 100` under limited rights [M].
- `LogIn "Name" "password"` logs the current station out and the named user in; `Logout` [D, M].

## Profile settings that change what a command does [D]

- **Single Digit Input**: when Yes, a bare dimmer value 1-9 means 10-90 (`At 5` is 50 %); not applied
  when an attribute is named (`Attribute "Dimmer" At 5`). Plugin commands that set dimmers would name
  the attribute [D; our rule].
- **Normal Value** (what `Normal` / At At sets), Value, Speed, Preset, Time, Frame and Color
  readouts, DMX readout, Wheel Mode (Additive, Incremental, Prop.+, Prop.-), Time Key Target, Precise
  Edit, Screen Encoder, Encoder Bar Type (Default, Exec, Xkeys), **TCSlot** (the selected timecode
  slot), Move Grid Cursor, KnockIn MIB, DMX tester settings, Mirror Special Executor Pages, Show
  Settings In Editors, Resolve Executor Assignments, Preview Variables, Create Command Handle.
- Oops settings live here: Create Oops, Oops Views, Oops Programmer, Oops Selection, Oops Confirmation
  (Main confirms create, delete, exchange, file loads, insert, layout, move, remove).
- Attribute preferences per profile (Edit Encoder Bar): natural readout, encoder resolution and press
  factor per attribute, dual encoder factors, Ignore Channel Functions.
- User variables beat global variables of the same name [M: `system_test_uservariables`].

## Screen configurations [D]

- Part of the user profile (no pool): which windows sit in each user-defined area and what the view
  buttons hold. Every profile starts with **Default** and **3D**. Users on one profile can each use
  a different screen configuration (MA's examples: a backup console showing other views, a 3D
  computer following Blind, a designer's web remote with limited rights).
- `Store ScreenConfiguration 3 "Average Joe"`, `ScreenConfiguration 2`, `Assign ScreenConfiguration
  "Average Joe" At ViewButton 1.6`, `Copy ScreenConfiguration a At b`.

## Object ownership [D]

- Editing an object locks it (or part of it, such as one macro line) for other users: pulsing lock,
  big red lock, a 10-second Ownership Conflict pop-up. `DropOwnership Group 1` asks the owner, who
  gets a 10-second Drop / Keep pop-up (default: drop). Automatic processes take ownership too (the
  Total Reference Update after a preset update). `ListOwnership` (or `ListOwnership Macro 1.*`) prints
  current locks to the Command Line History.
- A plugin write to an object Aaron is editing would meet this lock [?: what the plugin sees].

## Aaron's question: can the plugin be its own user? (2026-11-05, now partly answered)

- What a user profile separates is exactly what Aaron wants kept apart: programmer, selection,
  selected sequence, current page, views [D].
- The plugin runs on the command line of the user who started it (`Root 20.1`: `Cmdline 1` = User 5,
  `Cmdline 2` = User 2) [C]. `LogIn` switches the whole station, so logging the console in as a plugin
  user would log Aaron out [D].
- So the plugin gets its own profile only if it is started on a second station (onPC on another
  computer in the session) logged in as a dedicated user with its own profile and Program rights [D:
  mechanism; ?: the plugin's server would then live on that station, not the console].
- Not yet studied: how sessions and onPC stations join (Networking chapter), and whether the console
  allows a plugin on a remote station to reach the show data the same way.

## Plugin access today, and gaps

- The guard allows reading the user profile list only (`ShowData > UserProfiles`), not their
  content [C]. No tool reads users, rights or profile settings such as Single Digit Input; a job that
  depends on them should read them first on onPC [?].
