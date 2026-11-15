# Macros and variables: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Macros", 10 pages, 15 keyword pages), 14 of MA's
macro, variable and user-input tests, the release notes 2.2 to 2.5, and our reads of Aaron's macros
(Shuffle 2-4 on executors 196-198, the Relays macro). Study pack: `python3 tools/atlas/pack.py
"Macros" --terms macro,variable,uservariable,userinput`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What a macro is [D]

- Commands stored in a pool object (Macro pool, shared by every user of the show); assignable to
  executors and view buttons; a running macro shows a play icon and the current line in the pool.
- Lines (`Macro n.m`, class `MacroLine` [C]) with: **Command** (`COMMAND` [C]), **Wait** (seconds,
  or `Follow` = 0, or `Go` = pause until the next Go+) (`WAIT` [C]), **Enabled** (`ENABLED` [C]),
  **AddToCmdline** (append to what is already typed), **Execute** (Yes: runs with an automatic Please;
  No: leaves the command on the command line for the user).
- A factory macro library imports through the macro editor's Import or Show Creator > Import >
  Macros.

## Command editor [D]

- Opens for macro lines, cue commands, agenda events. Title-bar options: **Create Handle** (turns the
  last object typed into a `#[...]` handle that follows the object when it is moved or renamed; Thru
  prevents it; press Please after each object to convert several), Preview Variables, **Resolve
  Executor Assignments** (pressing an executor inserts the assigned object's handle instead of
  `Page n.e`). Defaults per user profile.

## Creating and editing [D]

- GUI: Edit + empty pool object, Insert New Macro Line, type the command; Settings (Name, Scribble,
  Appearance, Tags, Note, Lock, CLI); Test Macro Line, Test Macro, List References, Import, CLI.
- **By command (documented):**

```
ChangeDestination Macro
List                                  (find a free number)
Store 5
ChangeDestination 5
Insert
Set 1 Property "Command" "Fixture"
Insert
Set 2 Property "Command" "At Full"
Set 2 Property "Wait" 2               (Follow and Go are case-sensitive)
ChangeDestination Root
```

  Edit the same way (`Set n Property ...` overwrites); delete rows with `Delete 2` (a list deletes
  several) inside the macro destination [D]. `ChangeDestination` is the long form of `cd` [?: same
  keyword, check the keyword page].
- **CLI (command line interaction)**: with CLI off, tapping a macro runs it directly (pool object shows
  CLI in red; edit, move or delete it by typing `Edit Macro 5`); with CLI on, it interacts with the
  command line. `Edit Macro 5 Property "CLI"`.
- Assign: `Assign Macro n At Page p.e` or `Assign Macro n At Executor e`; also view buttons [D].
  Aaron's Shuffle 2-4 are macros 55-57 on executors 196-198 [C: CONVENTIONS].
- **Several commands on one line with `;`**: MA's own example macro runs `Macro 2; Echo "Macro 1 Line 1
  - Trigger Macro 2"` [D]. The plugin now checks every segment (alpha.6) [C: code, tests].

## Variables [D]

- Types: Integer, Double (six decimals), Text; typeless (a variable can change type); names are
  case-sensitive (avoid spaces). Scopes: **user** (only the creating user profile) or **global**
  (every user in the session).
- `SetUserVariable MyNumber 9` (integer) versus `SetUserVariable MyText "9"` (text); quotes decide.
  Single and double quotes nest: `SetUserVariable MySpecialGroup "Group 'Spots Grid' "`.
- Use: `$MySpecialGroup At 80` (text expanded as a command); `Group $"MyGroupName" At 80` (expanded as a
  quoted name). Wrong quoting gives "Illegal object".
- `GetUserVariable MySpecialGroup`, `GetUserVariable Our*`, `GetUserVariable *` (and the Global forms)
  print to the command line feedback. `DeleteUserVariable` / `DeleteGlobalVariable`: **no Oops**.
- Concatenation: `SetUserVariable R $"A"" "$B` (text, no spaces between parts); numbers add instead:
  `$MyInteger$MySignedInteger` = 7; integer + double = double; quotes convert numbers to text; a double
  cannot become an integer.
- **From properties**: `SetGlobalVariable myShow At Root "MANetSocket" Property "Showfile"`;
  `SetUserVariable "mySeqPrioName" At Sequence 42 Property "Priority" /Look` (`/Look` gives the name of
  an indexed value).
