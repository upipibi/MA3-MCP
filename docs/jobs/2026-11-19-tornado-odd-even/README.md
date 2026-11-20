# Groups 608 / 609: every other Tornado yoke (2026-11-19)

Aaron wanted the odd yokes of the Tornado rows to chase on their own and the even ones on their own
(tilt phaser, opposite directions). MAtricks `XGroup 2` does not do it: a `0 Thru 360` range then
repeats every two fixtures instead of spreading over each half ("xgroup doesnt work, I cant apply
0 - 360 with that"). His alternative: "select every other from the yokes section group, and create
two groups".

Source: Group 606 `Yoke Sections`, 120 yokes (`Fixture <bar>.2.<head>`) in one grid line x 0..119 in
his own order (heads 5 to 1 inside a bar; the first 60 are bars 1101-1111 and 1121, the second 60 are
1112-1120 and 1122-1124).

Built (`plan.py`, `plan.json`): **Group 608 `Yoke Sections Odd`** = positions 1, 3, 5 ... of that
line, **Group 609 `Yoke Sections Even`** = positions 2, 4, 6 ...; 60 yokes each. Grid: two rows of 30,
row 0 = the first 60 of his line, row 1 = the second 60, same left-to-right order, so a phase range
along X gives each Tornado row its own full chase.

Run: backup `Christmas 2026_mcp_1120_0229`; `Reset Selection 1 MAtricks` (so a left-over XGroup is not
stored into the groups; returned OK, first use on the console), then 246 commands (`ClearSelection`,
`Grid x/y` + `Fixture <id>` per yoke, `Store Group`) in undo group `tornado-odd-even`, closed. Verified
from a fresh read: both groups match the plan (60 members, every grid position), groups 600-607
unchanged. The job cleared Aaron's selection and reset his MAtricks; it did not save the show.

Use: Group 608, tilt phaser, `At Phase 0 Thru 360`; Group 609, same phaser, `At Phase 360 Thru 0`.
Not yet seen on the rig: that the range runs along X in both grid rows at once (MA help); if it runs
through all 60 as one line instead, flatten the grids to one row.

Syntax proven on 2.5.1.1: `Grid <x>/<y>` then `Fixture <id>` places one sub-fixture at that grid
cell and adds it to the selection; `Reset Selection 1 MAtricks`.
