# Group 706 `Ladder LEDs` (2026-11-05)

Aaron: "can you organize all the individual ladder LEDs into one group, and save it to group 706".

The ladders are 12 grouping fixtures (`Ladder 1`..`Ladder 12`, FIDs 20001, 20052, ... step 51) under
`Fixture 20000 Christmas Lights`, each holding 50 `LED - RGB` fixtures (FID grouping + 1..50). A 13th
grouping, `Test` (50 LEDs, the only ones patched today), is not a ladder and was left out; it does
sit inside Group 811 `Ladder 1` (100 members) alongside ladder 1's own 50.

Built: Group 706 `Ladder LEDs`, 600 members, selection grid 50 x 12: x = LED along the ladder
(0..49, the same direction as his `Ladder n` groups), y = ladder (0 = Ladder 1 .. 11 = Ladder 12).
Backup `Christmas 2026_mcp_1105_2334`; 27 commands in undo group `group-706-ladder-leds`; read back:
600 members, 50 on each of 12 rows. The job did not save the show.

Number: 706 is what he asked for. It is in the 700 hundred (now Portman: 700 `Portman Filaments`,
702, 703); the ladder groups are 811-822 and 806 was also free. Asked; he confirmed: "yes, 706 is
what I wanted". Do not move it. He also confirmed leaving the `Test` set out ("LEDs good").

Syntax proven on 2.5.1.1: `ClearSelection`, then per row `Grid 0/<row>` followed by
`Fixture <a> Thru <b>` (the selection fills the row from the grid cursor along X), then
`Store Group <n> "<name>"`. The selection is the operator's own: this clears it before and after.
