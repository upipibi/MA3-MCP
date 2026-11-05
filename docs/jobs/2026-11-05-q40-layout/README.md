# Q40 block in Layout 1 (2026-11-05)

Aaron: "can you build the q40 layout into layout 1, from my old show file into this one".

Old show (Christmas 2025, export kept from the Portman job): 55 Q40 elements = 11 panels x (master
+ 4 instances), all 50 x 50; each panel is a master tile centred over a 2 x 2 (Instance2 top-left,
3 top-right, 4 bottom-left, 5 bottom-right); panels in rows of 2 / 3 / 6 inside a 750 x 510 `Q40` box.

Today: 11 panels, `Fixture 801-811` under grouping 800, 4 instances each, hanging in three lines by
patch position: upstage (Y 5.6) 801, 811, 806; next (Y 4.9) 802, 808, 809, 810; downstage (Y -0.1)
807, 803, 804, 805. That is 3 / 4 / 4, so last year's 2 / 3 / 6 picture cannot be copied panel for
panel. By then Aaron had tiled the default layout area with boxes; the one free slot was
x 180..960, y -270..60, between his `R1` and `Key` boxes.

Built (`q40.py`, `q40-plan.json`, `q40-preview.png`): the old look at 30 x 30 so three rows fit the
slot; rows from today's rig with the upstage line on top (the layout is a plan view: key light at
the bottom); left-right from POSX at 48 px per metre (layout left = negative X, checked against the
key lights he ordered left to right); a `Q40` label box styled like his `R1` box filling the slot.
Elements `Layout 1.1470-1524` (55) and the box `1525`.

Run: backup `Christmas 2026_mcp_1105_2341`; 55 assigns, then sizes, positions and the box in one
undo group `q40-layout`; verified from a fresh export: 55 of 55 match, no existing element moved
(120 yoke cells only lost their editor "Selected" flag). The job did not save the show.

My calls, told to Aaron: today's rig arrangement instead of last year's pyramid; 30 x 30 instead
of 50 x 50; upstage on top.

## Second pass, same evening: default size

Aaron: "oh man, those are small, any way we could make them the default size? We have lots of
empty space". Three rows of master-over-2x2 at 50 x 50 need 450 of height and the slot has 330, so
each master moved to the LEFT of its 2 x 2, centred on its height (a panel is 150 x 100); rows and
left-right order unchanged (43.5 px per metre); the box label is left-aligned so it clears the
middle panel of the top row (`q40_default_size.py`, `q40-plan-v2.json`, `q40-preview-v2.png`).
Backup `Christmas 2026_mcp_1105_2344`; undo group `q40-default-size`; verified from a fresh export:
55 of 55 match, nothing else moved. The job did not save the show.
