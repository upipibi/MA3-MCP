# Stick delivery, 2026-11-05: job record

Written during the session as a running log, kept as it was (it mixes the plan for each item with
its result; the line in each heading is the outcome). All four items are done and verified on the
console. Left over at the end of the day: one console restart with the stick out to prove both
plugins survive it.

The layout exports (`layout1-*`) and Aaron's Capture screenshot (`capture-portman-plot.png`) named
below are local only: raw show data is not committed to this public repo.

Left over: restart the console once with the stick out to prove both plugins survive; the stage
`Selectable 3D` question (offered, not asked); the PIN-changed-by-itself bug (Open items); commit
both projects (`/save` here and in `../MA3 Cue Display/`); Cue Display version bump is Aaron's call.

Aaron's words: "I want the updated plugin for MCP, the cue display plugin, the model, and the layout
complete." He asked to compact first; nothing below is started except where marked DONE. Job folder:
`docs/jobs/2026-11-05-stick-delivery/` (his Capture screenshot + two MVR inspection scripts).
2026-11-05 after the compact: the files for items 1-3 are ON THE STICK (md5 verified). What remains
for each is Aaron's console step and my verification after it.
The console ran plugin alpha.2, show `Christmas 2026`, backup
`Christmas 2026_mcp_1105_1615` taken today. All repo work since 2026-11-03 is uncommitted (`/save`).

## 1. MA3 MCP plugin 0.2.0-alpha.3 (DONE on the console 2026-11-05, restart proof pending)
- VERIFIED after Aaron's GUI import: `ma3_status` 0.2.0-alpha.3; `Plugin 36.1` reads `INSTREAM=true`,
  `ISRESOURCE=false`, `FULLPATH=<Showfile>` with no manual step; show saved with `ma3_save`. Only the
  restart with the stick out is still unproven. The plain `<Plugin>` + bare `ComponentLua` form is
  the proven one. The Cue Display attributes (`Installed="Yes" LoadOnDemand="Yes"`) are NOT a
  fallback: that plugin imported as a resource (see item 2).
- Why: the plugin would not start after a console restart. Root cause was our XML using MA's
  resource-plugin form (`UserPlugin` + `Path`); alpha.3 ships a plain `<Plugin>` XML like Cue Display.
- Do: `cp "dist/MA3 MCP.lua" "dist/MA3 MCP.xml" /Volumes/MA3/grandMA3/gma3_library/datapools/plugins/`,
  verify md5. Aaron deletes Plugin 36, imports through the GUI, starts it; `/mcp` reconnect here.
- Verify: `ma3_status` = 0.2.0-alpha.3; `ma3_object "Plugin <n>.1"` should show `ISRESOURCE=false`;
  if `INSTREAM` is not true, `ma3_set` it (or Aaron sets InStream in the plugin editor); `ma3_save`.
  Real proof = next console restart with the stick out. If the new XML form fails to import, fall
  back to the Cue Display attributes (`Installed="Yes" LoadOnDemand="Yes"`), which are proven there.

## 2. Cue Display plugin (DONE 2026-11-05: re-imported as Plugin 38, verified on the console)
- VERIFIED: `Plugin 38.1` reads `SYNTAXERROR=false`, `INSTREAM=true`, `ISRESOURCE=false`,
  `FULLPATH=<Showfile>`; its `/health` page on port 8090 answers `ok 2.0.0` and `/api/state` returns
  JSON. Show saved with `ma3_save` after Aaron confirmed Layout 1. No `Cue Display` macro seen yet.
  The steps below are history.
- Done in `../MA3 Cue Display/` (uncommitted, version left at 2.0.0, noted in its CLAUDE.md under
  Out-of-session changes): `src/server.lua` no longer assigns to the loop variable, XML template in
  our proven form, tests and build run on Lua 5.5 then 5.4 (68 pass on both, `luac5.5 -p` clean).
- Remaining: stick into this Mac, copy `../MA3 Cue Display/dist/MA3CueDisplay.lua` + `.xml` to
  `/Volumes/MA3/grandMA3/gma3_library/datapools/plugins/`; Aaron deletes Plugin 38 and re-imports;
  verify `Plugin <n>.1` reads `SYNTAXERROR=false`, `INSTREAM=true`; then the macro `Cue Display`.
