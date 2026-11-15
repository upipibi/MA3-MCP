# DMX curves: what we know, how sure we are, how to do the work

Written 2026-11-08 after the curve restore on `Christmas 2026`. Aaron: "I didn't feel you were
confident in your existing knowledge about the curves and how to fix it." This page is the answer:
everything the help, MA's own code and our two sessions say about DMX curves, each statement marked
with its evidence.

Evidence marks: **[D]** documented in the MA help 2.5 · **[M]** used in MA's own Lua shipped with
2.5.1.1 (`gma3_2.5.1/shared/resource/`: system test `lib_plugins/systemtests/db/system_test_dmx_curves.lua`,
menus `lib_menus/ui/popups/dmx_curve_popup.lua`, `lib_menus/ui/fixturesetup/dmx_curves.lua`) ·
**[O]** proven on onPC 2026-11-08 · **[C]** proven on the console 2026-11-08 · **[?]** not proven.

## What a curve is

- A curve reshapes one DMX channel's output; default is linear 0-100 % [D]. Modes: **MinMax**
  (a straight line between two points, used to limit output), **Switch** (two points, on/off with
  hysteresis), **Custom** (up to 63 points with Accel/Decel handles) [D, M].
- Up to 9,999 curves per show [D]. A curve whose output drops below an earlier value is shown in red
  and counted as a warning (`NotInvertibleCount`, `ApproxInvertibleCount` on the pool) [D, M].
- `UseForVisualization` decides whether the 3D view shows the curved output [D].
- MA ships three curves to import: `Sinus`, `Square`, `PowerCorrection`
  (`gma3_2.5.1/shared/resource/lib_dmxcurves/*.xml`) [D, O: files present].
- Fixture types with measured emitters create curves automatically and apply them to logical
  channels; an unused auto curve is deleted automatically [D, M].

## Where curves live in the object tree

| What | Object path (2.5.1.1) | Evidence |
| --- | --- | --- |
| Live curve pool | `Root 14.9.1` (`ShowData > LivePatch > DmxCurves`), class `DmxCurve`, points class `DmxCurvePoint` | [C] |
| Editable copy (Patch window open) | `Root 14.10.1`; Lua `Patch().DmxCurves` while the patch is being edited | [O, M] |
| A curve's properties | `NAME`, `CURVEMODE`, `MINX`, `MINY`, `MAXX`, `MAXY` (0..16777215), `CURVEINDEX`, `USEFORVISUALIZATION` | [C] |
| Per-channel assignment | Parameter List `Root 14.9.9.<n>` (`RTChannels`), property `DMXCURVE` | [C] |
| Per-fixture-type assignment | `FixtureType > DMXModes > <mode> > DMXChannels > <channel> > <logical channel>`, property `DMXCURVE` | [D, M] |
| Different thing | `ChannelFunction` property `PHYSICALCURVE` is not a DMX curve | [C] |

The Parameter List cannot be listed with `ma3_children` (returns one child) but every
`Root 14.9.9.<n>` resolves [C]. An entry moves when fixtures are re-patched or added (the same
dimmer was entry 189 in one show and 179 in the other) [C]; MA moves a channel's curve with it when
its DMX address changes [D].

## The three states of a channel's curve

The Parameter List's DMX Curve cell offers [D]:

1. **Follow FT** (empty, the default): the channel uses its fixture type's curve, if any.
2. **A curve:** this channel uses that curve.
3. **Ignore FT:** this channel ignores a curve set in the fixture type. [?] Which value the property
   holds for this state is not known; bench it on onPC before relying on it.

## How the value is written

- The value of `DMXCURVE` is the curve's **`CURVEINDEX`** property, not its pool number. MA's own
  pop-up fills its list with `Curve.Name, Curve.CurveIndex` [M]. On Aaron's show `CURVEINDEX` was pool
  number minus one (Rear House: pool 2, index 1) [C], which is why "slot minus one" worked; after a
  curve is deleted or moved the two can differ [?]. **Always read `CURVEINDEX` first.**
- Command form that worked: `Set Root 14.10.9.<n> Property "DMXCURVE" <index>`, Patch window open [O, C].
  MA's own form: `cd <RTChannels address>` then `Set "<channel name>" Property "DmxCurve" "<index>"` [M].
  A curve name is "Illegal value" [O]; `""` sets it back to Follow FT [O].
