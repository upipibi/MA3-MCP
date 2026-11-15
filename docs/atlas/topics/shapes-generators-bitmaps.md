# Shapes, random generators, bitmaps: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapters "Shapes", "Generator - Random", "Bitmap" and the
keyword pages `Shape`, `Generator`, `Bitmap`), MA's two bitmap system tests, MA's menu code for the
three editors, and the release notes 2.2 to 2.5.1.1. Study packs: `pack.py "Shapes" --terms shape`,
`pack.py "Generator - Random" --terms generator`, `pack.py "Bitmap" --terms bitmap`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

None of the three is used in Aaron's shows that we have read [C: show digests]. All three act on the
programmer: calling one with fixtures selected changes the stage unless Blind is on [D].

## Shapes [D]

- A shape is a pool object holding **one phaser recipe**: how values move between steps over time.
  Made for phaser recipes (pick a shape in the recipe's Shape column instead of hand-setting curves).
  Introduced in 2.4; imported and exported through Show Creator.
- Always holds Transition, Width, Acceleration, Deceleration per step; optional Attributes, Speed,
  Speed Master, Phase, Measure, NShot, Direction, Adaptive Measure, Adaptive Width, XY Rotation,
  MAtricks (property meanings: the recipe editor, `recipes.md`).
- **22 predefined shapes** in the pool; some attribute-specific, some generic. A white-square feature
  group bar means the shape holds attribute values; generic shapes have no bar.
- Calling a shape: an attribute shape sets those attributes on the selection and outputs; a generic
  shape applies to the attributes already active in the programmer with multi-step values.
- Editor: Sheet tab (one row per step, attributes grouped under Value Source headers; Group By
  Attribute flips rows to attributes) and 1D tab (curves, Accel X, Decel X, Trans X, Width X, Value
  Absolute / Relative; add / delete attribute or step; Show Step Values; Minimum Step Width).
  **Link Steps** (two-step shapes only: widths sum to a constant, accel of one = decel of the other)
  and **Make Other Symmetrical** for transitions. Settings: Name, Scribble, Appearance, Tags, Note;
  Revert.
- Commands: `Store Shape 21` (storing deactivates the programmer values), `[Function] Shape
  ["name" | n]`. Pool settings include First Index (2.4).
- The **Shaper** dialog (blade shapers) is a different feature with a similar name: its bugs in the
  release notes are not about shape objects.

## Random generators [D]

- Generator pool objects of type Random: absolute values that wander per fixture, with **variance**
  so each loop differs (without variance it would be a plain phaser). Absolute layer only. Called into
  the programmer, stored in presets or cues.
- One generator holds several **Random Channels** (rows), each: Attribute, Speed Master (one of the
  15 speed masters or BPM), Speed and Speed Variance, Phase and Phase Variance, Low and Low Variance,
  High and High Variance (percent of the attribute's DMX range), Attack, Decay, Ratio and Ratio
  Variance, **Speed Once** / **Phase Once** (pick once at start, or re-pick every loop and follow live
  edits), **Random Start** (same start each time, or different).
- Commands: `At Generator 2`, `Attribute "Zoom" At Generator "Flicker"`; shortcut `Gen`. Editor has
  Revert and an At button.
- Fixed in 2.2: deleting a generator in data pool 2 or higher deleted the whole data pool; the
  Speed fader could not exceed 60 BPM.

## Bitmaps [D, M]

- Map a media file (image, gobo, symbol, video, NDI stream) onto fixtures arranged in the **selection
  grid**. The purple rectangle in the grid is the **canvas**. Pool objects in the Bitmaps pool (part
  of the data pool).
- **Known limitation: an 8K video previewed in the Layout Viewer can overload and crash the system.**
  Keep sources at 1920 x 1080 or less, 30 Hz (DMX outputs at most 30 Hz). NDI sources must be
  reachable from every calculating station in a session.
- Bitmap Configuration rows (one plays at a time): Content, Width / Height (canvas, default 64),
  Interpolate, Alpha, Content Mode (None, Clip, Wrap), Control X / Y / Zoom / Aspect / Rotate, Color
  R / G / B. Editor buttons At, Dimensions From Selection, Format Selection, Auto Format, Revert,
  Speed Master (video speed).
- Bitmap Channels: which attribute follows which part of the image (Attribute, Source, Value Low /
  High); for example a pixel's brightness drives Tilt.
- **Bitmap Control fixture** (MA fixture type with no real DMX channels): patch one, apply the
  bitmap to it, and its X, Y, R, G, B, Zoom attributes drive the configuration from cues and presets.
- Commands: `At Bitmap "Unicorn"` (shortcut `Bi`); MA's test also sets configuration properties
  with `Set Bitmap n Property '<name>' <value>` and `Set Bitmap n Property 'BMC' 1` [M].
- Release-note traps: **deleting a bitmap from a data pool other than 1 deleted the whole data pool**
  (fixed 2.5.1.1, the version on Aaron's console); nodes could crash with bitmaps (fixed 2.5);
  importing a video into a pool slot assigned to a running bitmap crashed (fixed 2.4); editing a
  bitmap during an active video stream crashed (fixed 2.3).

## Plugin access today, and gaps

- All three pools are reachable with `ma3_children` / `ma3_object` under the data pool [?: not
  read yet on a show that has them]. A plugin job would never call one during a service (stage
  output). Bitmaps with video are a known crash class: the console guard keeps the plugin away from
  media previews, and a job touching bitmaps would be onPC-only first.