- Background (the diagnosis):
- Read 2026-11-05: `Plugin 38.1` has `SYNTAXERROR=true`, `ISRESOURCE=true`, `INSTREAM=false`,
  `FULLPATH=.../shared/resource/lib_plugins/MA3CueDisplay.lua`, `FILEEXISTS=false`. Two causes:
  (a) `luac5.5 -p` on its dist file fails at line 281, `line, _, partial = entry.sock:receive("*l")`
  inside `for _, entry in ipairs(...)`: Lua 5.5 makes loop variables const (source: `src/server.lua`,
  `read_pass`); (b) its XML form makes the console treat it as a resource plugin, so it is not in
  the showfile. Fix = rename that `_`, ship the XML in our proven form, rebuild, back onto the stick.
  That project is Aaron's and off limits until he says yes (asked 2026-11-05).
- Source: `../MA3 Cue Display/dist/MA3CueDisplay.xml` + `MA3CueDisplay.lua` (Aaron's own plugin,
  v2.0.0.0; its README step 4: set InStream so it lives in the showfile). Copy both to the same
  plugins folder on the stick. Do not modify that project. Tell Aaron the README's install steps.

## 3. Stage model (MVR), empty layers stripped (IMPORTED by Aaron 2026-11-05)
- Result on the console: grouping `Fixture 100002 Stage` with 43 children (42 `GroupObject` + 1
  `SceneObject`, 85 scene objects in all), patch 17 top-level entries, 33 fixture types (new:
  `SceneObject`, plus one more duplicate each of Fuze Profile Follow and ERA 600 Performance).
- Aaron asked how to make the stage unselectable in 3D: every fixture has `SELECTABLE3D` (patch
  column "Selectable 3D"), true on the Stage objects today. Offered to set it; not asked yet.
  Unverified: whether it can be written outside the Patch menu and whether a parent row cascades.
- DONE: `Stage - MA3.mvr` written by `docs/jobs/2026-11-05-stick-delivery/strip_layers.py`: 52 empty
  layers dropped, 2 kept, 85 scene objects unchanged, the 15 `.3ds` files byte-identical, archive
  stored uncompressed like Capture's original. Saved next to the original in OneDrive and on the stick.
- Source: `Stage.mvr` in Aaron's Capture project folder (`Christmas 2026/MVR/`, OneDrive) (71 KB, exported 2026-11-05 10:38). MVR 1.4 zip:
  `GeneralSceneDescription.xml` + 15 small `.3ds`. No fixtures. 54 layers, only two hold objects:
  `Portable Stage` (84 SceneObjects in 42 GroupObjects) and `Worship Center - Stage and Backstage` (1).
  Origins span x -12.2..11.0 m, y -6.1..0, z -1.2..0.
- Do: write a new zip with the same files and the XML minus the 52 empty `<Layer>` elements (keep
  byte-for-byte everything else, keep the UTF-8 declaration); re-run `inspect_mvr.py` on the result;
  save as `Stage - MA3.mvr` next to the original AND copy to `/Volumes/MA3/grandMA3/gma3_library/mvr/`.
  Work in a fresh scratch folder; run Python with `-I`.
- Aaron imports: save the show under a new name first (PSR cannot be Oopsed, clears the programmer,
  console standalone/idle master); Menu > Show Creator > Partial Show Read > MVR; keep Group Objects
  ticked, tick Scene Objects; Finish > OK. Before: patch has 16 top-level entries, 30 fixture types
  (`ma3_fixtures {summary:true}`); compare after. Model arrives grey (Capture MVR has no materials).

## 4. Portman layout in Layout 1 (DONE 2026-11-05, verified; show not saved by the job)
- Results at the bottom of the plan file below. `ma3_commands` is now proven on the console.
- Plan: `docs/jobs/2026-11-05-stick-delivery/portman-layout-plan.md` (+ `portman-plan.json`,
  `portman-plan-preview.png`, `plan_portmans.py`). Old show read: `Christmas 2025 (no audio)`, saved as
  `layout1-OLD-christmas-2025.*`. Old 1405/1403/1401 (left column top to bottom) -> 1201/1202/1203;
  1406/1404/1402 -> 1204/1205/1206; block shifted +250 in x. Live Layout 1 now has 227 elements
  (Aaron added nine Eras; re-export in `layout1-export-2.xml`). The bullets below are the background.
- Ask: "layout the Portmans in Layout 1 ... match the layout in Capture. Look at the old showfiles to
  see how I did it in the past."
