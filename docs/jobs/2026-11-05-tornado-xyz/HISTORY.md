# Tornado XYZ: how the investigation went (2026-11-05)

Superseded by `FINDINGS.md`; kept for the reasoning trail.

- His words: "When I go to set xyz, nothing happens. Go ahead and try." Backup taken:
  `Christmas 2026_mcp_1105_2119`.
- Facts read on the console: Tornados are `FixtureType 18` `TORNADO (TB 5 IP)` (SOURCE User, 24 used,
  all in `Mode 5 170CH` = `FixtureType 18.6.5`). XYZ is a per-mode setting: the DMXMode has `XYZ`
  (false) and `XYZPOSSIBLE` (true). Era 600 (`23.6.1`) and Fuze Profile Follow (`22.6.x`) read XYZ
  true; those two types are new today (VERSION 2.5.1.1), so they may have arrived with XYZ on.
  No lock difference between the types.
- Tornado geometry: per head a `Yoke n` Axis carrying Tilt with a child `Head n` Axis carrying Pan
  (tilt outside, pan inside: the reverse of a normal moving head). In the patch each Tornado is
  `[LED Array]`, `[BEAM Array]` > `[Yoke 6..10]` > eight `[LED]` + one `[Beam]` sub-fixtures.
- My tries: `ma3_set FixtureType 18.6.5 XYZ true` read back false, no error; the command form says
  "Illegal property". Reason: `FixtureType n` resolves to `ShowData.LivePatch` (`Root 14.9`); the
  edit copy `ShowData.Patch` (`Root 14.10`) is EMPTY unless the Patch menu is open. So this did not
  reproduce his GUI failure.
- Next: Aaron opens Menu > Patch and leaves it open; then read `Root 14.10` (find FixtureTypes,
  the Tornado, mode 5), try XYZ on the UNUSED `Mode 1 41CH` first (harmless), then mode 5; read
  back; he leaves the patch with save. If the edit copy refuses too, the type itself is the
  problem: suspects are the tilt-then-pan axis order or five pan/tilt pairs in one fixture.
- RESULT with the Patch menu open (edit copy = `Root 14.10.6.<type>.6.<mode>`): the Tornado refuses
  XYZ even on its unused `Mode 1 41CH` (`ma3_set` reads back false, no error). Control: the Rogue R2
  Spot's unused `18 Channel` mode went true through the same call, then was set back to false. So
  the route works and the Tornado type itself refuses; nothing was left changed.
- Structural difference found: R2 Spot and Era 600 carry Pan on the OUTER axis (`Yoke_Main Module`)
  and Tilt on the INNER axis (`Main Module`); an XYZ-enabled mode also has a `PanTiltDistance`
  channel on the pan axis. The Tornado carries Tilt on the outer axis (`Yoke n`) and Pan on the
  inner (`Head n`), five pairs per fixture. Strongly suspected cause, not proven. `XYZPOSSIBLE`
  reads true on every mode of every type, so it is not a reliable signal.
- Options given to Aaron: leave XYZ off; or build a COPY of the Tornado type with the axes
  relabelled (outer = Pan, inner = Tilt) and test XYZ + 3D aim on it before touching the 24 patched
  fixtures (relabelling swaps what Pan/Tilt mean in existing Tornado presets and cues).
- MA manual: XYZ is set in the Fixture Type editor, XYZ cell of the DMX mode row; close editor and
  patch, save (help.malighting.com/grandMA3/2.5/HTML/xyz_activate.html).
