# Tornado ring sections in Layout 1 (2026-11-05)

Aaron: "I dropped in the tornado rings, then all their sections in layout 1, but the ring sections
are one massive line. Can you organize each section to that like ring 'masters' that I added,
similar to how the portmans are organized. I need to be VERY dense. I want the rings ... to stay the
same size ... The ring I might tap on, the ring section I won't, it's just a visual."

Before: 24 ring masters (`<fid>.1` = `[LED Array]`, 50 x 50) in two rows of 12 (1113-1124 on top at
y 1180, 1101-1112 below at y 1113, x -350..200), and 960 section elements (`<fid>.2.<head>.<led>`,
5 heads x 8 LEDs per bar, 50 x 50) overlapping in one line at y 852 from x -7000 to 6476.

After (`rings.py`, plan in `rings-plan.json`, picture in `rings-preview.png`): masters untouched.
Each head is a hollow 3 x 3 ring of 10 x 10 cells (LED 1 top-left, then clockwise; the profile's
geometry confirms LEDs 1-8 run in order around the ring, the start point and direction are my
choice). A bar's five rings stack in a 30 x 150 column centred on its master, head 1 on top: below
the master for the lower row, above it for the upper row. Section cells have object name and bar
hidden, so they show colour only. Footprint x -340..240, y 963..1380; nothing else overlaps.

Run: backup `Christmas 2026_mcp_1105_2227`; 1,926 commands in one undo group
`tornado-rings-layout` (5.8 s); verified from a fresh export: 960 of 960 match the plan, no other
element changed. New syntax proven: `Set Layout 1.<a> Thru <b> Property "Width" 10` works on a
range of layout elements. The exports (`layout1-before.xml`, `layout1-after.xml`) are local only.
