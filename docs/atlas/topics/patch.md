# Patch and fixture setup: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Patch and Fixture Setup", 21 pages, 25 linked
keyword pages), 27 of MA's system tests, MA's patch menu code, the release notes 2.2 to 2.5, and our
jobs (stage flip, Tornado XYZ, layouts, the curve restore). DMX curves have their own page:
[dmx-curves.md](dmx-curves.md). Study pack: `python3 tools/atlas/pack.py "Patch and Fixture Setup"
--terms patch,fixture,universe,stage,mvr,layer,class,attribute,dmx`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## The patch menu

- Menu > Patch; also the door to Fixture Types, Attribute Definitions, Parameter List, DMX Universes,
  Stages, DMX Curves [D].
- **Every patch change is made in an editable copy and only applies when the menu is left with Save;
  leaving without saving discards everything** [D, C]. The editable copy is `Root 14.10` (empty until
  the menu opens) [C]; Lua `Patch()` returns it while the menu is open [M]. Fixture types can only be
  changed there; `FixtureType n` on the live patch ignores writes silently [C].
- Buttons: Insert New Fixture, Delete, Cut / Copy / Paste rows (reorder), Edit DMX Mode (fixture type
  editor for the first selected fixture's mode), Export (whole or selected patch as grandMA3 XML to
  `gma3_library/patch` or as MVR to `gma3_library/mvr`), Patch (Edit Patch pop-up), Create
  Multipatch, Select Up / Select Down (move through grouping levels) [D].
- MVR import lives in Show Creator > Partial Show Read [D]. Our stage model came in as MVR [C].
- Channel map in the insert dialogs (Channels or Structure view) [D].
- Columns: Condensed or Full; filters (pool filter + per-column filters, filter icon on), Split View by
  Fixture Types, DMX Universes (incl. Unpatched), Filters, Hierarchy, ID Types (incl. No ID), Layers,
  Classes; Show 3D Positions (a small 3D view at full intensity, Wireframe, Beam Simple/Line,
  BodyQuality Box/Standard/Ultra) [D].
- **Trap we hit:** with the patch as the command-line destination, an unknown keyword in front of a
  name stores a fixture with that name (`Store DmxCurve 4`, `Import "Rear House" At ...` without
  `Library`) [O].

## Fixtures and IDs

- A fixture = a row: fixture type + one mode, attributes become parameters [D].
- 12 ID types: locked Generic (preprogram, swap types on site), Fixture, Channel, MArker, Multipatch,
  PSR (system use only); six renamable custom ones, defaults Houselights, NonDim, Media, Fog, Effect,
  Pyro; each name is a keyword (renaming changes the keyword) [D].
- A fixture has an FID and/or a CID (in another ID type); at least one is needed to operate it.
  Channel key repeated cycles the ID-type keywords [D].
- Fixtures live on a stage (Stage 1 by default); Class and Layer group them; a **Grouping** fixture
  (generic) holds children and its ID selects them all [D]. Aaron's rig uses grouping fixtures
  (`Dimmer Racks` 88888, `Key / Wash` 1800) [C].
- DMX address `universe.address` (`3.54`) [D, C].

## Adding fixtures [D]

- Insert New Fixture wizard: Show tab (types already in the show; Used only) or Library (drive:
  internal, earlier installed versions, USB; sources MA, User, Shares when a World Server connection
  exists); search across manufacturer, fixture, mode; then name, quantity, first ID, (Full mode: ID
  Type, CID, Layer, Class), first address; Create.
- grandMA2 fixture files are not loaded directly; MA's converted grandMA2 library is.
- Close the menu with Save and Exit to apply.

## Patch columns (Full mode) [D]

