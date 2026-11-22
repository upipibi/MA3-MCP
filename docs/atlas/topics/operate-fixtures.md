# Operating fixtures: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Operate Fixtures", 23 pages, 20 keyword pages),
20 of MA's programmer, selection and clone tests, the release notes 2.2 to 2.5, and our group and
layout jobs (selection grid by command). Study pack: `python3 tools/atlas/pack.py "Operate Fixtures"
--terms prog,fixture_at,selection,clone,align,attribute_at,special,smart`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

**Everything in this chapter acts on the operator's live programmer or selection.** A job that selects
fixtures or sets values changes what Aaron is working with and, unless Blind is on, the stage. Our
rule: clear the selection before and after, never set values during a service [C].

## Selecting fixtures [D]

- `Fixture 1 Thru 5`, `Fixture 1 Thru 10 - 6 Thru 8`, `Fixture 1 Thru 5 + 9 Thru 10`, `+ Fixture 5
  Thru 7` (add), `- Fixture 5 Thru 7` (remove); fixture sheet taps, 3D lasso, group or preset taps.
- **Sub-fixtures with a trailing dot**: `Fixture 301.` (fixture and all its sub-fixtures),
  `Fixture 301 Thru 303.`, `Fixture 301.1. Thru` (all pixels of a sub-level), `Fixture 301.1. Thru 4 + 6`;
  `Fixture Thru .` = everything at every level; `Fixture Thru` = every top-level fixture.
- Selection Bar window: Previous, Set, Next, Full.

## The selection grid [D, C]

- A 3D grid of boxes giving fixtures a relative arrangement for MAtricks, phasers, ranges and
  selection order (not their stage positions; the 3D viewer can push its view into the grid).
- **Grid cursor** (blue; origin 0/0/0 has a white frame): selections land at the cursor; Move Grid
  Cursor after a selection: None, **Append X** (next free X), **New Line** (X=0 on the next line);
  Preserve GridPositions (keep gaps and offset from the origin).
- `Grid 1/2/1` moves the cursor (Z can be omitted); `Grid 1 Thru 3/2` makes a multi-cell cursor;
  selecting into a multi-cell cursor fills it. Our Group 706 used `Grid 0/<row>` then `Fixture a Thru b`
  per row [C].
- **Grid tools by command**: `Grid "Linearize" "Numerical"` / `"LeftToRight"` / `"TopToBottom"`,
  `Grid "RemoveGaps"`, `Grid "RemoveOffset"`, `Grid "Align" "Left"` / `"Center"` / `"Right"`,
  `Grid "Transpose"`, `Grid "Rotate" "Right"` / `"Left"`, `Grid "Flip" "X"` / `"Y"`, `Grid "Multiply" 6`,
  `Grid "Divide" 2`, `Grid "MakeSymmetrical"`, `Grid "UseMatricksPositions"`;
  `Grid "Perspective" Camera 3` / `Grid "Planar" Camera 3` (not with sub-fixtures).
- Setup mode: drag fixtures (negative coordinates allowed). Window settings: Tool Bar, Align Bar,
  MAtricks Transformation, Centerline X / Y, Gridlines, Auto Scroll.
- Stored with groups, presets and cues. Group preferences: Move Grid Cursor 1D / 2D-3D Selection.
- `Down` on multi-instance fixtures arranges sub-fixtures by their fixture-type geometry grid; `Up`
  returns. **`GridStore`** writes the current sub-fixture arrangement back into the fixture type
  (applies to every fixture of that type).
- Align ranges per row or column with Rx / Ry / Rz in MAtricks.

## Parent and child fixtures [D]

- Setting an attribute a sub-fixture lacks changes the parent's attribute (Pan on a pixel moves the
  head). Changing sub-fixture values shows the parent with a dark red background and the min..max of
  its children.

## Fixture sheet [D]

- Every object with an FID or CID; modes **Fixture** (attributes as columns), **Channel** (tiles with
  intensity and colour), **Dimmer+** (plus the selected feature group), **Sheet/Filter** (all attributes
  unless masked).
- Settings: Layer (or Auto), Step, Readout (Auto, Natural, Percent, PercentFine, Physical, Decimal8/16/24,
  Hex8/16/24), Speed readout, Preset display (ID, Name, Value combinations), ChannelSet display, Sheet
  Mode, #Columns, Adjust Columns, Transpose, Merge Cells, Fixture Sort, Feature Sort, Layer Toolbar,
  Color Mode, Time Format, Frame Readout, Appearance, Font Size, Fixture Appearance, **Fixture Graphic**
  (None, Flip, Simple, Gobo) and its Source (Auto, Value, Output, DMX), Feature Graphic. Mask: Show ID
  Type, Show Fixture Name, Hide Subfixtures, Sorted By FID / CID, Group By ID Type.
- Filters, worlds and the selection can be assigned to a sheet (sheet masking).

## The programmer [D]

- A temporary store per user profile with three levels: selected fixtures, **active** values (stored on
  Store), **deactivated** values (still output, not stored). `Please` twice activates every attribute
  of the selection; once more deactivates.
