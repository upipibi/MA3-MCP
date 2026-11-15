# Appearances and tags: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapters "Appearances", 4 pages, and "Tags", 1 page), MA's
appearance and tag tests, and our notes (Aaron uses no tags or appearances to mark songs; the number
ranges are the marker: `docs/CONVENTIONS.md`). Study packs: `pack.py "Appearances" --terms
appearance`, `pack.py "Tags" --terms tag`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Appearances [D]

- Looks (background colour with alpha, an image, image colour) assigned to pool objects, presets, view
  buttons, windows, layout elements, executors (via the object), cue parts. Appearances pool.
- Create: edit an empty pool object (`Edit Appearance n`): Name, background RGBA (faders, picker, hex),
  Image (from Images, Videos, Gobos or Symbols pools), **ImageMode** Stretch / Bar / Crop / Tile /
  Center, image colour (adds colour only: black stays black), ImageRotation 90/180/270, ImageMirror;
  Revert. Assigning a media object to an empty appearance creates one; assigning an appearance to
  another copies it.
- Assign: Assign + appearance + object; `Assign Appearance 3 At Group 5`, `Assign Appearance 1 At
  Sequence 2 + 3 + 4`; or the object's Appearance setting.
- Our plugin's pool-button state uses an appearance named `MA3 MCP` if Aaron creates one [C: code].

## Tags [D]

- Labels that link objects; objects with the same tag can be triggered or selected together (busking).
  Tags pool; a tag can be tagged.
- Assign: tag editor (Add New Tag Reference, several at once), the object's Tags setting, the Tags column
  of cues, recipes and macro lines, or by command: **`Assign Tag n At <object>`**, `Assign Off Tag "x"
  At Sequence 3` (`Set ... Tags` does not work [C]).
- Tag editor columns: Data Pool, Class, No, Name, **Protect** (immune to Kill Instant / Kill Delayed).
- Tag settings: Name, Scribble, Appearance, Tags, Note, **Tag Type**, Action, **Forward Commands**
  (default on: `>>>`, `<<<`, `Go+`, `Go-`, `Goto`, `HalfSpeed`, `Load`, `On`, `Off`, `Pause`, `Rate1`,
  `Speed1`, `Toggle`, `Top` sent to the tag reach every tagged object).
- Tag types: **Kill Instant** (starting a tagged sequence starts the OffCue of the others at once),
  **Kill Delayed** (after the started one finishes its fade in). Set them before triggering. Kill
  Protect does not protect against tag kills; Flash, Temp, Swap and Black do not permanently switch
  others off. The Off menu's Trigger column shows the tag that started a playback.

## Traps

- A tag with Forward Commands turns one command into many playbacks: reading tags is safe, sending
  playback commands to a tag is a stage action [D].

## Plugin access today, and gaps

- Tags and appearances are pool objects; `ma3_object` reads an object's `TAGS` and `APPEARANCE` [C].