- Capture reference (`capture-portman-plot.png`): two vertical truss towers, far stage-left and far
  stage-right, each with three Portman P1 hex fixtures stacked top to bottom. Patch labels visible:
  left tower 3.1, 3.44, 3.87; right tower 3.130, 3.173, 3.216 (universe 3, 43 channels apart). A row
  of four moving heads runs across the top between the towers (4.24, 4.65, 4.129, 4.170).
- Aaron, 2026-11-05: "The current layout doesn't have the Portmans, the older shows do. And the older
  shows will show you how I want the Portmans laid out." So the reference is an OLD show's Layout 1,
  not the current one. Old show files are binary; the only way to read one is on the console (or
  onPC) with the plugin running: Aaron loads the old show (Christmas 2025 is the best candidate: its
  Layout 1 `Portmans` plus groups 400 `Portman Dimmer` 42 cells, 403 `Portman Color` 42, 404 `Left ->
  Right#2`, 406 `]`, 407 `X`), imports the plugin, then `ma3_export {address:"Layout 1"}` and save
  the file into the job folder as `layout1-OLD-<show>.json`. Also read that show's Portman fixtures
  (`ma3_fixtures {type:"P1"}`) to map old fixture IDs to today's. Then Aaron reloads Christmas 2026.
- Read from the CURRENT show 2026-11-05 (saved as `layout1-export.json` / `.xml` in the job folder):
  Layout 1 `Portmans`, 218 elements, no Portmans in it. Canvas 1920x1080, LayoutType Grid, elements
  are `<Element Object="ShowData.LivePatch.Stages.Auditorium.Fixtures.<grouping>.<fixture>[.<instance>]"
  Action="SelectFixtures" PosX PosY Width Height FixtureID=... IDType="0" Appearance="<Fixture>">`.
  Present: 4 Infinibars as 2 columns x 24 cells each (cells 20x30, x -951..-772, y 467 down to -292,
  33 apart), 2 dimmers + a `Dimmers` group box (x 400..830, y -540..-350), a `Q40` group box (x
  -2030, y -680, 600x1280), 8 Fuze Profiles 50x50 on y -450..-350 (x -250..290), 6 Fuze Washes 50x50
  on y -530, plus text/box elements (`Era`, `Key`, `Q`). Overall x -2030..1370, y -680..550.
- Today's Portmans: grouping fixture 1200 `Portmans `, fixtures 1201-1206 (`P1Min PF 2`..`PF 7`), type
  `## P1 Mini`, mode `5 Standard`, 14 instances each (`1201.1`..`1201.14`, named `[Instance2]`..
  `[Instance15]`), patched 3.001, 3.044, 3.087, 3.130, 3.173, 3.216. Per the Capture screenshot:
  left tower top to bottom = 1201, 1202, 1203; right tower = 1204, 1205, 1206. Group 400 `Portman
  Dimmer ` now holds just the 6 fixtures; 402 `Color Master` and 403 `Color Sections` are empty.
- Then: translate the old layout's Portman element positions and sizes onto fixtures 1201-1206 (and
  their instances), choose free space in today's Layout 1 (or keep the old coordinates if free), show
  Aaron the plan, wait for go, `ma3_backup`, send with `ma3_commands` in one undo group, verify by
  re-export. Layout syntax, checked 2026-11-05: the manual gives `Assign Fixture <id> At Layout 1` to add an
  element (no command places it); the element object (`Layout 1.<n>`, class Element) has writable
  POSX, POSY, WIDTH, HEIGHT (Int16; negative values read back unsigned, 64596 = -940), so position
  goes through `ma3_set`. Unproven on the console: try one element first after the go; importing a prepared layout XML is the
  alternative route if commands prove awkward.

## Facts learned 2026-11-05 worth keeping
- Fuze Profile order stage left to right: 1812, 1813, 1816, 1818, 1815, 1814, 1817, 1811; all on
  universe 31 (1818 at 31.414). In `docs/CONVENTIONS.md`.
- A plugin cannot be a dockable window (85 fixed window types); Aaron was only curious.
- The Capture MA-Net3 bridge is the sibling project `../ma-net3-bridge/`, not this one.
- Aaron already keeps per-rig MVR exports in the Capture `Christmas 2026/MVR/` folder (Band, Electric
  2-5, Pars, R2s, Tornados, Stage), so he has done MVR imports before.
