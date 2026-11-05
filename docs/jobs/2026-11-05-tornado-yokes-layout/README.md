# Tornado yoke sections in Layout 1 (2026-11-05)

Aaron: "can you do the same with the yoke and yoke section. I've added them to the layout, using
those yoke and yoke section groups." (Same day as `../2026-11-05-tornado-rings-layout/`.)

Before: 24 yoke masters (`<fid>.2` = `[BEAM Array]`, 50 x 50) in two rows only 70 apart (1113-1124
at y 1020, 1101-1112 at y 950) and 120 yoke sections (`<fid>.2.<head>`, 50 x 50) in one line at
y 781. Meanwhile Aaron had re-spaced the ring block himself: both ring rows 200 apart with every
column hanging BELOW its master, head 1 nearest the master. That is the arrangement copied here.

After (`yokes.py`, `yokes-plan.json`, `yokes-preview.png`): the upper row of yoke masters moved up
130 so the rows are 200 apart (x and size untouched; this is the one place a placed element was
moved, because the columns do not fit otherwise). Each yoke section is one 30 x 30 cell, the
footprint of one ring, five in a column centred under its master, head 1 on top, object name and
bar hidden. Footprint x -205..400, y 800..1200; nothing else overlaps.

Run: backup `Christmas 2026_mcp_1105_2235`; 256 commands in one undo group `tornado-yokes-layout`;
verified from a fresh export: 120 of 120 sections and 12 of 12 moved masters match the plan, no
other element changed. The job did not save the show. Exports are local only (and in OneDrive).
