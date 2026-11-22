# Dimmer tiles back in two rows, between Era and R1 (2026-11-21)

Aaron, on the 2026-11-19 ladder job: the dimmers "are now mixed in other dimmers ... rather than two
rows, one of each electric, its now a straight line, which doesnt help me. Also, they are in the middle
of the key light area. I think Era and R1 could be shifted to make some space between those sections,
and we can put the dimmer there". And: "The ladder layout needs tweaked, but thats a later issue."

What I had done wrong on 2026-11-19: his 14 `Stage Dimmers` tiles were two rows (8 below, 6 above), and
I laid them out as one row of 14 in the `Key` box, his upper row followed by his lower row.

## What was sent

First job run through onPC as the `MCP` user (55 commands, undo group `dimmer-rows`, closed; the
group is in the MCP user's Oops list on onPC, not on the console). Backup `Christmas 2026_mcp_1122_0242`.
Verified from a fresh export: 33 tiles and 3 boxes where planned, no other element changed, and the
console reads the new values. `plan.json` holds every element's old and new place.

| Block | Before | After |
| --- | --- | --- |
| `Era` box (element 198) | y 300..540, rows at y 430 and 330 | y 380..540, rows at y 460 and 390 |
| `Dimmers` box (199) | one row in `Key`, x 205..915, y -475..-415, label above | x 180..960, y 220..380, label inside at the top |
| dimmer tiles (1445-1458) | one row at y -470 | his two rows again, same order and offsets as before 2026-11-19: 615 611 616 612 617 613 618 614 at y 230 (x 365..765), 619 624 620 625 621 626 at y 300 (x 425..725) |
| `R1` box (1469) | y 60..300, rows at y 200 and 100 | y 60..220, rows at y 140 and 70 |
| `Key` box | dimmer row in its middle band | as he had it before 2026-11-19 |

My calls: the three boxes share the old Era + R1 height evenly (160 each), which closes the rows of
Era and R1 from 100 apart to 70 apart (tiles are 50, so 20 between rows); x positions of his Era and
R1 tiles are untouched. Which row is which electric is not known to me: the rows are his old ones.
