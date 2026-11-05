# Tornado XYZ: findings (2026-11-05)

Aaron could not enable XYZ on `FixtureType 18` `TORNADO (TB 5 IP)` (SOURCE User, 24 fixtures in
`Mode 5 170CH`). All tests ran on a scratch copy (`FixtureType 25`) inside the editable patch
(`Root 14.10`, exists only while the Patch menu is open). The scratch copy was deleted afterwards;
the real type and the 24 fixtures were never changed. Backup before: `Christmas 2026_mcp_1105_2119`.

## The rule MA applies (measured, not documented)
`DMXMode.XYZ` goes true only when, for the mode's pan/tilt:
1. Pan sits on the OUTER axis geometry and Tilt on the INNER one, and
2. the tilt axis geometry has NO rotation relative to the pan axis geometry, including any plain
   geometry in between (every one of ROTX/ROTY/ROTZ = 0 on both).
The pan axis geometry itself MAY be rotated (ROTY 90 was accepted). `XYZPOSSIBLE` reads true on
every mode of every type and means nothing. `CANHAVECHILDREN` does not matter. A refused set reads
back false with no error. `FixtureType n` only resolves to the editable copy while Patch is open;
on the live patch every fixture-type write is silently ignored.

## Test log (scratch copy, unused `Mode 1 41CH`, cut down to one head)
| State | XYZ |
| --- | --- |
| original (Tilt on Yoke, Pan on Head, 5 heads) | refused |
| relabelled Pan on Yoke / Tilt on Head, 5 heads, used mode 5 | refused |
| one head, original labels | refused |
| one head, relabelled | refused |
| + CANHAVECHILDREN false | refused |
| + Array1 ROTZ 0 (Head still ROTX -90 ROTZ -90) | refused |
| + Head 1 rotation 0 | ACCEPTED |
| Yoke 1 ROTY 90, Head 0 | accepted |
| Head ROTZ 90, or ROTX -90, or ROTY 90, or ROTZ -90 (each alone) | refused |
| Head 0, Array1 ROTZ 90 | refused |
Control: Rogue R2 Spot unused `18 Channel` mode accepted XYZ straight away (then set back).
Not yet tested: whether five pan/tilt pairs in one fixture are accepted once each is square.

## How the Tornado is built
Per head: `Yoke n` (Axis, rot 0, Tilt, turns about the bar's long axis X) > `Array n` (plain,
ROTZ 90) > `Head n` (Axis, ROTX -90 ROTZ -90, Pan, physical +29.5..-29.5, turns about base Y) >
beam/LED children (ROTX 90). With MA composing rotations as Rz*Ry*Rx the chain is the identity:
beams point straight down at rest. Mode 5 uses the `Bsae2 170CH` tree (`Geometry 4`): yokes 6-10,
children are GeometryReferences (8 LED + 1 Beam per head).

## What a real fix needs (not built)
A new fixture type, same DMX, described the way MA wants it:
- `Yoke n`: Pan, rotated so its local Z lies along the bar: ROTX 90, ROTZ 90 (frame x=baseY,
  y=baseZ, z=baseX). Its mesh will look turned unless the model moves to a child geometry.
- `Array n`: rotation 0. `Head n`: Tilt, rotation 0, position (0, -0.065, 0).
- every child of `Head n` (45 in mode 5): new rot = F^T * Rx(-90) * old rot, new pos likewise,
  F = [[0,0,1],[1,0,0],[0,1,0]]. For the plain beam that is ROTX -90 ROTY -90, pos (0,-0.04,0).
- relabel the ten channels (proven to work: LogicalChannel.ATTRIBUTE, ChannelFunction.ATTRIBUTE
  and NAME take the strings "Pan"/"Tilt").
- unknowns: sign of each axis versus the real fixture (needs Aaron's eyes on 3D against a real
  Tornado), setting three angles one at a time near gimbal lock (set ROTY last, read back), and
  point 'not yet tested' above. `TYPE` on a geometry is read-only (no retyping Axis <-> Geometry).
- cost for the show: on that type Pan and Tilt swap meaning (big move = Pan, the +/-29.5 swing =
  Tilt), so Tornado position presets, cues and effects must be rebuilt; groups should survive if
  the 24 fixtures keep their IDs and only their type is switched (to be checked on one first).
Scripts: `relabel.py` (the relabel + XYZ try on the scratch copy).

# Second session, same day: the build attempt (Aaron: "Lets give it a shot")

Groups recorded first (local only, not committed): `groups-before/group-600|602|603|605|606|607.xml` (exports) and
`groups-before/all-groups.json` (every group's members by sub-fixture index). Groups store items as
ID paths (`1101.2`, `1101.2.1.9` ...) with grid positions, so they survive as long as the fixture
IDs and the sub-fixture tree stay the same.

## The complete rule set for `DMXMode.XYZ` (measured on 2.5.1.1)
1. Pan on the outer Axis geometry, Tilt on the inner one.
2. The tilt axis has zero rotation relative to the pan axis, including any plain geometry between.
3. The tilt axis origin lies ON the pan axis: its offset in the pan frame is along local Z only
   (X = Y = 0). A sideways offset of 4.8 cm was refused; (0, 0, z) and (0, 0, 0) were accepted.
4. The pan axis geometry itself may be rotated and offset freely.
5. Five pan/tilt pairs in one fixture ARE accepted, BUT MA creates the virtual XYZ channels
   (`PanTiltDistance`, `XYZ_X/Y/Z`, `XYZ_Flip`, `XYZ_MArker`) for ONE pair only: the last (`Yoke 10`).
   Copying those channels to another yoke made MA drop all of them and clear the flag, and the
   mode then refused XYZ for the rest of that copy's life (cause not found).
So on this software a Tornado bar as one fixture can have XYZ on one head at most.

## What did work (all on a scratch copy, deleted again)
- MA's rotation convention: M = Rz * Ry * Rx, right-handed. Proven two ways: how it re-normalises
  angles at ROTY = +/-90, and the profile's own LED ring (right-handed: all 8 LEDs + beam face the
  same way, stepping 45 degrees; left-handed: LED 4 and 8 flip). Maths in `geomath.py`.
- The faithful re-description (`build.py`, `meshes.py`, `relabel.py`): yoke = Pan with ROTX 90,
  ROTZ 90 and its origin dropped to the head pivot; array and head rotation 0, head offset 0; each of
  the 45 head children re-posed with K = F^T * A_old * H_old; yoke/head models moved to plain child
  parts (`Yoke body n`, `Head body n`) with compensating poses. `build.py verify` compared every
  child's world orientation and position before/after: 0 differences, and XYZ read true.
- Property setters that take strings: `ATTRIBUTE` ("Pan"), `MODEL` (model name, "" clears),
  `GEOMETRY` (dotted NAME PATH from the tree root: "Bsae2 170CH.BEAM Array.Yoke 6.Array 6.Head 6").
  HAZARD: an unknown GEOMETRY string silently links the channel to the FIRST top-level geometry.
  `TYPE` on a geometry is read-only. `Copy <Root path> At <Root path>` copies geometries and DMX
  channels inside the edit copy; `Delete FixtureType n[.path]` works there too.

## Options now (Aaron decides)
- Leave the Tornados without XYZ.
- Split each bar into five single-head fixtures plus one bar fixture (two new fixture types, a full
  re-patch of the 24 bars to 144 fixtures, groups/layouts/presets rebuilt, bar master dimmers no
  longer tied to the heads inside one fixture). Every head then has its own single pan/tilt pair,
  which is the case MA supports. Not started.
