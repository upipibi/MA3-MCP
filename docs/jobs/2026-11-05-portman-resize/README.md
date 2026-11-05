# Portmans resized to fit the default layout area (2026-11-05)

Aaron: "I've reorganized the portmans to better align with how they are in real life. Can you make
them all a bit smaller, to fit in the default layout size."

Before: he had re-arranged the 90 Portman elements himself (two columns of three fixtures; each
fixture is its master with its two hexes stacked below it), all 50 x 50, spanning x -110..200,
y -630..500. The default layout area is the 1920 x 1080 canvas centred on the origin (x -960..960,
y -540..540), so the block ran 90 below the bottom edge.

After (`resize.py`, `resize-plan.json`, `resize-preview.png`): every Portman element scaled to 0.9
about the block's top-left corner, so cells are 45 x 45 and the spacing shrinks by the same ratio;
the top-left corner stays where he put it. Block now x -110..169, y -517..500, inside the default
area, no overlaps. His arrangement is otherwise unchanged.

Run: backup `Christmas 2026_mcp_1105_2257`; 360 commands in one undo group `portman-resize`;
verified from a fresh export: 90 of 90 match, nothing else changed. The job did not save the show.
Left alone, not asked: the old `Portmans` label box (element 318) still sits at x 750..1500, partly
outside the default area, and the Era / Key / Dimmers blocks are parked below it (y -1710..-1050).
