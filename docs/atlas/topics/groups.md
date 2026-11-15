# Groups: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Groups", 5 pages, 6 keyword pages), 16 of MA's
group and selection tests, the release notes 2.2 to 2.5, and our group jobs (Group 706 `Ladder LEDs`,
`docs/jobs/2026-11-05-ladder-group/`). Study pack: `python3 tools/atlas/pack.py "Groups" --terms
group,selection`. Aaron's numbering by fixture family is in `docs/CONVENTIONS.md`, "Groups".

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What a group is [D]

- A stored fixture selection **with its selection order and selection-grid positions** (a 3D
  relationship between fixtures, not stage positions), in the Group pool. **Groups store no values.**
- Cues and presets do not reference groups; recipes do.
- The order and grid drive ranges, MAtricks and phasers; this is why Group 706 got a 50 x 12 grid
  (x = LED along the ladder, y = ladder) [C].

## Creating and changing [D]

- `Store Group 3 "Name"` stores the current selection (order and grid included).
- Storing onto an existing group opens a pop-up; **Grid Merge Mode** Append X (default: new fixtures
  go after the last X position) or Off (stored positions merged); Save Defaults / Load Defaults.
  Command: `Store Group n /Merge /GridMergeMode "Append X"` [M]; options `/Merge`, `/Overwrite`,
  `/Remove`.
- Add fixtures: Edit + tap the group, select more, Update, OK; or Store + tap, Merge; or Edit Setting >
  Edit Content > select > Update.
- Remove fixtures: Edit Content, `-` then the fixtures, Update; or Store + tap, Remove.
- **Building the grid by command (proven 2026-11-05)** [C]: `ClearSelection`, then per row
  `Grid 0/<row>` and `Fixture <a> Thru <b>` (the selection fills the row from the grid cursor along
  X), then `Store Group <n> "<name>"`; clear the selection before and after (it is the operator's).
  MA's tests do the same with `Grid 1/1; Fixture 1; Grid 3/3; Fixture 2` [M].

## Group settings (EditSetting Group n, Edit Edit, or Swipey > Edit Setting) [D]

- Label: Name, Scribble, Appearance, Tags, Note.
- Settings: **Lock** (no changes to settings or content; still selectable and usable in recipes),
  **Mode** (group master: None, Positive, Negative, Scaling, Additive), Move Grid Cursor (after the
  group is called), Edit Content, List References; a master fader on the right.

## Group masters [D]

| Mode | Effect |
| --- | --- |
| Positive | HTP limit: output reduced by the master |
| Negative | LoTP limit; **beats Positive** when groups overlap |
| Scaling | multiplies (50 % fixture x 50 % master = 25 %; masters multiply together) |
| Additive | adds output, HTP-merged with programmer and playbacks |

- Example: a fixture at 100 % in a Positive group at 80 % and a Negative group at 60 % outputs 60 %;
  both Scaling would give 48 %.
- `Set Group 4 Property "Mode" "Positive"` (case-sensitive value; without a mode a pop-up asks).
- Fixtures under a group master get a different background in the fixture sheet; groups with a mode
  show a level bar in the pool.
- Masters window (2.5): hold Group opens the Group Masters tab; Full / Zero or Flash / Black buttons;
  set all masters of a mode with `FaderMaster Group * At 100 /Type "Positive"`.
- Deleting the group from an executor keeps the limit (the group still exists); deleting it from the
  pool removes the limit.

## Deleting [D]

- `Delete Group n`; a referenced group asks first (through the plugin `/NoConfirmation` skips it);
  recipes lose the selection; an executor holding it as a master becomes empty. **Oops brings the
  references back.**

## Commands [D, M]

| Command | Use |
| --- | --- |
| `Group 3` | default function SelFix: select the group's fixtures |
| `List Group` | list the pool in the command line history |
| `Store Group n "Name"`, `Store Group 1 Thru 8 /NC` | store |
| `Copy Group 100 Thru 102 + 104 At 200` | copy (gaps kept or not, as for cues) [M] |
| `Move Group a At b`, `Insert Group`, `Lock Group 1 Thru 8`, `UnLock Group` | pool housekeeping [M] |
| `Park Group "DIM"`, `Unpark Group "DIM"` | park the fixtures (live output!) [M] |
| `cd Group; import lib "group_export.xml" At ...` | import [M] |
| `IfOutput Group 1` | select fixtures of the group that are outputting [M] |
| `Assign Appearance 3 At Group 5`, `Label Group 3 "Name"`, `Set Group 4 Property "Mode" "..."` | |

MA's tests also show the selection itself as an object: `Set Selection MAtricks "X" 10`,
`Copy Selection 1 At 2`, `Clone Selection 2 At Selection 1 If Programmer /Overwrite`,
`Set CurEnv Property "ActiveSel" "1"` [M] (studied with MAtricks and Operate Fixtures).

## Traps

- A group referenced by recipes loses nothing visible when deleted, but the recipes lose their
  selection; Oops restores it [D].
- 2.5: Phaser recipes and group + recipe template combine in the programmer; changed sub-fixtures
  could break group filters before 2.5 [D].
- The `Test` LEDs are not in Group 706 by Aaron's choice; Group 811 `Ladder 1` also holds the Test
  set (100 members) [C].

## What we have proven

- `ma3_groups` reads members, selection data and grid; Group 706 built and read back (600 members,
  50 x 12) [C].

## To bench on onPC

1. Group master by command and its property names; how `Mode` reads back.
2. `Store Group n /Merge /GridMergeMode "Append X"` on an existing group.

## Plugin access today, and gaps

- Can read and create groups with exact grids [C]. Gaps: group master levels are not read by a tool [?].
