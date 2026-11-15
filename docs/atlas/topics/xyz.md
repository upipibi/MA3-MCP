# XYZ and MArker fixtures: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "XYZ", 3 pages), MA's XYZ and MArker tests, and our
Tornado XYZ study (`docs/jobs/2026-11-05-tornado-xyz/FINDINGS.md`, closed: a five-head bar cannot have
XYZ). Study pack: `python3 tools/atlas/pack.py "XYZ" --terms xyz,marker`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What it is [D]

- Programming position as X, Y, Z (stage metres or a space) instead of pan/tilt: moves travel in straight
  lines; absolute and relative; mixable with pan/tilt in one sequence. A **Distance** attribute joins
  Pan and Tilt (where relative XYZ is added when mixed with absolute pan/tilt).
- Knocking in one system while the other is active converts values; XYZ presets in the absolute layer
  knock out absolute pan/tilt (same for relative); several playbacks with both systems knock in Pan,
  Tilt, Distance. `On FeatureGroup "Position"."XYZ"`; `On EncoderPage "Position".2`.
- Ranges: absolute 0-100 % of the space, relative -100 to 100 %; physical readout in metres; Coarse
  encoder = 1 m per click.
- **Activation per fixture-type mode** (Fixture Types > Edit > XYZ = Yes); adds virtual parameters that
  do not count against the parameter limit (shown in System Info). MA's rules for which modes may have
  it (pan outermost, tilt axis at zero rotation to pan, tilt pivot on the pan axis, one pan/tilt pair
  per fixture) are in our Tornado findings [C].

## MArker fixtures [D]

- A virtual fixture (MA Lighting library) in mode **Moving** (moves its children: X, Y, Z, Rot X/Y/Z;
  needs a DMX address to show changes in 3D) or **Still** (a fixed target).
- As a target: MArker ID type with a CID; XYZ fixtures get a **MArker** attribute: set it to a MArker's
  number and they point at it; moving the MArker moves the beams.
- Target Space and Movement Space (stage spaces, default 200 m each way) bound the values.
- PSN trackers can drive moving MArkers (PSN menu: IDType, ID, DMX Priority); their universes must use
  merge mode Prio.

## What MA's tests add [M]

`Set FixtureType ... Property "XYZ" "Yes"`; `cd Root 'ShowData'.'Patch'.'Stages'`, `cd 'Spaces'`,
`Set 2 Property 'MinX' -2` (MaxX, MinY, MaxY, MinZ, MaxZ, Name); `Set n Thru m Property 'MovementSpace'
'Stage'`, `... 'TargetSpace' 'SmallTarget'`; `MArker 1`, `Attribute 'XYZ_X' At 0`.

## Plugin access today, and gaps

- Readable through fixture types and stage spaces [C]. Aaron does not use XYZ today [C].
