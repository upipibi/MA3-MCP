# Portman layout in Layout 1: plan (2026-11-05)

Status: DONE 2026-11-05 on `Christmas 2026`. Results at the bottom.

## What Aaron asked
"Layout the Portmans in Layout 1. I want it to match the layout in Capture. Look at the old
showfiles to see how I did it in the past." The current Layout 1 has no Portmans; the old shows do.

## What the old show does (Christmas 2025 (no audio), Layout 1 `Portmans`)
Read with `ma3_export`, saved as `layout1-OLD-christmas-2025.json` / `.xml`.
- 90 Portman elements: 6 fixtures x (1 master tile + 14 instance cells), all 50 x 50, Action
  SelectFixtures, object name and bar visible, border hidden.
- Each Portman is two 7-cell hexes side by side: instances 1-7 form the left hex, 8-14 the right hex.
  Cell offsets from the hex centre column (x, y): top (0, +30), upper right (+50, 0), lower right
  (+50, -50), bottom (0, -70), lower left (-50, -50), upper left (-50, 0), centre (0, -20).
  The two hexes are 150 apart; the master tile sits centred above them (+80 x, +70 y from hex one).
- Six Portmans in two columns x three rows, rows 200 apart, columns 350 apart, inside a text box
  `Portmans` 750 x 610.
- Layout Y points up (master tiles sit above their cells in every family).

## What goes into today's Layout 1
Same pattern, same sizes, same spacing. Mapping by the Capture plot (`capture-portman-plot.png`):

| Position | Old fixture | Today |
| --- | --- | --- |
| left column, top | 1405 | 1201 (3.001) |
| left column, middle | 1403 | 1202 (3.044) |
| left column, bottom | 1401 | 1203 (3.087) |
| right column, top | 1406 | 1204 (3.130) |
| right column, middle | 1404 | 1205 (3.173) |
| right column, bottom | 1402 | 1206 (3.216) |

Left column = stage-left tower top to bottom, right column = stage-right tower top to bottom.
Placement: the old coordinates are now under the Infinibars (x -951..-752), so the whole block moves
250 to the right: cells span x -650..0, y -70..520; text box `Portmans` at x -700, y -70, 750 x 610.
Checked against the live layout re-exported after Aaron reloaded the show (227 elements, including
the nine Eras he added today): no overlap with anything. Preview: `portman-plan-preview.png`.
Every element's exact fixture, x, y, width and height is in `portman-plan.json` (built by
`plan_portmans.py`).

## Execution (after the go)
1. `ma3_backup`.
2. One element first, to prove the unverified syntax: `Assign Fixture 1201 At Layout 1`, read back the
   new element (expected `Layout 1.228`), set PosX/PosY, read back. Position goes by command
   (`Set Layout 1.<n> Property "PosX" <v>`) if the console takes negative numbers there, else by
   `ma3_set` (not part of the undo group; the report will say which).
3. The other 89: `Assign Fixture <id> At Layout 1` in plan order through `ma3_commands`, undo group
   `portman-layout`; read back element numbers; then PosX/PosY (Width/Height only where the console
   default is not 50) in batches of up to 200.
4. The `Portmans` text box: try to add it as an empty element with CustomTextText, border visible,
   750 x 610. If the console refuses, skip it and report; the 90 fixture elements do not depend on it.
5. `ma3_undo_close`. Re-export Layout 1 and compare every Portman element with `portman-plan.json`.
6. Report: counts, anything that did not match, backup name, how to revert.

Not touched: every existing element, every other layout, groups, presets.

## Results (2026-11-05)
- Aaron: "use the mcp for the portman layout". The session's own connector still held the old PIN
  (the PIN changed by itself on the show reload), so the same MCP tools were called over the plugin's
  endpoint with `tools/mcp_call.py`, which reads the saved PIN from Claude Code's config.
- Backup: `Christmas 2026_mcp_1105_1733`.
- Added `Layout 1.228` to `Layout 1.317`: the 90 Portman elements, each verified against
  `portman-plan.json` (fixture, x, y, 50 x 50) from a fresh export (`layout1-AFTER.xml`).
- Added `Layout 1.318`: text box `Portmans`, x -700, y -70, 750 x 610, border visible, text top,
  padding 2, object name hidden, like today's `Key` box.
- Undo: group `portman-layout` holds 283 commands (90 assigns, 180 positions, the box and its
  properties); a second one-command group `portman-layout-box-name` hides the box's object name.
  Two Oops revert everything.
- Syntax now proven on 2.5.1.1: `Assign Fixture <id or id.instance> At Layout 1` appends an element
  (50 x 50 at -25, -25, name and bar visible, border hidden); `Store Layout 1.<n>` creates an empty
  1 x 1 element; `Set Layout 1.<n> Property "PosX" -520` takes negative numbers; visibility
  properties take "Hidden"/"Visible" ("No" is an illegal value). 89 assigns ran in 257 ms and 180
  sets in 289 ms through `ma3_commands` (its first real use on the console).
- Not mine: 14 key-light elements (1811-1818, 1821-1826) moved between the pre-job export and the
  final one. Aaron was rearranging them in the Key box while the job ran.
- The show was not saved by the job.
