# Dimmer curve assignments: what changed between show files (2026-11-08, restored)

Aaron, during the Sunday service: "figure out why dimming curve assignments changed from the last
show file to this show file ... There are dimmers with dimming curves assigned" in the last
late-2026 show file (the previous saved version of `Christmas 2026`). Reads only during service.

## Where MA keeps curve assignments (proven on the console 2026-11-08)

- Per patched channel: the Parameter List = `Root 14.9.9` (`RTChannels`), one `RTChannel` per
  channel with `FID`, `CID`, `IDTYPE`, `CHANNELNAME` and **`DMXCURVE`** (empty = follows the
  fixture type). 11,618 entries on this show.
- Per fixture type: `FixtureType n.6.<mode>.1.<channel>.<logical>` (`LogicalChannel`) has
  **`DMXCURVE`**; `ChannelFunction` below it has `PHYSICALCURVE` (a different thing).
- The curve pool: `Root 14.9.1` (`DmxCurves`): `DmxCurve 1`, MinMax, 0..16777215, the default line.
- MA help: Parameter List "DmxCurve" cell (Follow FT / Ignore FT / a curve), and the fixture type's
  DMX channel "DMX Curve" field. Changes only inside the Patch menu.

Quirk: `RTChannels` is not iterable. `ma3_children` on `Root 14.9.9` returns one child and
`ma3_export` of it writes one `RTChannel`, while `Root 14.9.9.<n>` resolves for every n up to the
count. Read it by index (one `ma3_object` per entry, about 30 ms each). Indices 5..~880 are the
conventional dimmers (`Body Spot_Dimmer`, FIDs 1..478 and 2001..2401); then LEDs and movers.

## Current show, read during the service

- `rt-now-1-900.json`: Parameter List entries 1..900 (889 dimmer channels): **no curve on any**.
- `ft-curves-now.json`: all 24 fixture types, 994 logical channels: **no curve on any**.
- Today's undo history (256 entries): nothing touching curves or the patch.

So in the current file every dimmer follows its fixture type, and no type carries a curve. If the
previous file had curves on dimmers, every assignment is gone.

## Old show `Late 2026 2`, read on onPC (2026-11-08, after the service)

Aaron loaded the previous show on onPC on this Mac with the alpha.4 plugin from the stick;
`tools/mcp_call.py` reached it through `MA3_MCP_URL` / `MA3_MCP_PIN` (added today).

- Curve pool `Root 14.9.1`: `DmxCurve 1` (default), `2 Rear House` (MinMax, MinX 50 %, MinY 15 %),
  `3 Seat Lights` (Custom, two points, inverted: In 0 -> Out 100 %, In 100 % -> Out 0, Accel 33 %).
  Exported with `Export Root 14.9.1.<n> "<name>"`, which writes `gma3_library/patch/dmxcurves/<name>.xml`;
  copies here: `Rear House.xml`, `Seat Lights.xml`, `curves-old.xml` (the whole pool).
- Parameter List: all 6,437 entries read by index (`scan_rt.py`, 50 entries/s on onPC,
  `rt-old-all.json`). Exactly 11 channels carry a curve, all `Body Spot_Dimmer` of `### Dimmer` fixtures:

| Curve | Dimmer FIDs |
| --- | --- |
| Rear House | 197, 200, 285, 286, 287, 288, 289, 307, 310 |
| Seat Lights | 210, 294 |

- Fixture types (`Root 14.9.6`, 21 types, 915 logical channels, `ft-old-export.xml`): no curve on any.

**Current `Christmas 2026`:** pool has only `DmxCurve 1`; the same 11 dimmers exist (Parameter List
indices 179, 182, 192, 251-255, 260, 273, 276 on both the console and the onPC copy) with no curve.
So the pool lost both curves, and with them every assignment. How `Christmas 2026` was created from
`Late 2026 2` is the open question for Aaron.

## Command facts learned on the onPC copy (reads and reverted writes)