- MA's example "song setup" macro (one macro per song sets `SetGlobalVariable "currentsong" "FirstSong"`
  and calls a shared SongSetup macro: page by name, select executor, `Off Timecode 1 Thru`, `<<<
  Timecode 1 Thru`, select and `Go+ Timecode "FirstSong"`, `Off Page 2 Thru 100 - "FirstSong"`,
  `Go+ Cue 1`). A pattern that fits Aaron's song-per-timecode setup; note it uses Page ranges, which
  our plugin refuses for itself [D, C].

## Properties by command [D]

- `List Preset 2.1` prints every property (names in caps) to the command line history.
- `Set Preset 2.1 Property "Name" "Signer"`; `Edit Group 8 Property "Appearance"` (opens the picker);
  copy a property between objects: `Set Sequence 42 Property "Priority" At Sequence 1`;
  `Label Group 5 At Sequence` (name of the selected sequence).
- Factory macros that teach this: Selected Sequence Name / Number to UserVariable, Selected
  TimecodeSlot Start Time.

## Handles, wildcards, prompts [D, M]

- `#[Macro 1]` is a handle (follows the object when moved or renamed): `Go+ #[Sequence 23]`,
  `Delete #[Macro 42].1 Thru 5`, `SetUserVariable "MyHandle" #[Macro 1]` or `... At Macro 1`, then
  `Go+ $myHandle` [D, M].
- `*` wildcard: `Group "Mac*"`, `Fixture "backt*blue"`, `Set Macro 5.* Property "Enabled" "Yes"`;
  as a number, all objects of the type [D].
- **User input prompts** in a macro line: `Block Sequence (Sequence #) Cue (Cue #)` asks the operator
  for each value in a command editor; `Fixture (fixturenumber)` in MA's tests [D, M].
- A macro called from another macro's line (`Macro 2; ...`) stops when the calling macro stops; use
  `Call Macro 2` to let it run on [D].
- Factory macro "World Is Selection": `Delete World 999 /NoConfirmation`, `Store World 999`,
  `World 999` [D].
- Macro line properties MA sets by command: `Wait` (`"0.5"`, `"0"`, `Follow`, `Go`), `AddToCmdline`,
  `Execute`, `Enabled`, `Command` [M]; import: `cd Macro; import lib "macro_export.xml" At ...` [M].
- Variables in commands, from MA's tests: `Label Cue $CueNumber $CueName`, `Group DIM At $a$b`
  (10 and 12 add to 22), `Label Cue 1 $"a"" "$"b"`, `Fixture Thru At $myDoubleVar`; an undefined
  variable (`Channel $doesntexist`) is an error [M].

## Commands [D]

| Command | Use |
| --- | --- |
| `Macro 2`, `Go+ Macro 2`, `Call Macro 2` | run (Call keeps running when the caller stops) |
| `Off Macro 2`, `Pause` | stop, pause a running macro |
| `Store Macro n "Name"`, `Edit Macro n`, `Delete Macro n`, `Move Macro a At b`, `Insert Macro` | pool |
| `ChangeDestination Macro`, `ChangeDestination n`, `Insert`, `Set m Property "Command" "..."`, `ChangeDestination Root` | build by command |
| `Import Macro Library "color.xml" At Macro 42`, `Import Library "*.xml"` (destination Macros) | factory library |
| `Set/Get/DeleteUserVariable`, `Set/Get/DeleteGlobalVariable` | variables |
| `List Macro 5`, `List` | show properties in the command line history |

## Traps

- Deleting a variable cannot be oopsed [D].
- Macros run as the user who fires them; a macro that changes pages, fires executors or turns
  things off changes the live stage. Our jobs read macros, never run them (Aaron's Relays macro parks
  group 1100 at 100: firing it during a service changes the house) [C: our reads].
- A macro line's command runs with the same parser as `ma3_command`, so `;` chains apply there too.

## What we have proven

- `ma3_macros` reads every macro with its lines (command, wait, enabled) [C]. No macro created,
  edited or run by a job.

## To bench on onPC

1. Build a macro by `ChangeDestination` + `Set` through `ma3_commands`; confirm line properties.
2. A prompt line `(Sequence #)` sent through the plugin: does it open a dialog that stalls the screen
   thread? (Never on the console until known.)
3. `GetUserVariable *` output: readable by the plugin, or only in the history window?

## Plugin access today, and gaps

- Reads macros and lines [C]. Gaps: variables are not read by a tool (they live per user or global:
  object path [?]); prompts in macros are a stall risk for the plugin.
