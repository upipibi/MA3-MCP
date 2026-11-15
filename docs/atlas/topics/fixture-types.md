# Fixture types: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Fixture Types", 13 pages), MA's fixture-type tests
(edit, delete, exchange, import/export), the release notes 2.2 to 2.5, and our Tornado XYZ work
(`docs/jobs/2026-11-05-tornado-xyz/FINDINGS.md`: MA's rules for XYZ on a DMX mode, and why the
five-head Tornado bar cannot have it). Study pack: `python3 tools/atlas/pack.py "Fixture Types"
--terms fixturetype,ft,gdtf,dmxmode,wheel`. Patch context: [patch.md](patch.md); curves:
[dmx-curves.md](dmx-curves.md).

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What a fixture type is [D]

- The footprint of a device: modes, channels, physical properties (wheels, emitters, filters,
  geometries, models). Sources: the grandMA3 library, converted grandMA2 library, MA Fixture Share,
  GDTF Share (with a World Server connection), the built-in builder, the GDTF Builder.
- Live in `Root 14.9.6` (`ShowData > LivePatch > FixtureTypes`); editable only in the Patch menu's copy
  (`Root 14.10.6`); writes to the live one are ignored silently [C].
- Structure [C, M]: `FixtureType > DMXModes > <mode> > DMXChannels > <channel> > <LogicalChannel> >
  <ChannelFunction>`; also `Wheels`, `PhysicalDescriptions` (Emitters, Filters, ...), `Models`,
  `Geometries`, `Revisions`, `Protocols`, `AttributeDefinitions`.

## The Fixture Types menu (Patch > Fixture Types) [D]

Columns: Lock, No, Name, Scribble, Note, Appearance, Color (also the split-view colour), Source
(grandMA3, grandMA2, User, Share), ShortName (patch name suggestion), LongName, Description,
Manufacturer, **Used** (fixtures using it), CanHaveChildren, **Special Purpose** (for example
Universal), **MVR Object Type**, **ShareGlobal** (identical types share global preset data; Yes by
default; not changeable in Live Patch), Version (the minimum software that can use it), **XYZ** (Yes,
Partial, No). Editor views Condensed / Full / Extended. Changes save when the patch is left with Save.

## Importing [D]

- Import button: library, user, shares; GDTF files from a stick at `grandMA3/gma3_library/fixturetypes`
  (`.gdtf` extension), cancel a long import with MA + Esc (or Shift + Esc) for five seconds.
- **Importing types exported from a higher software version may lose data.**
- Conflicts: orange font = warning (usable), red = error (hidden outside the patch); Edit > Show
  Conflicts (n) lists them.

## Building and editing [D]

- Insert New Fixture Type, then Geometries (Base > Axis Yoke > Axis Head > Beam), Models (meshes:
  .3ds, .gltf, .glb; the Meshes pool), link models to geometries, then DMX Modes > DMX Channels.
- DMX channel: Coarse / Fine / Ultra, Default, Highlight, **Master** (whether group or grand masters
  affect it); Logical Channel (attribute, snap, master, MIB fade, **DMX curve**); Channel Function
  (Physical From / To, DMX From; DMX To is computed; not editable in Live Patch).
- Sub-fixture grid positions per geometry: Grid Auto or Manual with Swap XY, Inv X/Y/Z, Grid X/Y/Z;
  per-fixture rotation and inversion of the grid live in the patch.
- Back up a built type with Export (XML) from the Fixture Types menu; save the show.
- Easier than building: copy an existing type and change the differences [D].

## Commands MA's tests use [M]

`cd FixtureType 1`, `cd DMXModes.2`, `Set DMXChannels.1.1 Property "Attribute" "Pan"`,
`Set "DMXChannels".1 Property "Default" 50` (also `Highlight`, `Coarse`, `Fine`, `Ultra`),
`Set "DMXChannels".1.1.1 Property "DMXFrom" 10` (also `PhysicalFrom`, `PhysicalTo`, `RealFade`,
`RealAcceleration`, `DMXInvert`, `EncoderInvert`, `IgnoreFollow`, `CustomName`), `Insert Type
"MediaServerLayer"`, `Delete Geometry`, `Import Lib n At 1 /NC`, `Import 1 "generic@moving_head.xml"
/Overwrite`, `Export ... /File 'x.xml' /HighPrecision`, `Assign FixtureType "x".DMXModes."Mode 0" At
...` (exchange), `Set FixtureType "x" Property "ShareGlobal" 0`, `Delete FixtureType`. All inside the
Patch menu (`Root 14.10`) for the change to stick.

## Traps (release notes and ours)

- 2.5 fixes: **deleting a fixture type could freeze the software (rare)**; exchanging many types then
  unpatching and repatching could crash; replacing a GDTF type with the same type in XML added dimmer
  values to colour presets; phaser data could be lost after changing a fixture's type; more than 1,024
  attributes could crash new channel functions (2.5.1.0) [D].
- 2.4: editing logical channels could lose their DMX curves; 1.8: save/load lost fixture-type curves [D].
- XYZ rules (pan outermost, tilt axis with zero rotation to it, tilt pivot on the pan axis; one
  pan/tilt pair per fixture) [C: Tornado findings].
- Fixture-type writes outside the Patch menu are silently ignored: always read back from the live
  patch after Aaron saves [C].

## What we have proven

- Reading all fixture types and their logical channels (`ma3_export` of `Root 14.9.6`, 2 MB in one
  call on onPC) [O, C]; editing a copy on onPC for the Tornado XYZ study [O].

## To bench on onPC

1. A full edit round trip by command in `Root 14.10.6` (attribute, default, DMX From), save, read back.
2. `Assign FixtureType ... At ...` exchange on a scratch fixture, and what happens to presets.

## Plugin access today, and gaps

- Full read [C]. Writes need the Patch menu open by Aaron and his save; there is no tool to open or
  close the patch menu (by design).
