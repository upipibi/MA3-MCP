# Worlds and filters: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Worlds and Filters", 5 pages), 17 of MA's world and
filter tests, and the release notes 2.2 to 2.5. Study pack: `python3 tools/atlas/pack.py "Worlds and
Filters" --terms world,filter`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Worlds [D]

- Limit **access**: fixtures and attributes outside the selected world disappear from some windows and
  cannot be programmed (each user in a session can work in a world). Always one selected world.
- **World 1 "Full"** holds everything, is locked and cannot be deleted. Its world master is linked to
  the grand master (2.5).
- Store: select fixtures (none = all fixtures), activate attributes (none = all attributes), Store into
  the World pool. Worlds hold no values. Edit (Edit + world, change selection, Update) or Edit Settings:
  Name, Appearance, Scribble, Note, Lock, **Selection** (Normal: sub-fixtures included, also inside
  selected grouping fixtures / Strict: only what was selected; changes show after reselecting the
  world), **Master** (limits the world's intensity). `Store World n Property "Selection" "Strict"`.
- Deleting a world removes it as input/output filter from sequences and presets (Oops restores both);
  **a deleted world stays active for the user until another is selected**.
- Fixtures of different worlds can be stored in one sequence (multi-user programming).

## Filters [D]

- Block values from being stored, updated, recalled or cloned, or mask sheets. Defaults: All (locked),
  Prog Only, Only Dimmer, Only Position, Only Color, Selection Only, Parked Only.
- **Selected** filter (yellow frame) versus **called** filter (pulsing; `Call Filter n`; used for the next
  Store, Update, At or Clone only). At flashes when a filter other than 1 is active.
- Filter editor: rules on the left, attributes and programming layers on the right (like the At Filter
  window); Import / Export; List References.
- **Rule types**: Attributes, Changed, Cooked, DMX Mode, DMX Tested, Fade & Delay, Fixture Layer &
  Class, ID Type (From-To), IfActive, IfOutput, IfProgrammer, Live, MIB, Multi Step, Name, Parked,
  Patch (address range), Selected, Selected Feature, Stage, Used In Object, Used In Selected Sequence,
  Used In Show. Per rule: Invert, Apply to Fixtures, Apply to Attributes.
- Rules in a ruleset combine with AND; rulesets combine with OR.
- **Dynamic rules** (marked; for example IfOutput, Selected) only work for sheet masking. **Only filters
  without dynamic rules can be input/output filters** (sequences, presets, cue breaks, recipes, command
  line). Break filters must be static [D: cues].
- `Assign Group 2 At Filter 8` creates a Used In Object rule (groups, worlds, presets, sequences).
- Filters exported from 2.2.5.2 or older lose patch-information rules on import into 2.3.2 or newer;
  filters with fixture selections from those versions lose the selection once edited.

## Where filters and worlds attach [D]

- Sequence input and output filters, preset pool and per-preset input filters, cue breaks
  (`Assign Filter "x" At Cue n`, `Assign World "All" At Cue 3` [M]), recipe lines, sheet masking
  (`Assign Filter "Only Dimmer" At ScreenContent 1.1.1`), group and world masters.

## Commands [D, M]

`World 999` (select), `Store World 999`, `Delete World 999 /NoConfirmation` (MA's "World Is Selection"
macro), `Store World n Property "Selection" "Strict"`, `Call Filter n`, `Assign Filter n At ...`,
`Assign World n At ...`, `Delete Filter n`, `FaderMaster World 2 At ...`.

## Traps

- A world limits what a job can see: reads made in a small world miss fixtures [?: does the plugin's
  command line run in the operator's world? Bench].
- Deleting a world or filter strips it from every sequence or preset using it (Oops restores) [D].

## Plugin access today, and gaps

- Worlds and filters are pool objects readable with `ma3_children` [?: not read yet]. Gap: which world
  the plugin's commands run in.