- On a fixture type's logical channel MA sets the curve by handle: `Set 1 Property "DmxCurve"
  "<HandleToStr(curve)>"` after `cd` into the channel [M].
- Software 1.9 fixed a crash when a channel was given a curve that did not exist through the command
  line [D]. Never write an index that is not in the pool; read the pool first.

## A channel keeps its curve when the curve leaves the pool

When a curve disappears from the pool, the channels that used it read empty (`DMXCURVE` missing),
but they keep the link: re-import the curve at the same slot and every channel shows it again, with
no command sent. Seen on the console 2026-11-14 (11 dimmers came back on re-import) [C], and Aaron
has seen it happen before [Aaron]. So after curves go missing, **re-import them at their old slots
first and read the channels before setting anything.** Not known: what makes the curves leave the
pool (the 2026-11-14 loss followed a restart on a show file that may not have been saved after
the 2026-11-08 restore) [?].

## Creating and moving curves

| Way | How | Evidence |
| --- | --- | --- |
| By hand | Menu > Patch > DMX Curves > Insert new Dmx Curve; edit mode, name, points | [D] |
| Lua (plugin) | `Patch().DmxCurves:Append()`, then set properties, inside the Patch window | [M] |
| Points by command | `cd <DmxCurves address>`, `Store <curve>.<point>`, `Set <curve>.<point> Property "In" "<v>"` | [M] |
| Blank curve by command | `Store Root 14.10.1.<n>` | [O] |
| Export | `Export Root 14.9.1.<n> "<name>"` writes `gma3_library/patch/dmxcurves/<name>.xml` of the selected drive | [O] |
| Import from the console's own library | `Import Library "<name>.xml" At Root 14.10.1.<n>` | [O] |
| MA's import form | `cd <destination>; cd ..` then `import lib "<name>.xml" at <destination> /NC` | [M] |
| Import from a USB stick | **`Select Drive <n>`** (with a space) to make the stick the library drive, import, then `Select Drive 1` [D: folder structure page]; or `Import Library "<name>.xml" If Drive <n> At ...` [D: syntax] | [?] both untested |
| Import from any folder (plugin) | Lua `<curve handle>:Import("<folder>", "<file>.xml")` merges the file into an existing object [D] | [?] |
| By hand from a stick | Patch > DMX Curves > select slot > Import > pick drive and file | [C] (Aaron, 2026-11-08) |

What went wrong on 2026-11-08 and why, now that the help and MA's code are read:

- `SelectDrive 2` is not a keyword; the console answered "Object not found" because of that.
  The documented form is `Select Drive 2` [D].
- `/Path "/media/sdb2/..."`: a path starting with `/` means the root of the selected drive, not
  the console's file system [D: /Path page]. The right form would have been
  `/Path "/grandMA3/gma3_library/patch/dmxcurves"` with `If Drive 2` [?].
- `Import "Rear House" At ...` without `Library`, and `Store DmxCurve 4` (no such keyword) made
  fixtures named after the text, because the Patch window was the command-line destination [O].
- A failed import still creates a blank curve at the destination [C]; delete it after a failure.

## Rules that make curve work safe

- Curve assignments are patch changes: saving them clears the Oops list, so the backup taken first is
  the only undo [D: Workspace, Oops Menu].
- Every curve change happens with the Patch window open and is only applied when Aaron leaves the
  patch with Save [D, C]. Leaving without saving discards all of it [D].
- Read before writing: the pool (names and `CURVEINDEX`), and the channels by FID, not by Parameter
  List number (numbers shift between shows) [C].
- Known MA bugs worth remembering: editing a fixture type's logical channels could lose its curves
  (fixed 2.4) [D]; save/load lost fixture-type curves (fixed 1.8) [D].

## What happened to Aaron's curves

The previous show `Late 2026 2` had `Rear House` (MinMax: input from 50 %, output starts at 15 %)
on dimmers 197, 200, 285 to 289, 307, 310 and `Seat Lights` (Custom, inverted) on 210 and 294 [O].
`Christmas 2026` had neither curve [C]. The show files' save histories show `Christmas 2026` split
from `Late 2026` on 2026-10-22 and `Late 2026 2` came from a later `Late 2026` save on 2026-10-31
(`tools/showfile/lineage.py`) [O]. So the curves were most likely made in `Late 2026` after the
Christmas show was split off; nothing removed them. [?] Aaron to confirm. Restored 2026-11-08 [C]:
he imported the two files by hand, the plugin set the 11 channels, he saved the patch.

## The restore procedure, next time

1. Read: the target pool (`Root 14.9.1`: names, `CURVEINDEX`) and the channels by FID.
2. Get the curve files into the console's own library: export from the source show, then on the
   console either Aaron imports in Patch > DMX Curves, or (once benched on onPC) `Select Drive <n>`,
   `Import Library ... At Root 14.10.1.<slot>`, `Select Drive 1`.
3. Read the new curves' `CURVEINDEX`.
4. Read the channels: if they already show the curve (see above), stop here. Otherwise, with the Patch window open: `Set Root 14.10.9.<n> Property "DMXCURVE" <CURVEINDEX>` per channel,
   one undo group, read back from `Root 14.10.9`.
5. Aaron leaves the patch with Save; read the live pool and channels from `Root 14.9`.

## To bench on onPC (none of this on the console)

- `Select Drive <n>` + plain import, and `If Drive <n>` import, from a second drive (onPC lists the
  other installed versions' folders as drives).
- The value of `DMXCURVE` for "Ignore FT".
- `CURVEINDEX` after deleting and re-ordering curves; does the channel follow the curve?
- Why curves leave the pool in the first place (see "A channel keeps its curve" above).
- Lua `handle:Import(folder, file)` into an empty curve.
