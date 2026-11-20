# Layouts: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Layouts", 8 pages), 12 of MA's layout tests, the
release notes 2.2 to 2.5, and six layout jobs on Aaron's Layout 1 (Portman, rings, yokes, Q40,
resize; `docs/jobs/2026-11-05-*`). Aaron's layout rules: `docs/CONVENTIONS.md`, "Layouts". Study
pack: `python3 tools/atlas/pack.py "Layouts" --terms layout`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What a layout is [D]

- A 2D draft of fixtures, sub-fixtures, pool objects (groups, macros, sequences, presets, worlds,
  tags, quickeys) and output stations, in the Layouts pool, shown in the Layout Viewer; **at most
  10,000 elements per layout**.
- Elements are `Layout n.m` (class `Element`) with position and size properties; we set them with
  `Set Layout 1.<a> Thru <b> Property "PosX" <v>` (also `PosY`, `Width`, `Height`) [C].
- Aaron's Layout 1 (`Portmans`) fits the default 1920 x 1080 canvas centred on 0 (x -960..960,
  y -540..540); masters 50 x 50 with parts drawn against them; rows 200 apart [C: CONVENTIONS].

## Creating and adding [D]

- Select fixtures, Assign, tap an empty layout pool object (new layout) or a spot in the viewer: the
  **selection-grid positions** become layout positions. Sub-fixtures the same way.
- Pool elements: `Assign Group 1` then tap the viewer; `Assign Macro 1 At Layout 1`; output stations:
  `Assign "HostName" At Layout 3` (network state in the indicator; Edit opens Device Configuration).
- By command we used `Assign Fixture <id[.instance]> At Layout n` and `Store Layout n.m` [C].
- Multipatch: `Assign Fixture 1 Multipatch 1 Thru 5`, then tap the viewer.
- Clone into a layout: `Clone Fixture 1 Thru 6 At Fixture 7 Thru 12 If Layout 3` (Low Priority,
  High Priority, Overwrite pop-up; clones keep element settings with a small offset).
- Setup mode (title bar) gives the toolbar (Auto, Select, Move, Resize, Resize fixed ratio, Add,
  Delete, Align) and the layout encoder bar. Fit Type Elements / Canvas / Both.

## Layout settings (Edit the pool object) [D]

Name, Scribble, Pool Appearance, Canvas Appearance (background; falls back to the pool appearance),
Tags, Notes; canvas **PositionX, PositionY, DimensionW, DimensionH**; Markers (layer markers on
fixtures); **Value Colors** (dimmer values coloured as in the fixture sheet); **ViewPosActive** with
ViewPosX, ViewPosY, ViewPosScale (recall a stored zoom and position: two layouts with the same
fixtures can show different views); **Executor Style** (sequences shown with cues); Render Style for
elements set to Default (2.5).

Layout element defaults (Menu > Preferences and Timings > Layout Elements, part of the user profile)
are templates per object type, including render style and action.

## Viewer settings [D]

Layout (or Link Selected), Setup, Layer (DMX / Value / Output readout), **Lasso Filter** (All /
Fixtures / Others), Show Selection, Right Click To Edit (off prevents accidental edits), **Lock
Position**, Selection Mode (2D Grid / Linearize), Auto Fit, Canvas Fit Mode (Bar / Crop / Stretch),
Fit Type, **Snap To Grid** and Snap Grid (1-14,000 px), Visible Grid, Grid Color, Grid Style (Off /
Lines / Dots), Scale, Show Title Bar. A title-bar button transfers the layout arrangement to the
selection grid.

## Element properties (Edit, or Edit Selected in the encoder bar) [D]

- General: Name, ID, CID, Object (assignment editor), **Action** (Layout Default / Object Default / a
  specific action), Appearance, Full Resolution (many high-resolution images slow the GUI; 150 px or
  less always low quality), Mirror, Appearance Rotation.
- Arrangement: Font Size, **Position X / Y**, Padding, Border Color / Size, **Width / Height**, Element
  Visible, show Name / ID / CID / Border / Bar / Value, Indicator Bar, Selection Relevance.
- Custom Text: text, size, colour, horizontal (Center, Left, Right, OutsideLeft, OutsideRight) and
  vertical (Center, Top, Bottom, Above, Below) alignment, Vertical.
- Several selected elements edit together (selection order decides alignment order). Objects can be
  locked by another user editing them (object ownership).

## Layout encoder bar [D]

- Position: Pos X, Pos Y, Width, Height, Scale, Ratio, Rotate (group of fixtures), Change on Encoder
  Event, Reset Position, Edit Selected.
- Arrangement: Line, Grid, Circle (as in the 3D arrangement tool) and **Camera** (arrange the
  selection as a 3D camera sees it: camera, scale, ratio, move X/Y; Apply or Apply On).

## What MA's tests add [M]

`Store Layout`, `Move Layout`, `Delete Layout`, `Export Layout`, `cd Layout; import lib
"layout_export.xml" At ...`, `Set 2 Thru Property "Name" "sameName"` inside the Layout destination,
`If Layout` selection.

## Traps (release notes 2.2 to 2.5.1.1, and ours)

- Fixed in 2.5: **raising an element's height with the encoder could crash**; Setup values computed
  wrong with `+` or `*` in the calculator; assigning an object reset vertical text alignment to Above;
  deleting a displayed layout then Link Selected flooded Lua errors.
- 2.4: moving elements could jump and resize; loading a 2.2 show in 2.3 lost fixture appearances in
  layouts; a session could misapply MAtricks changes in setup mode.
- Ours: Aaron arranges Layout 1 himself; never move or resize his elements unless the pattern cannot
  fit otherwise, and say so [C: CONVENTIONS]. Read fresh before planning: he edits between jobs.

## What we have proven

- Element creation by `Assign Fixture ... At Layout`, `Store Layout n.m`; position and size by
  `Set Layout ... Property` in one undo group; read-back with `ma3_children` / `ma3_object` [C].
- A box label outside its box: `Set Layout 1.<n> Property "CustomTextAlignmentV" "Above"`; `CustomTextAlignmentH
  "Left"`; element sizes of 8 and 9 are accepted (2026-11-19, ladder job) [C].

## To bench on onPC

1. The canvas and view properties by name (`DimensionW`, `ViewPosActive`, ...).
2. Element `Action` values by command (select-on-tap behaviour for Aaron's master tiles).
3. Custom text properties for labels drawn next to masters.

## Plugin access today, and gaps

- Full read and write of elements [C]. Gap: no layout-specific tool; jobs use generic tools and
  scripts (`docs/jobs/2026-11-05-*/`).
