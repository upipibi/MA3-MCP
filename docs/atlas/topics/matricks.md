# MAtricks and shuffle: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "MAtricks and Shuffle", 7 pages), 10 of MA's
MAtricks and shuffle tests, and Aaron's show (Shuffle 2-4 are macros 55-57 on executors 196-198 of
every weekly page; `docs/CONVENTIONS.md`). Study pack: `python3 tools/atlas/pack.py "MAtricks and
Shuffle" --terms matricks,shuffle`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What it is [D]

- A tool that divides the current selection into sub-selections along the selection grid's X, Y and
  Z axes (red, blue, green sections in the MAtricks window or the encoder bar's MAtricks pop-up).
- Per axis, three groups of properties: **Grid** (axis value X/Y/Z, Block, Group, Wings, Width),
  **Layers** (Fade, Delay, Speed and Phase From/To: ranges applied across the fixtures), **Shuffle**
  (Shuffle, Shift).
- `Next` / `Prev` step the axis value; **Set** selects everything again (MAtricks off), Set again
  turns it back on; **Active** toggles without resetting. Values by command:
  `Set Selection MAtricks "X" 6`, `Set Selection MAtricks "SpeedFromX" 10`.
- MAtricks pool (Data Pools tab): `Store MAtricks n "Name"` (long-press an empty object); recall by
  tapping. Presets and recipes can store MAtricks too.

## Grid functions (ten fixtures in a row) [D]

| Property | Effect |
| --- | --- |
| Block n | fixtures move in blocks of n (XBlock 2: 1+2, 3+4, ...) |
| Group n | interleaves into n groups (1,3,5... and 2,4,6...). **A value or phase range then repeats every n fixtures; it does not spread over each group on its own** [C: Aaron, 2026-11-19]. For two interleaved chases build two groups (`docs/jobs/2026-11-19-tornado-odd-even/`) |
| Wings n | splits into n wings stepped from opposite ends (both ends first, then inward) |
| Width n | wraps onto the next axis after n fixtures (a 5 x 4 grid from 20 fixtures); storing a group keeps it |

## Two selections, shuffle, shift, invert [D]

- Each user profile has selection 1 and 2 (`Select Selection 2`, ActiveSel); Copy Sel, Copy Values;
  `ClearAll` clears both, `ClearSelection` only the active one.
- **Shuffle** randomises the selection order per axis (values 0 = none to 32,767; the same value on the
  same fixture count gives the same order); ShuffleMode Auto / Linked (same-position fixtures stay
  together) / Unlinked; with Rx/Ry/Rz only existing grid positions count. Shuffle changes selection
  order, not output: values must be applied again. It is stored with the MAtricks.
- **Shift** moves the selection within grid positions (+ right, down, front).
- **Invert**: InvertStyle (Pan, Tilt, Pan and Tilt, All), InvertX/Y/Z; inverted fixtures show green;
  Align with invert works on the X axis only. **Speed Master** can override From/To speeds.
- **Transform Mirror**: mirrors values by blocks, groups and wings (symmetrical effects on odd counts).
- Deactivating or resetting MAtricks restores the original selection order.

## What MA's tests add [M]

`Set Selection MAtricks Property "PhaseFromX" 0 "PhaseToX" 360`, `Set Selection MAtricks "XShift" 1`,
`Copy Selection 1 At 2`, `Clone Selection 2 At Selection 1 If Programmer /Overwrite`,
`Set CurEnv Property "ActiveSel" "1"`, `Store MAtricks n`, MAtricks export/import, `Shuffle`.

## Traps

- MAtricks act on the operator's live selection; a job that touches selection or MAtricks changes what
  Aaron is working with: clear and restore, or do not touch [C: ladder group job cleared before and after].
- Multipatch fixtures are not in the selection grid and are ignored by MAtricks [D: patch].

## Plugin access today, and gaps

- MAtricks pool objects are readable as objects [?: not read yet]. The live selection lives in the
  user environment (`CurEnv`), inside the user profile branch the console guard refuses [C].
