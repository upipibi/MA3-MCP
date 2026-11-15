# Agenda, timers, quickeys: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapters "Agenda" 5 pages, "Timers" 3, "Quickeys" 4), MA's
agenda and timer tests, and our agenda job (`docs/jobs/2026-11-05-agenda/`: 15 entries for the
Christmas 2026 run, Agenda 14-28, proven syntax). Study packs: `pack.py "Agenda" --terms agenda`,
`pack.py "Timers" --terms timer`, `pack.py "Quickeys" --terms quickey`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Agenda [D, C]

- Scheduled execution of sequences, macros, plugins or a command by the calendar, once or repeating
  (minutes, days, weeks, months, years). Agenda Viewer: Sheet, Year, Month, Week, Day (disabled entries
  in red; days with events green, conflicts bright red).
- Entry properties: Name, Appearance, Note, **Mode** (Absolute date/time, or Dawn, Sunrise, Sunset,
  Dusk with **Daylight Offset**; location and time zone from Date and Time settings), **StartDate**,
  **StartTime**, **Valid Duration** (back-fire an event missed while the console was off or the agenda
  disabled), **Enabled**, **Object** (plugin, macro, sequence), **Action**, **Command** (instead of an
  object, for example `Go+ Executor 101`), **Repeat** (Schedule: days, weeks-in-month, months, with an
  end date or time; Iterations: every n minutes, days, weeks, months, every year).
- Read-only columns: Countdown, Planned Date, Planned Time, Repeat Count Days / Total. Delete Old
  removes past events.
- Class `AgendaEvent` with `STARTDATE`, `STARTTIME`, `COUNTDOWN`, `ENABLED`, `APPEARANCE`, `OBJECT`
  [C: census and our job]. The 15 Christmas entries were made by command (syntax in the job record) [C].
- **An enabled agenda entry fires on its own**: an entry with an object or command is a scheduled
  stage action; ours were informational [C: job record].

## Timers [D]

- Timer pool: **Stopwatch** (counts up) or **Countdown**; Timer 1 is a locked stopwatch. Default pool
  action Toggle. Running timers show in the pool and in Running Playbacks.
- Commands: `Go+ Timer n` (start), `Pause`, `Top` (reset; keeps running if running), `Off` (stop and
  reset: zero for stopwatches, the set time for countdowns), Flash and Temp run while held; `List
  Timer` shows properties. Read-only **`ElapsedTime`**.
- Settings: Name, Scribble, Appearance, Note, Timer Mode, **Timer Link Type** (Not Linked, Selected
  Sequence, Link Last = any sequence, or a specific sequence: starting it starts the timer), Timer
  Trigger, Restart Option (Continue / Reset), colours, Frame Format, Time Readout.
- **The running state is not saved**: on reload a timer sits paused at its saved time.
- The clock viewer shows a timer (Clock Source = Timer) with Off / Pause / Go+ in its title bar.
  A countdown on a song timer could feed the Cue Display page later [?].

## Quickeys [D]

- Soft versions of hardware keys and functions in the Quickey pool; assignable to Xkeys, layouts,
  executors. Editor: Name (Code wins), Scribble, Appearance, Tags, Note, Lock, **Code** (the key or
  function). Virtual LED: black off, white active, grey enters a keyword. MA1 and MA2 can latch.
- With CLI off, tapping behaves like the hardware key; edit with `Edit Quickey 1`; CLI on in the pool
  settings makes them editable by tap (pink background).

## Plugin access today, and gaps

- Agenda events read and written [C]; timers and quickeys are pool objects [?: not read yet].
  `ElapsedTime` would let a tool or Cue Display show a timer [?].
