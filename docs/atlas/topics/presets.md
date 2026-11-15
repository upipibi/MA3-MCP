# Presets: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Presets", 6 pages, 6 linked keyword pages), 25 of
MA's preset system tests, the release notes 2.2 to 2.5, and our notes (`docs/PROGRAMMING-STYLE.md`:
Aaron programs songs with hard values; presets drive busking and Portman/Key executors). Study pack:
`python3 tools/atlas/pack.py "Presets" --terms preset,recast,universal`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What a preset is [D]

- A labelled reference to attribute (and timing) values for fixtures, used in cues, recipes, the
  programmer, or played back directly. Updating the preset updates every cue that references it.
  Cyan markers show preset values in sheets and cues.
- **Pools:** one per feature group (Dimmer, Position, Gobo, Color, Beam, Focus, Control, Shaper, Video
  on a default show; addressed `Preset <pool>.<n>`, for example `Preset 4.1` is Color 1), each with an
  input filter for its feature group; five **All** pools (`All 1` to `All 5`, pool 21 to 25, no filter,
  renamable); **Dynamic** follows the selected feature group. Our fake and our reads use
  `Preset 1.1`, `Preset 4.7` [C].

## Preset modes [D]

| Mode | Letter | Data valid for |
| --- | --- | --- |
| Selective | S | each fixture that has stored data |
| Global | G | every fixture of a fixture type (the lowest ID's value; diverging fixtures get selective data too) |
| Universal | U | every fixture that has the stored attributes |

- Pool letters show the stored data levels and the mode (`UGS` = universal mode with global and
  selective data). Store or update options: Default (pool or preset mode), Force Global (drops selective
  data for those fixture types), Force Universal (drops selective and global data).
- Each pool has a default mode (letter in the pool title); presets can be called in a different mode.

## Kinds of content [D]

- Absolute (no marker in pool / dark red) and relative (dark pink) values; timing layers Fade (green)
  and Delay (orange). **A timing-only preset cannot be referenced in a cue**: stored with values it
  becomes individual timing; presets with values and timing are referenced.
- **Embedded presets:** a preset referencing other presets (universal > global > selective chains);
  names in square brackets are referenced names; long chains warn; depth via `ListReference`.
- **Recipe presets:** recipe lines cooked into values (up to 10 nested levels; red infinity icon =
  circular reference); Recipe Templates (open pot) load the recipe into the programmer.
- **MAgic presets:** up to five points per grid axis defining a range applied to any selection (store
  them selective).
- **Multistep (phaser) presets** (three dots; purple pot = phaser recipe); **MAtricks** stored in a
  preset (green nine-dot icon); **filtered** presets (pool or per-preset input filter).
- Feature group indicator bar: white = stored, grey = not, red = not accessible (world) [D].
- **Extract**: `Extract Selection`, `Extract Fixture n`, `Extract Preset 4.1`, `Extract Cue n` put the
  values into the programmer without the preset link; `/Single` goes one level down the embedding [D].
- **Delay To Phase** (per preset): on = each attribute starts its phase when its delay ends (waves);
  off = phase starts at the trigger and attributes join in sync [D].

## Preset pool settings [D]

Name (All pools), Input Filter, Show Empty, Appearance, **Cue Part** (programmer part presets call
into; per pool or per preset), Pool Columns, Display Mode, Font Size, DataPool, colours (pool, empty,
For All / For Some / For None indicator), **First Index** (`Store Preset 1` stores the next dimmer
preset at the pool's First Index; preset pools are the exception where the number after Preset names
the pool), **Preset Mode** (default for new presets), Pool Action. Indicator bar: green = all selected
fixtures can use it, yellow = some; cyan number = fixtures using it now.
- Pool actions available: At, Call, **SelFix/At** (preset default: first tap selects the fixtures
  that can use it, second calls it), SelFix/Extract, Select, Toggle, Go+, Flash, Temp, Top, Pause,
  Off, Goto, Load, None; Use Object Action (per-object action wins); 2 Finger Edit. Selecting by a
  preset does not include grid positions unless stored selectively. Per-preset settings beat pool
  settings [D].

## Creating presets [D]

- Store options (hold Store): Embedded, MAtricks, Recipe Mode (Normal with selection / NoSelection;
  `/Recipe`), **Keep Activation** (new preset stays active in the programmer), Preset Mode, Input
  Filter (on: feature-group pools only accept their attributes; All pools accept anything).
- Filters on pools or presets: `Assign Filter "Name" At Preset 4.1` (or `World`).
- Static preset: select, set values, tap an empty pool object.
- **Global data is held by a real fixture**: the lowest ID of the type; it moves to the next patched
  fixture of the type when that fixture gets selective data or is deleted. Fixture sheet marks: one
  yellow square = global, two = universal. Shows converted from 1.5 or older migrated global data to
  the first patched fixture of the type.
- Universal presets store the first active fixture's data; universal colour goes through the colour
  engine (a 7-colour LED colour becomes a similar RGBA colour).
- Embedded: call a preset, store with Embedded on.
- **Preset mode conflict pop-up**: if the programmer data does not fit the chosen mode, a pop-up offers
  the chosen mode, a suggested one, or cancel. Through the plugin (`/NoConfirmation`) [?] which wins.
- MAgic: needs distinct grid positions (start at 0, adjacent); calling it writes hard values, no link,
  unless used in a recipe; must be stored selective. Workflow: Next through fixtures setting each
  point, Set to reselect, Store, Edit Settings > MAgic on.
- Multistep: store with phaser data in the programmer.

## Recipe presets [D]

- Edit Preset Object pop-up (Swipey > Edit): Recipe Template switch; buttons Insert line, Cut, Paste,
  Delete, Copy, Oops, **CleanUp Recipes** (drop lines that send nothing), Reset MAtricks for Selected,
  **Turn Into Recipe**, **Take Selection**, List References, Edit (into the programmer), **Recast
  Preset**, **Cook**, At.
- Add Standard Recipe makes line 1; later lines copy the first line's preset reference and MAtricks.
  Editing a line cooks on close.
- Three workflows: lines with a selection (cooked in the preset, referenced from the programmer,
  playable from executors); lines without a selection (cooked onto the current selection: hard values
  stay hard, preset values keep links); Recipe Template (lines loaded into the programmer part).

## Using presets [D]

- Validity: universal = any fixture with the attributes; global = fixtures of a stored type;
  selective = only stored fixtures. Without a selection, the first tap selects every fixture that can
  use it (like a group).
- Timing in a preset is called with the values and beats the Programmer Time master; timing-only
  presets call into the timing layers without a reference.
- **Temporary mode**: `At Preset 1.3 /Universal` (also `/Selective`, `/Global`) uses a preset outside
  its stored mode.
- **On executors**: global or universal presets need the At function (values go to the programmer for
  the selection, not played back); Go+, Toggle, Flash and the like play back **selective** data
  (presets can be played from pools too). Preset playback settings: Menu > Preferences and Timing >
  Preset (OffFade when a selective preset playback is switched off; Sync). Aaron's Portman and Key
  executors are presets [C: PROGRAMMING-STYLE].
- **In cues a reference is stored, not the value.** Absolute and relative layers carry their fade and
  delay layers; absolute-linked timing beats relative-linked; phaser layers (Speed, Phase, Measure,
  Accel, Decel, Transition, Width) travel together.
- **Adding or removing attributes after use needs a Recast** (`Recast Preset 4.1` or the editor) and
  recast only reaches cues with a preset link in the absolute layer.
- **Deleting a preset used in cues hardcodes its values into those cues.**

## Editing and updating [D]

- Edit + tap the preset: fixtures selected, values pulled into the programmer **and sent to output
  unless Blind is on first**; Update, confirm OK. Esc leaves edit mode (values stay in the programmer).
- Update menu (presets on the left): Preset Update Mode Original Content Only / Add New Content;
  Preset Mode Default, Selective, Global, Universal, ForceGlobal, ForceUniversal; Input Filter on/off.
- Absolute and relative layers update separately: a new relative value does not reach cues that use
  the preset's absolute value (and the reverse) until a Recast; recipe presets and cues that reference
  an updated preset may need cooking again.
- Preset object editor: pool settings per preset (they win), **MAgic**, **Recipe Template**, Phaser
  Delay To Phase.
- Avoid mixing universal and global data for one fixture type: the merge pop-ups move global data to
  another fixture or store universal data on the last fixture of the type, and results become
  unpredictable.

## Commands [D, M]

| Command | Use |
| --- | --- |
| `Store Preset 4.n` / `Store Preset 4.n /Merge /GridMergeMode "Append X"` | store (store options as above) |
| `Store /Recipe "NoSelection"` | recipe preset without selection |
| `At Preset 1.3 /Universal` | call with a temporary mode |
| `Update Preset 4.1` (`/AddNewContent`, `/OriginalContentOnly`, `/Global`, `/ForceGlobal`, `/Universal`, `/Selective`) | update |
| `Recast Preset 21.1` | push attribute additions/removals into cues (absolute links only) |
| `Extract Preset 4.2`, `Extract Selection /Single`, `FeatureGroup "Color" Extract Selection`, `Extract Selection /Active` | values without links |
| `Cook Preset 1.1` (`/Merge`, `/MergeLowPriority`, `/Overwrite`, `/Remove`) | cook recipes |
| `CleanUp Preset 2.2 /Type "Recipe" /Recipe "NotCooked"` (or `"NoOutput"`, `"CookedButOverwritten"`) | delete recipe lines that do nothing |
| `ListReference Preset 4.7` | where a preset is used, embedding depth |
| `EditSetting Preset 21.5` | preset settings pop-up |
| `Assign Filter "x" At Preset 4.1` | per-preset input filter |
| `Move Preset 1.3 At ...`, `Insert ...`, `Lock`, `Unlock` | pool housekeeping [M] |
| `Attribute "Pan" At GridPosition` | MAgic and grid values [M] |
| `Set Selection MAtricks Property "PhaseFromX" 0 "PhaseToX" 360` | MAtricks in the programmer [M] |
| `Insert Type "StandardRecipe"` | add a recipe line by command [M] |

MA's tests also show fixture-type `ShareGlobal` (`Set FixtureType "x" Property "ShareGlobal" 0`):
whether global preset data is shared between fixture types [M, ?].

## Traps (release notes 2.2 to 2.5.1.1, and ours)

- 2.5 known limitation: **Recast reaches cues only through absolute-layer links** [D].
- Editing a preset sends its values to the stage unless Blind is on [D]: never during a service.
- Deleting a used preset hardcodes it into cues (a quiet, permanent change) [D].
- [?] Read the 2.4 and 2.5 preset bug list in the pack before any preset job (25 pages of release
  notes mention presets: universal colour, recipe cooking, phaser presets).

## What we have proven

- Reading preset pools (`ma3_presets`), objects and exports; preset names and numbers on Aaron's show
  (Portman presets on executors) [C]. No preset has been stored, updated or recast by a job.

## To bench on onPC

1. Store, update, recast and delete a scratch preset used in a scratch cue; confirm the hardcode on
   delete and the absolute-only recast.
2. What `/NoConfirmation` picks in the preset mode conflict pop-up.
3. `ShareGlobal`, `Cue Part` per preset, and the property names of every preset setting.

## Plugin access today, and gaps

- Can read presets, their modes and contents (export) [C]. Gaps: no tool lists where a preset is
  used (`ListReference` output goes to a window, [?] readable), no tool reads which fixtures hold
  global data.
