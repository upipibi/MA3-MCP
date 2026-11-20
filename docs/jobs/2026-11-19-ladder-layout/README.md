# Ladder LEDs in Layout 1 (2026-11-19, built the same evening)

Aaron: "Similar to how the ring LEDs are shown in the layout, I need all the 'ladder' LEDs, which
are really attached to the legs of a platform and the platform part of the platform, laid out in the
layout viewer. We are tight on space, so put some thought to what needs moved around. I'm thinking
dimmers move to make space under the infinibars and tornado?"

## What is there now (export `layout1-before.xml`, 1,525 elements, local only)

Canvas x -960..960, y -540..540, y up. No ladder LED is in the layout yet.

| Block | Area | Content |
| --- | --- | --- |
| `Infini Bars` (group element 201) | x -960..-740, y -360..540 | 196 cells of 20 x 30 |
| `Tornado` box | x -740..-120, y -360..538 | 1,128 elements |
| `Dimmers` (group element 199, 420 x 180) | x -960..-540, y -540..-360 | 14 `Stage Dimmers` tiles, 50 x 50, two rows of 7 (elements 1445-1458) |
| free | x -540..-120, y -540..-360 | 420 x 180, empty |
| `Portmans` box | x -120..180, full height | |
| `Era`, `R1`, `Q40`, `Key` boxes | x 180..960, stacked | `Key` (y -540..-270): 6 Fuze at y -530..-480, 8 Fuze Profile at y -400..-300; the band y -480..-400 is empty |

## The rig as patched (console, 2026-11-19)

13 groupings under `Fixture 20000 Christmas Lights`: `Ladder 1`..`Ladder 12` and `Ladder13`, 50
`LED - RGB` each (650), FIDs 20002-20051, 20053-20102, ... step 51; universes 5-9, three ladders per
universe (Aaron moved ladders 7 and 8 to universe 11 on 2026-11-19, and subfixture indices changed:
read the patch and groups fresh before planning). Groups 811-822 = one per ladder (822 `Ladder 12` holds 100: ladders 12 and 13). The `Test`
grouping is gone. No patch positions (every LED sits at 0 / 0 / 0.4), so the real shape cannot be
read from the show.

## First plan (afternoon; replaced by "Built" below)

- Dimmers leave the bottom-left strip, as Aaron suggested; that frees x -960..-120, y -540..-360
  (840 x 180) under `Infini Bars` and `Tornado`. New home: one row of 14 at 50 x 50 in the empty band of
  the `Key` box (x 220..920, y -470..-420), front light with front light. Nothing else moves.
- Ladder LEDs: colour-only cells like the ring sections (names hidden, not meant to be tapped), drawn
  in the platforms' real shape, with one tappable master per ladder (the grouping fixture).
- Needed from Aaron before the shapes can be drawn: how many platforms, which ladders are on which,
  how a 50-LED string runs (legs and deck), left to right on stage. A phone photo or sketch with the
  ladder numbers is enough.
- Then: plan picture, his go, `ma3_backup`, one undo group, verify from a fresh export.

## Built (22:10, `ladders.py`, plan `ladders-plan.json`, pictures `ladders-preview.png` and `-strip.png`)

Aaron asked "are you ready with that new layout with the pixels?". The arrangement did not come from
a sketch: he had built place groups in the meantime, and their selection grids carry the shape.

| Group | Members (read fresh) | Drawn as |
| --- | --- | --- |
| 701 `Front Left`, 702 `Rear Left`, 703 `Center Left`, 704 `Center Right`, 705 `Right Front`, 706 `Right Rear` | ladders 4, 5, 6, 3, 1, 2; 50 each, grid x 0..49 | six legs, each a 5 x 10 block of 9 x 9 cells, LED 1 top-left, snaking down |
| 710 `Platform Top` | 178: ladder 12 on x 88..39, ladder 13 LEDs 1-16 on x 38..23 and LEDs 28-50 on x 22..0; ladders 7 and 8 the same, on the same cells | two lines of 89 cells of 9 x 9, ladders 12/13 above ladders 7/8, grid x 0 on the left |
| 709 `Curve` | ladders 9 and 10, x 0..99 | a shallow arc of 100 cells of 8 x 8 along the bottom |
| none | ladder 11 (50), and LEDs 17-27 of ladders 13 and 8 (11 each), which `Platform Top` skips | parked in grey spots: ladder 11 as a flat 2 x 25 strip between the centre and right legs, the skipped LEDs as two small U shapes under the place where the line skips |
| 707 `Support Front`, 708 `Support Rear` | empty | not drawn |

Patch as read: ladders 7 and 8 now sit last in the fixture tree (sub-fixtures 1921-2021, universe 11);
groups 817 and 818 are empty and 822 `Ladder 12` holds 200 (ladders 12, 13, 7, 8). Group 808 `LED Crop`
holds 14 tail LEDs (ladder 1: 4, ladder 3: 6, ladder 11: 4); they are drawn with their strings.

Layout: new box `Ladder LEDs` (element 2176) on x -960..-120, y -540..-360; cells are elements
1526-2175, name and bar hidden, action left at SelectFixtures so a lasso selects them. The 14 dimmer
tiles moved to one row in the empty band of the `Key` box (x 210..910, y -470..-420), his upper row
left to right, then his lower row; the `Dimmers` box (element 199) wraps the row (710 x 60) with its
label above it.

Run: backup `Christmas 2026_mcp_1120_0407`; 2,004 commands in one undo group `ladder-layout` (4.9 s);
verified from a fresh export (`layout1-after.xml`, local only): 650 of 650 cells match the plan, the
box matches, and no other element changed except the 14 tiles and the `Dimmers` box. The show was
saved with `ma3_save` at the end of the session (`/save`). Newly proven by command on the console: `CustomTextAlignmentV "Above"`, `CustomTextAlignmentH "Left"`,
and 8 and 9 as element sizes.

My calls, told to Aaron, each one a re-run of `ladders.py` if wrong:

- A leg as a 5 x 10 snake with LED 1 at the top. A straight line of 50 needs 500 px at a visible
  cell size and the strip is 180 high. How the string really runs on a leg is not known.
- Ladders 12/13 as the rear (upper) line, 7/8 as the front line; front legs on the outside of the
  left and right pairs; the curve along the bottom, ends up.
- Where ladder 11 and the 22 skipped LEDs really are: not known, hence parked.
- No tappable master tiles: there is no room for 50 x 50 tiles in the strip. His place groups select.