FID, IDType, CID, Name, FixtureType, Mode, Patch, Layer, Class; Offset Pan / Offset Tilt (degrees,
applied at output, not seen in programmer, cues or presets: for a re-hung fixture); DMX Invert Pan /
Tilt; Invert 3D Pan / Tilt (visualiser only); Enc Invert Pan / Tilt (encoder direction); Pos X/Y/Z,
Rot X/Y/Z, Scale X/Y/Z; Gel Color (added to output and 3D); Note; Tags; Beam Angle; Shadow Quality
(None to Very High; needs Cast Shadow); Cast Shadow; Follow Target; Selectable 3D; Visible 3D; MIB
(Yes **disables** MIB for the fixture); Target Space and Movement Space (MArker fixtures); **Master
React** (None: ignores group and grand masters and solo / Group / Grand); Grid Rot and Inv (six, for
sub-fixtures in the selection grid); Material Overwrite (appearance as material, for example NDI on a
plane); Appearance (patch and fixture sheet).

Properties we have read and written on the console: `FID`, `CID`, `IDTYPE`, `PATCH`, `FIXTURETYPE`,
`MODE`, `SUBFIXTUREINDEX`, position for layout work [C]. [?] Map the rest by name on onPC.

## IDs and addresses [D]

- IDs: select FID or CID cells in order, type a number, Please: numbered in selection order.
- Addresses: type `2.1` into selected Patch cells (in order), or the Edit Patch pop-up (left: selected
  fixtures; right: universes, red when the universe is not granted; encoder bar for fixture, universe,
  address). Buttons: PatchTo, Unpatch, Move Patched To Selected Universe (keeps addresses), AddressMode
  (Univ.addr / Absolute), Patch To Next Free Address, Patch To Next Free Universe, SkipPatched,
  PatchOffset (gap between fixtures). Closes itself when all are patched.
- Leaving the menu asks what to do with the changes (pop-up).
- Leave pop-up: Save and Exit / Discard and Exit / Stay in Patch [D]. Aaron saves the patch himself;
  a job prepares the editable copy and hands over [C].

## Which pan/tilt invert [D]

1. 3D turns the other way from the real fixture (and a third-party visualiser agrees with the real
   fixture): the fixture type's physical range is wrong; use **Invert 3D** (no DMX change). With XYZ
   active, fix the fixture type instead: Invert 3D plus XYZ inverts the DMX.