- `Set Root 14.10.9.<n> Property "DMXCURVE" <k>` works with the Patch window open; `k` is the
  0-based pool index (0 = `DmxCurve 1`, 1 = second curve). A name or `DmxCurve 2` is "Illegal value";
  `""` clears. `Root 14.10` (the editable copy) is empty until the Patch window opens; writes there do
  not touch `Root 14.9` until the patch is saved.
- `Store Root 14.10.1.<n>` creates a blank curve; `Delete Root 14.10.1.<n>` removes one.
- **Mistakes:** `Store DmxCurve 4` (three times) and `Import "Rear House" At Root 14.10.1.5` each
  returned OK or Failed and created an unpatched *fixture* named `4` / `Rear House`: an unknown
  keyword in front of a name is taken as a fixture name while the patch is the destination. Aaron
  saw them in the Patch window. They were in the unsaved onPC copy only; he reloads without saving.
  Rule from now on: no syntax experiments on a loaded show without showing the command first.
- MA help, Import keyword: `Import [Object] Library "File Name.xml" (At <object>)`; the file is read
  from the library folder that matches the destination. The `Library` keyword was missing from the
  failed attempt. Untested: `Import Library "Rear House.xml" At Root 14.10.1.2`.

## Restore plan (rehearse on the onPC `Christmas 2026` copy, then the console)

With the Patch window open on the target machine, one undo group `dimmer-curves`:

1. `ma3_backup`.
2. `Import Library "Rear House.xml" At Root 14.10.1.2`, read `Root 14.10.1`: expect slot 2
   `Rear House`, MinMax, MINX 8388608, MINY 2516582. If a fixture appears instead, stop and report.
3. `Import Library "Seat Lights.xml" At Root 14.10.1.3`: expect slot 3 `Seat Lights`, Custom, 2 points.
   Fallback for 2-3: Aaron imports the two files in Patch > DMX Curves (Import button); on the console
   the files go to the stick at `grandMA3/gma3_library/patch/dmxcurves/`.
4. `Set Root 14.10.9.<i> Property "DMXCURVE" 1` for i = 179, 182, 251, 252, 253, 254, 255, 273, 276;
   `... 2` for i = 192, 260. Read back all 11 from `Root 14.10.9`.
5. Aaron closes the Patch window and saves the patch. Read `Root 14.9.1` and the 11 live entries
   from `Root 14.9.9` to confirm; then he saves the show (console: `ma3_save` or his own save).

## onPC rehearsal, 2026-11-08 10:38 (Aaron: "go for onPC")

Ran steps 1-4 on the onPC `Christmas 2026` copy exactly as planned: backup `Christmas 2026_mcp_1108_1038`,
both Imports returned OK and the pool read back `2 Rear House` (MinMax, 8388608 / 2516582) and
`3 Seat Lights` (Custom, 8388608 / 8388608, 2 points); fixture count unchanged (no stray fixture);
the 11 `Set` commands all OK in undo group `dimmer-curves` and every channel read back with the right
curve. `Import Library "<file>.xml" At Root 14.10.1.<n>` is the proven creation syntax. Waiting on
step 5: Aaron saves the patch, then the live `Root 14.9.1` / `Root 14.9.9` reads confirm.

## Console run, 2026-11-08 16:42 (Aaron: "Go for console, patch is open")

Backup `Christmas 2026_mcp_1108_1642`. The curve files were on the stick (console Drive 2, `MA3`,
PATH `/media/sdb2`) under `grandMA3/gma3_library/patch/dmxcurves/`. Command-line import from the
stick failed with "Object not found" in every documented form: `Import Library "Rear House.xml" If
Drive 2 At Root 14.10.1.2`, `SelectDrive 2` (also "Object not found") then the plain Import, and
`... /Path "/media/sdb2/grandMA3/gma3_library/patch/dmxcurves"`. The plain Import created a blank
`DmxCurve 2` at the destination (deleted again with `Delete Root 14.10.1.2`). No fixture was created
(the `Library` keyword makes the quoted text a file name). Conclusion: the command line imports from
the console's own library or the UI-selected drive only; selecting the stick is a GUI step. Hand-off:
Aaron imports the two files in Patch > DMX Curves (slot 2 Rear House, slot 3 Seat Lights), then the
11 `Set` commands run as on onPC.

