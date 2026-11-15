# Recipes: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Recipes", 4 pages, 4 keyword pages), MA's recipe
editing test, cue and preset recipe sections (see [cues-and-sequences.md](cues-and-sequences.md),
[presets.md](presets.md)), and the release notes 2.2 to 2.5. Aaron's songs use hard values, not
recipes (`docs/CONVENTIONS.md`). Study pack: `python3 tools/atlas/pack.py "Recipes" --terms recipe,cook`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What a recipe is [D]

- Lines that describe a look (selection or group, values or presets, MAtricks, filter, fade, delay,
  speed, phase, grid) and **cook** it into a cue part, a preset or the programmer. Cooked data carries a
  pot marker and can be removed again. Useful for touring rigs where fixtures change.
- **Four possible sources for one attribute in a cue**, one wins: values stored in the cue part beat the
  cue part's recipe; values stored in a preset beat the preset's recipe; a preset reference in the cue
  part means the preset decides.
- Cooking a cue part: Merge keeps existing values; Overwrite replaces everything (values the recipe does
  not touch are removed).
- **Storing recipes into a feature-group preset pool stores all values; the input filter is ignored.**
- Pot icons: green (standard lines cooked), violet (phaser lines cooked), red (a line did not cook),
  orange (cooked plus uncooked data), open green / open violet (templates); both pots = mixed.

## Recipe editor columns [D]

- Standard lines green, phaser lines violet. X / Y / Z / Shuffle toggles show MAtricks columns.
- Name (red = cannot cook), Part (programmer part, editor window only), Step (automatic), Tags,
  **Enabled**, **Selection** (group or fixtures; red = empty group) with **Selection Mode** Normal (values
  pass to sub-fixtures) or Strict (only the listed fixtures; set on shows migrated from 1.9.7 or older),
  **Values** (preset or value), Filter, **Shape** (phaser), Value Source, Attributes, Value Absolute /
  Relative, Curve (Linear, Ease In and Out, Ease Out, Ease In, Snap, Swing, Custom), Trans / Width /
  Accel / Decel X/Y/Z, Link Steps (Yes by default in new shows), Speed X/Y/Z (ranges like `60 Thru
  90`), Speed Master, Phase X/Y/Z, Measure, **NShot** (run n cycles then stop; Stay keeps the end
  values; Unlimited; below 1 stops early), **Direction** (Forward / Backward / Alternate), Adaptive
  Measure, Adaptive Width (two-step phasers only), XY Rotation, MAtricks reference; "No Values" overrides
  referenced MAtricks values but never values stored in presets.
- With a world selected, cooking in the programmer cooks only that world's channels; stored recipes are
  cooked in full.

## Recipe editor window and edit recipe mode [D]

- Shows all programmer parts (part 0 plus up to 239); add or delete parts, recipes, steps; restart
  phasers (`Cook PhaserRecipe1 /Restart /MergeLowPriority`).
- Storing: to a cue part, the selected (green) part's lines; to a cue (`Store Cue 1`), every part as
  cue parts; to a preset, the selected part. Stored recipes leave the editor.
- **Edit Recipe mode** (`EditRecipe`, At Filter > Edit Recipes, or the window's title bar): tapping a
  group then presets records recipe lines; incompatible presets grey out; the last line wins for the
  same selection and attribute; values cannot be typed into a recipe (store them in a preset first).
  `EditRecipe Cue n` edits an existing object's recipes. Off + tap removes a line. CleanUp removes
  lines superseded by later presets of the same feature group.

## Commands [D]

| Command | Use |
| --- | --- |
| `Cook <object>` | `/Merge`, `/MergeLowPriority` (default), `/Overwrite`, `/Remove`, `/Restart` |
| `CleanUp <object> /Type "Recipe" /Recipe "NoOutput"` | `"NotCooked"`, `"CookedButOverwritten"` |
| `EditRecipe <object>` | edit recipes in the programmer |
| `Store Type "PhaserRecipe" Programmer 0.1`, `Insert Type "StandardRecipe"` | create lines by command [M] |
| `Set Programmer 0.1.1.1 Property "ValueAbsolute" 100` | line values by command [M] |

## Traps

- 2.5.1.0: cue durations were wrong when a cue contained recipes (Follow timing off) [D].
- 2.5: MIB with cue recipes could stop after patch changes; break protection rules apply to cooking [D, M].
- PSR imports only phaser recipes that use predefined shapes [D].

## Plugin access today, and gaps

- Recipe lines are objects under cue parts and presets (readable with `ma3_children` [?: not read
  yet]); exports include them [C: export of cues]. No recipe job has been done.