2. Real fixtures turn opposite to every visualiser: invert the **DMX** (in the patch or in the
   fixture's own menu; mind stored positions).
3. Facing rows should turn the same way on the encoder: **Enc Invert** on one row.

## Multipatch [D]

- Virtual fixtures that mirror a primary fixture's parameters; own DMX address with output; no extra
  parameters while the primary is patched and granted; in layouts and 3D; **not in the selection grid
  (no MAtricks)**; selected in light red.
- Select with `Fixture 2 Multipatch 1` (index on the primary; stable). `Multipatch 3` uses the hidden
  multipatch CID, which changes when the patch changes: do not use it.
- Moving the primary or adding multipatches elsewhere can renumber them. Created in the patch menu:
  Create Multipatch, an amount, then addresses.

## MVR [D]

- Import: Show Creator > Partial Show Read (MVR support). Export: patch menu > Export > MVR (default)
  or grandMA3; Entire Patch or Selected Fixtures (fixture files, stage elements, classes and layers
  included) to `gma3_library/mvr`; save the show first. `/MVR` option keyword. MVR-xchange in the In &
  Out menu exchanges files over the network.

## Live Patch [D]

- A limited patch menu where changes apply **immediately** (no save step) and nothing can be added or
  removed. Editable: Name, Patch, the offset and invert columns, position and rotation, Gel Color,
  Note, Tags, Beam Angle, shadows, Follow Target, Selectable / Visible 3D, Master React, automatic
  position points, grid rotation and invert, Material Overwrite, Appearance. Also an RDM Fixtures menu.
- So a **re-address in Live Patch hits the output at once**: never through the plugin during a service.

## DMX sheet and tester [D]

- The DMX sheet shows the real output (sequences, programmer, merged input, masters); all 1024
  universes; Value / Attribute / ID per cell; red labels = not granted; settings: Only Selection,
  Universe, Address, Readout (Percent / Decimal / Hex), Address Mode, Level Bar (Off / Background / Bar /
  Programmer), Follow Preview, DmxTestBar.
- DMX tester (encoder bar or the `DMXAddress` / `DMXUniverse` keywords): test value on addresses,
  Retain, DMX Channels All / Patched / Unpatched, Release Selected / Unselected / All, **Park /
  Unpark Selected**; tested cells turn white; the universe pool and command line show park and tester
  icons (tester icon flashes red). The tester drives the real output: never during a service.

## DMX universes [D]

- 1024 universes (Menu > Patch > DMX Universes): Lock, No, Name, Scribble, Appearance, Note, Tags,
  Merge Mode (incoming DMX), **Request** (Auto: requested when something is patched / On / Off: useful
  when parameters run short), **Granted** (read-only), Coarse Params, Used.
- Universe pool: top bar green when granted, red when not, flashing bright green with output.
- Pool icons: merge mode P (Prio) / H (HTP) / L (LowTP); park icon; tester icon; tag and note icons;
  port icon (green out, orange in, cyan both, dark cyan out with RDM, black no output); `S` sACN and
  `A` Art-Net output indicators (flash green with changing output); orange `sACN In` / `Art-Net In`;
  `PSN In` for MArker fixtures mapped to PSN [D].
- **Moving a universe in the pool moves every fixture patched in it, keeping start addresses** [D].
  `Select DMXUniverse n` [D]. A large `Move DMXUniverse ... Thru ... At ...` then Oops could freeze
  the UI before 2.5 [D: release notes].

## Removing fixtures [D]

- Deleting a fixture row in the Patch menu removes **all programming of that fixture from the show;
  it cannot be oopsed**. Not possible in Live Patch.
- Removing only the address or ID keeps the programming, but the fixture can no longer be edited,
  produces no output and leaves the fixture sheet.
- Our own deletes: the three stray fixtures on the onPC copy were deleted with `Delete Stage 1.2.n`
  [O]; patch deletes on the console need a shown plan and a go (standing rule).

## Positioning in 3D [D]

- Three ways: the (Live) Patch columns, the 3D viewer in Setup, position calibration. New fixtures
  start at 0 / 0 / 0 with no rotation. Metres and degrees only.
- Axes: X stage left positive, Y upstage positive, Z up positive; Rot X positive tips the top
  downstage, Rot Y positive tips the top stage left, Rot Z positive turns counter-clockwise from above.
  (Aaron's layouts read as a plan view: layout left = negative patch X [C: CONVENTIONS].)
- 3D Setup encoder bar: Function (Position/Rotation or Arrangement), Resolution (Coarse 10 cm / 1°,
  Fine 1 cm / 0.1°, Increment 1 mm / 0.01°), Axis (Stage or Object), Rotation Mode (Single or Group),
  Calibrate Position, Change on Encoder Event (send now or 2 s after the encoders stop), Reset
  Position, Reset Rotation.
- Arrangement tool: Line (start and length per axis, Line Up), Grid (columns, rows, spacing, Axis
  Group Type, Reset Z/X/Y, Direction, Row / Column Order), Circle (radius start, radius delta, angle
  start, angle range for arcs or spirals, Rotate to Circle Center); Apply on Change or Apply; purple
  ghosts show the result before it applies.
- **Position calibration**: per fixture, four real-world points (P1-P4, red, green, blue, yellow) and
  the pan/tilt that hits each; Store Px, Call Px, **Solve** computes position and rotation; four points
  recommended. The `Action` keyword stores, calls and solves from the command line. [?] syntax.
- Our layout and Portman jobs set positions with `Set Layout ...` and read patch positions; the stage
  came from Capture as MVR [C].

## 3D viewer [D]

- Shows fixtures and stage objects with beams (haze per render quality); stage as box or floor;
  fixtures can be selected and used with commands; cameras from the Camera pool; shaders compile on
  first open (yellow text, error if it fails).
- Left tools: Select, Follow (point selected movers at a tapped spot, obeys Align), Move, Rotate
  Center, Zoom, Rotate Pivot, Set Pivot, Focus (Setup: aims static fixtures by changing their
  rotation), Fit, Fit Selected, Camera (reload), **3D view to Selection Grid** (grid values from the
  current view).
- Settings: Rendering (Beam, Spot, Ambient, Point Light faders and colours, Background, Lum. Spread
  default 80 %, Dynamic Gobo Resolution, Bloom, Setup, Camera, Stage, Render Quality); Misc (Show fps,
  Wireframe, **Priority: takes resources from the console UI, only on strong GPUs**, Mark Faulty Meshes,
  Show Selection, Lens Shading, ...); Label.
- More 3D settings: Touch Mode (Select, Follow, Focus, camera modes); **Selection Mode** 2D Grid
  (lasso started horizontally/vertically = Planar, green; diagonally = Perspective, cyan; use a 2D camera
  to avoid perspective distortion) or Linearize (yellow, one axis); Mark Unpatched (dark red); Prism
  Lines; Point of Origin; Show Pigtails; Arrangement ghosts; **Show Lines** (beam direction lines:
  None, All, All Dimmer 0, Selected, Selected Dimmer 0: handy to check where dark movers point);
  Render Environmental; Draw Target Spaces; Follow Preview. Labels on body or spot with FID, CID,
  Patch, Name; Select by Label; Max Label Count; Spot Subfixture ID [D].
- A dedicated 3D computer is onPC in the session, logged in as a user with the same profile as the
  operator (so it follows into preview), one big viewer, Priority on [D].

## Render quality, cameras [D]

- Render Quality pool objects (one always selected): Beam (No Beam, Line, Standard, High, High Fancy),
  Shadow (needs Cast Shadow and a Shadow Quality on the fixture), Gobo (Disabled / Enabled / Animated),
  Multi LED Beam Mode (Separated / Single Mean Color / Single Dynamic Gobo), Body Quality (None, Box,
  Low, Simple, Standard: above 1,200 vertices simplified, High: above 10,000, Ultra), Dilution Type
  (None, Linear, Correct), Cull Mode, Light Scale, Render Scale, Native Colors, Dilution Scale; Haze tab
  (needs Priority; disabled automatically when the fixtures' volume is too big or the show passes 90 %
  of the 10 GB data limit).
- Camera pool: the locked **Auto** camera follows the selection; `Select Camera 3`; editing an empty
  slot copies the selected camera; Camera Mode 3D or predefined 2D views; FOV, Roll, Zoom (0.01-1),
  Pos X/Y/Z, Pan, Tilt; Reload Camera applies.

## Stages [D]

- Patch > Stages: Insert new Stage; default 30 x 30 m centred, 0-15 m high; position and rotation;
  name, tags, note; copy, cut, paste, export, import (an exported stage contains its fixtures).
- **Deleting a stage deletes every fixture in it and all their programming.**
- Edit Stage: stage **Spaces** (volumes; used by XYZ and MArker target and movement spaces) and
  **Elements** (flat four-corner surfaces); a new stage has one space and a floor element. Complex
  set pieces come from the "Set" manufacturer in the fixture library.
- Our fixtures are at `Stage 1.2.n` (`Root ... > Stage > Fixtures`) [C].

## Classes and layers [D]

- Two equivalent ways to group fixtures (from MVR and CAD); one of each per fixture; used by patch
  filters and split view. Create in Split View (Full columns) > Layers or Classes > Insert, or with New
  when editing a fixture's cell; None removes.

## Attribute definitions [D]

- Building blocks of fixture types and the encoder bar; **at most 1,024 attributes per show**; 366
  predefined. Columns: Name (unique, locked once typed), Pretty (encoder label), Main Attribute
  (hierarchy), Activation Group, Feature, Special and Special Index (3D), Physical Unit, Geometry
  Type, Color and Intensity (colour engine, for ColorComponent attributes), Natural Readout, Encoder
  Resolution, Log Channels and Channel Functions (usage counts), Hide (off encoders and sheets, still
  in the DMX sheet), MIB (Disabled excludes the attribute).
- **Activation groups** (activate together, for example pan and tilt): editing the factory ones can
  stop values being stored together. **Feature groups** and features: every attribute has a feature;
  every feature group has a preset pool; editing them restructures the show. **Deactivation groups**
  (Position, Color by default): knock out one activation group when another takes over (pan/tilt vs
  XYZ). Changes apply when the patch is saved.

## Parameter List (RTChannels) [D, C]

- Every parameter of the show (`Root 14.9.9`, 11,618 on Christmas 2026 [C]; not iterable, read by
  index [C]). Columns: Lock, No, Name, FID, IDType, CID, ChannelName, Default (+ Preset), Highlight
  (+ Preset), Lowlight (+ Preset), Coarse, Fine, Ultra, DMX Curve. Editable: the special values,
  their presets, and the DMX curve. A filtered copy appears when a fixture is edited.
- Special values by command: select fixtures, set values, `Store Default` / `Store Highlight` /
  `Store Lowlight`; reset with `Store Highlight /Remove` (or `/Release`); Use Selection and If Not Empty
  store options decide which fixtures change; absolute values only; phaser presets use step 1 [D].
- DMX curves: see [dmx-curves.md](dmx-curves.md).

## Commands [D]

| Keyword | Syntax and notes |
| --- | --- |
| Patch | `Patch Fixture 2 3.123` re-addresses one fixture; `Patch Fixture 1 Thru 10` opens the Edit Patch pop-up (not for the plugin); `Patch Fixture 2 Multipatch 3 42.6` |
| Fixture, Channel, ID-type keywords | `Fixture 10.5` (sub-fixture); `Fixture 1 At Cue Next`; `Channel 10`, `Houselights 5`, `NonDim 1`, `Media 2`, `Fog 7`, `Effect 10`, `Pyro`, `Generic 1`, `MArker 30`, `PSR 2` |
| Multipatch | `Fixture 4 Multipatch 2` (stable), `Multipatch n` (hidden CID: avoid) |
| DMXAddress, DMXUniverse | tester values: `DMXAddress 3 At 50`, `DMXUniverse 2.8 Thru 15 At 42`, `Off DMXUniverse Thru`; `SelectFixtures DMXUniverse 2.001`; `Move DMXUniverse 1 At DMXUniverse 11` (moves its fixtures). **Drive real output: never in a service** |
| Park, Unpark | `Park Fixture 1 At 50 If FeatureGroup 1`, `Park DMXUniverse 1.20`, `Unpark DMXUniverse 2`. **Freezes output: never in a service** |
| Invert | `Invert Fixture 1 Thru 15` (fixture order; see MAtricks) |
| Default, Highlight, Lowlight | `Fixture 1 At Default`, `Fixture 2 At Default FeatureGroup 2`, `Store Default`, `Store Highlight /Remove`, `At Lowlight` |
| Action | position calibration: `Action "StoreCalibrationPoint1"`, `Action "CallCalibrationPoint2"`, `Action "SolveCalibration"` |
| Export | `Export Macro 1 "test" If Drive 2`; options `/MVR` for patch export |
| Solo, Select | intensity solo of the selection; Master React None excludes a fixture from solo |

## What MA's own tests add (27 tests) [M]

- **Patching by command inside the patch:** `cd Root ShowData."Patch"` (or `cd fixture`), then
  `Insert Type 'Fixture' At ...`, `Set 2 Property 'Name' 'X' 'FID' 1000 'IDType' 'Channel' 'CID' 2000
  'Patch' '20.1'`, `Set 1 Property 'Patch' ''` (unpatch), `Set 4 Property "FID" 4`,
  `Set Thru Property "OffsetPan" n` / `"OffsetTilt"`, `Delete Fixture 1`.
- Multipatch: `Store 1 MultiPatch 1 Thru 3`, `Set 1 MultiPatch 1 Thru 3 Property 'Patch' '20.1'`,
  `Delete 1 MultiPatch 1 Thru`, `Fixture 1 MultiPatch 2 + Fixture 2 MultiPatch 2`, `SelFix DmxUniverse 20.1`.
- Fixture types in the patch: `cd FixtureType 1`, `cd DMXModes.2`, `Set DMXChannels.1.1 Property
  "Attribute" "Pan"`, `Insert Type "MediaServerLayer"`, `Set 2 "DMXOffset" "2"`, `Delete Geometry`;
  `Import Lib n At 1 /NC`; `Import 1 "generic@moving_head.xml" /Overwrite`; `Export ... /File
  'x.xml' /HighPrecision`; `Assign FixtureType "..."` (exchange). Details on the fixture types page.
- **MVR import by command:** `AddOn 'MVR' 'MVRIMPORTPSR'` [M]; [?] arguments.
- Universes: `Label DmxUniverse 1 Thru 10 "hello 0"`, `Move DmxUniverse 1 At 42`,
  `Move DMXUniverse 1 + 2 At DMXUniverse 42`, `Park DmxUniverse 2.1`.
- Curves: see [dmx-curves.md](dmx-curves.md) (`Set "Dimmer 1" Property "DmxCurve" "<index>"` after `cd`
  into RTChannels).
- Clone (fixture data in the whole show): `Clone Fixture 1 At Fixture 3 If Programmer /Overwrite`,
  `If Cue 1 /MergeLowPriority`, `If DataPool 1`; studied with Operate Fixtures.

## Traps and MA bugs (release notes 2.2 to 2.5.1.1) [D]

- Fixed in 2.5, worth knowing on older shows: deleting fixtures and then setting an FID could crash;
  **deleting a fixture type in the patch could freeze the software (rare)**; exchanging many fixture
  types then unpatching and repatching could crash; PSR of a show with illegal fixture-type data could
  freeze so badly that a full install was needed; **phaser data could be lost after patch changes such
  as changing a fixture type**; MIB with cue recipes could stop after patch changes; changing
  sub-fixtures could break group filters; replacing a GDTF fixture type with the same type in XML
  added dimmer values to colour presets; MVR export dropped group names; re-importing an MVR could
  delete unused classes and layers; moving a large universe range then Oops could freeze the UI;
  deleting fixtures could shift meshes in 3D; the web remote could crash on certain filtered sheets.
- 2.5 change: the grandMA3 export option is now "All Stages" (was "Entire Patch"), written to
  `gma3_library/patch/stages`.
- 2.4: MVR import moved into Show Creator > Partial Show Read and **clears the programmer**; MVR
  object type per fixture type; MVR supports multipatch; PSR can exchange fixture types and import
  single properties (Patch, Position, Rotation); the Universal fixture type is no longer required
  in new shows (universal values move to fixtures whose Special Purpose is Universal).
- Our own: the patch is a job's riskiest area. Deleting a fixture or a stage destroys programming
  with no Oops; Live Patch and the DMX tester hit the output at once; fixture-type edits only stick in
  the editable copy (`Root 14.10`) and only when Aaron saves the patch [C].
- **Saving a patch change clears the whole Oops list** (and loading a show does too), so a patch
  job cannot be undone with Oops and no earlier job can either; `ma3_backup` is the only way back [D:
  Workspace, Oops Menu].

## What we have proven

- Reads: `ma3_fixtures` (all 2,000-plus rows with types, modes, patch), `ma3_object` on fixtures,
  fixture types (`Root 14.9.6`), the Parameter List by index, the editable copy `Root 14.10` while
  the menu is open [C].
- Writes: DMX curve assignment in `Root 14.10.9`, curve creation by import (onPC) [C, O]; fixture
  positions read for layouts; Aaron moved Fuze 1818 himself (31.414) [C].
- Mistakes on record: two stray fixtures from unknown keywords on onPC [O].

## To bench on onPC

1. `Patch Fixture n u.a` versus `Set ... Property "Patch" "u.a"` in the editable copy; read back
   from the live patch after Save.
2. `Insert Type 'Fixture' At` + `Set ... Property ...` to add a fixture by command; then delete it.
3. Every patch column's property name (`ma3_object {schema:true}` on a fixture), especially Master
   React, offsets, inverts, MIB, Gel Color.
4. `AddOn 'MVR' 'MVRIMPORTPSR'` arguments (read MA's MVR test), on a scratch show only.
5. Which universes are granted and requested (`DmxUniverse n` properties).

## Plugin access today, and gaps

- Can read the whole patch, fixture types, the Parameter List, curves, universes [C].
- Gaps: no tool for "what is granted / how many parameters are left"; no read of the DMX output
  (DMX sheet) or park state; the patch-menu save is Aaron's (the plugin cannot close the menu with
  Save, and should not).