- Remove: Off + tap a value (KnockOut); Off + a feature-group button.
- **Clear** in three presses: deselect; deactivate (an immediate store would be empty); release
  everything. Hold Clear one second = clear all. Keywords `ClearSelection`, `ClearActive`, `ClearAll`,
  `Clear`.
- Played-back sequences outrank the programmer by default; **Freeze** gives the programmer priority.
- **Blind**: programmer values stay off the stage; clearing the programmer in Blind before leaving it
  leaves the output unchanged; Program Time is ignored on entering or leaving Blind.
- **Preview**: a separate programmer with no stage output; **one preview programmer for the whole
  session** (users can overwrite each other's preview values).
- Layers (Encoder Bar, Layer Toolbar, keywords): Absolute, Relative, Fade, Delay, phaser layers,
  **CueAbs / CueRel** (which sequence, cue and part currently drives each attribute: a read of "why is
  this light on"), **DMX** (resulting DMX; tester values highlighted white), Output.

## Align [D]

- Distribute values across the selection order: modes Off (default), `/` (fan from the middle),
  `<` (from the first), `>` (from the last), `><` (from the centre), `<>` (from both ends); transitions
  Linear, Sinus, Slow, Fast (`AlignTransition`); XY Rotation across the selection grid. Active until a
  different attribute is adjusted. Align Bar window.
- By command: `At 75 Thru 10 Thru 75` (a range across the selection).

## Clone (rewrites programming across the whole show) [D]

- Reuse programming for new fixtures, move values between fixtures or attributes (Gobo1 to Gobo2),
  transfer through sequences, groups, presets, worlds and layouts. **It modifies the show file
  everywhere it reaches.**
- In the patch: Copy + Paste fixture rows clones their show data when the patch is saved (rows show
  "Cloned <FID>" until then); paste onto another stage to clone there.
- Clone menu (`Clone` + Please): source left, destination right (matched line by line; the shorter side
  repeats from the top in grey); object buttons Filters, Sequences, Groups, Presets, Worlds, Layouts
  (green = all items, yellow = selected, grey = none); Clone Show or Clone Programmer; mode pop-up
  **Low Priority Merge / High Priority Merge / Overwrite**; Include Dependencies (Clone Show only).
- Commands: `Clone Fixture 1 At Fixture 2` (opens the menu); `... If Programmer` (programmer only,
  priority pop-up); with `/NoConfirmation` it runs at low priority with no pop-up; `Fixture 2 At
  Fixture 1` equals cloning in the programmer. MA's tests: `Clone Fixture 1 At Fixture 3 If Cue 1
  /MergeLowPriority`, `If DataPool 1 /Overwrite`, `Clone Fixture 11 Attribute "ColorRGB_R" At Fixture
  11 Attribute "ColorRGB_B" If Programmer /Overwrite`, `Clone ... If Layout 3` [M].
- **The plugin adds `/NoConfirmation` to Clone**, so a Clone sent through it runs without the pop-up
  [C: tool rule]. A show-wide clone is a programming rewrite: shown plan and Aaron's go only.

## Special dialog, gels, sMArt [D]

- Special Dialog window: colour (picker with CIE, fader, swatch book), shapers, and other feature
  controls in one place. Gels pool (gel colours for conventionals, editable). sMArt: a dynamic pool of
  the fixture type's channel sets (gobo slots and the like) for the selection; tap to set.

## Keywords in this chapter [D]

`At` (and `At Cue 3`), `AlignTransition`, `Blind`, `Clear`, `ClearActive`, `ClearAll`,
`ClearSelection`, `Clone`, `CueAbsolute`, `CueRelative` (layers), `Gel`, `Grid`, `GridStore`, `If`,
`KnockOut`, `Thru`; options `/MergeHighPriority`, `/MergeLowPriority`, `/NoConfirmation`, `/Overwrite`.

## Traps

- Commands that set values (`At`, `Full`, presets) light the stage unless Blind is on; the operator's
  programmer is shared with the plugin's command line [C: the plugin types on Aaron's command line].
- Clone and GridStore change more than they appear to (the whole show; every fixture of a type) [D].

## Plugin access today, and gaps

- `ma3_programmer` (alpha.7, 2026-11-21) reads every profile's programmer (empty or not, bytes per part,
  `{values:true}` exports the contents) and selection counts [O: object reads on empty programmers;
  ?: a programmer with values; not on the console yet]. Path: `UserProfile n.1.<env>.3` (`Programmer`)
  > `ProgPart` (`MEMORYFOOTPRINT` 297 when empty); selection `UserProfile n.1.<env>.<ACTIVESELINDEX>`
  (`COUNTTOTALSELECTED`, `COUNTFULLYSELECTED`, `ACTIVE`). Slot 5 of an environment is not an object.
- No tool reads which fixtures are selected or the CueAbs layer [?]. A future read of "which cue
  drives this attribute" would answer live questions without screens.
