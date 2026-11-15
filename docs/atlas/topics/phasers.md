# Phasers: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Phasers", 6 pages, 2 keyword pages), 7 of MA's
phaser and phaser-recipe tests, the release notes 2.2 to 2.5, and Aaron's programming
(`docs/PROGRAMMING-STYLE.md`: effects come from the phaser pool, `Dim Sinus#2` and `Snap On#2` on
dimmers, `Circle` as a relative pan/tilt phaser on the Eras during holds; 2-4 step colour and dimmer
phasers on Infinibars and P1 Minis in choruses). Study pack: `python3 tools/atlas/pack.py "Phasers"
--terms phaser,step`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What a phaser is [D]

- A cue or preset with two or more **steps**; the output moves through the steps. One step = static.
- **Value layers** per step: absolute and/or relative values (stored, edited and played back
  separately, so they combine).
- **Step layers**: **Width** (time from this step's start to the next, % of one beat), **Transition**
  (% of the width spent changing), **Accel** and **Decel** (-100 % = smooth, sine-like; 0 % = linear;
  Spline Proportional "P" or Free "F").
- **Phaser layers** (same for all steps, per attribute of each fixture): **Speed** (BPM, Hz or
  seconds per beat), **SpeedMaster**, **Phase** (degrees offset per fixture: the spread), **Measure**
  (beats per loop; knocked in empty = number of steps).
- In cues, phaser layers travel together (adding one adds all) [D: presets page].

## Building steps [D]

- Hold **Step** and tap presets: a new step starts only when a preset touches attributes already in
  the current step (so one step can take a colour and a position preset).
- `Step 3` then a preset replaces step 3's reference. `Delete Step 3`; or select steps in the Step Bar
  and `Delete Programmer` (also At Filter > Delete Steps).
- By command (MA's tests): `Fixture 1`, `At 10`, `Next Step`, `At 20`, `At 30`; `Step 1 Thru 3` [M].
- **Stomp**: stops a phaser (programmer or playback) and resolves to its last static output in step 1.
  Calling a static preset onto running phaser attributes with the programmer in step 1 stomps them.
- **Sync**: predictable timing and phase on recall (encoder bar for the programmer; per cue part in
  the sequence sheet).

## Phaser editor [D]

- Window or temporary (Phaser button in the encoder bar). Views: Auto, 2D (pan/tilt square), 1D (one
  lane per attribute; Value or Transition scale), Sheet (steps as columns, layers as rows).
- Points: filled = absolute, hollow = relative, cyan = from a preset, yellow = hard value; green path.
- Left tools: Move Area, Select, Add Absolute, Add Relative, Move Point, Move Handles (accel/decel),
  Change Size, Change Rotation (MA = 5° steps), **Change Phase** (shortcuts, Reset, Invert, align by
  grid), **Change Width** (Speed shortcut equalises movement speed), **Select Form** (Rectangle,
  Sawtooth, Sine, Circle: rewrites transition, accel, decel), **Change Speed** (multiply/divide,
  Loop = x steps, Fixture = / fixtures), Select all Steps.
- Right tools: Reset spline, Delete, Cut / Copy / Paste Programmer, Mirror X, Mirror Y, **Mirror Time**
  (reverse), Swap XY, Flip, Reset Zoom.
- Step Bar (also a window): select steps; `*/3` = all of 3; `Step Toggle Executor`.
- Encoder bars: Preset Bar, 2D Bar, Phaser Bar.

## Phaser recipes (2.4+) [D, M]

- A phaser recipe lives in a programmer part, cue part or preset; built by command in MA's tests:
  `Store Type "PhaserRecipe" Programmer 0.1`, `Set Programmer 0.1.1.1 Property "ValueAbsolute" 100`,
  `Assign Attribute "Dimmer" At Programmer 0.1.1.1.1`, `Set Programmer 0.1.1.1 Property "TransX" 70`,
  `Set Programmer 0.1 Property "PhaseX" "30 Thru 90"`, `Set Programmer 0.1.1.1.1 Property
  "PhaseOffset" -10`, `Set Programmer 0.1 Property "LinkSteps" 0`, `Assign Filter "Only Color" At
  Programmer 0.1.1.1.1` [M]. In cue parts: `Set Cue 1 Part 0.1 Property "FadeX" "0 Thru 5"` [D].
- Shapes give phaser recipes their curve per step (see the shapes page when studied).

## Commands [D]

`Step n`, `Next Step`, `Delete Step 3`, `Delete Programmer`, `Pause Programmer`, `Store Programmer 42`,
`Attribute "Pan" At SpeedMaster 1`, `SpeedMaster`, `Rate1`, `Learn` (executor functions: Learn,
LearnSpeed, ReSync, FastSync, DoubleSpeed, HalfSpeed).

## Traps

- Before 2.5: phaser data could be lost after changing a fixture's type; FastSync on an NShot phaser
  stopped respecting NShot [D].
- Phaser presets used as special values (default, highlight, lowlight) only use step 1 [D].
- Aaron's phasers come from his phaser pool; a job never builds effects unasked [C: style guide].

## What we have proven

- Phaser cues and pool presets are visible in exports (`tools/cue_values.py` shows steps) [C]. Nothing
  built or changed.

## To bench on onPC

1. The object path of programmer parts and steps (`Programmer 0.1.1.1`) and whether the plugin can
   read them (would let a session see a phaser's layers exactly).

## Plugin access today, and gaps

- Phaser data inside cues and presets via export [C]. Gap: no tool reads the programmer [?].