Aaron imported both curves in the Patch window (read back: slot 2 Rear House MinMax 8388608/2516582,
slot 3 Seat Lights Custom 8388608/8388608, 2 points each; fixture count unchanged). The 11 indices
were checked against their FIDs first, then the 11 `Set Root 14.10.9.<i> Property "DMXCURVE" <k>`
commands ran in undo group `dimmer-curves` (all OK, read back correct, group closed). Waiting on
Aaron saving the patch, then the live `Root 14.9.1` / `Root 14.9.9` confirmation.

**Open (Aaron, 2026-11-08): "we need to figure this out for you later, so I don't have to do it"**:
a command-line way to get a file from the stick (or from this Mac) into the console's library so
`Import Library ... At Root 14.10.1.<n>` works without the GUI. Candidates: find the keyword that
selects a drive (the help lists `SelectDrive`; the console answered "Object not found", maybe a
different spelling or argument form); the `/Path` option's expected form (absolute path to the folder
failed; try the file, or a path relative to the drive root); `Copy`-ing a file between drives; or,
with Lua on (alpha.5), writing the XML straight into the console's `gma3_library/patch/dmxcurves/`
with `io.open` and then importing from the internal drive. Try on onPC first with a second
"drive" folder; nothing on a loaded show without showing the command.

**Done 2026-11-08, confirmed live.** Aaron saved the patch; `Root 14.9.1` holds `1 DmxCurve 1`,
`2 Rear House`, `3 Seat Lights`, and the 11 live `Root 14.9.9` entries carry the right curve. Fixture
count unchanged. The show itself still needs a save (Aaron's, or `ma3_save` on his word).

## Lost again, found 2026-11-14 (Aaron: "I think when the console crashed we lost our updates")

Read on the console (alpha.6, `Christmas 2026`): `Root 14.9.1` holds only `1 DmxCurve 1`; the 11
dimmers sit at the same Parameter List indices (179 = FID 197 ... 276 = FID 310, every FID checked)
and none has `DMXCURVE`. Most likely cause: on 2026-11-08 the patch was saved (applied to the live
patch) but the show file was not saved before the freeze forced the restart, so the console came back
on the last saved file. Saving the patch is not saving the show. Not proven: we cannot read the show
file's save times on the console. Lesson: a patch job ends with a show save, confirmed, the same day.

Restore plan (shown to Aaron 2026-11-14): he opens the Patch window and imports `Rear House` into
DMX Curves slot 2 and `Seat Lights` into slot 3 from the stick (proven way); `ma3_backup`; read
`Root 14.10.1` names and `CURVEINDEX`; 11 `Set Root 14.10.9.<i> Property "DMXCURVE" <CURVEINDEX>`
in undo group `dimmer-curves`, read back; he leaves the patch with Save; read the live pool and
channels; then the show is saved (his save, or `ma3_save` on his word) and confirmed.

## Restored 2026-11-14, no writes needed

Backup `Christmas 2026_mcp_1114_2340`. Aaron imported `Rear House` and `Seat Lights` on onPC on his
laptop, joined to the console's session, from onPC's own library (`gma3_library/patch/dmxcurves/`,
same bytes as the copies here). Read on the console right after: editable `Root 14.10.1` and live
`Root 14.9.1` both hold `2 Rear House` (MinMax, CURVEINDEX 1, 8388608 / 2516582) and `3 Seat
Lights` (Custom, CURVEINDEX 2, 2 points). All 11 dimmers already read the right curve in both
`Root 14.10.9` and `Root 14.9.9`, before any `Set` was sent. So the plugin wrote nothing.

What this suggests (not proven, bench on onPC): a channel keeps its curve reference when the curve
leaves the pool; the property reads empty while no curve answers to it, and the assignment comes
back when a curve returns at the same place. Also unexplained: the live pool showed the curves while
the desk's Patch window was still open (the import on the session's onPC may apply straight away).
Still to do: Aaron leaves the Patch window with Save on both stations, then saves the show.
