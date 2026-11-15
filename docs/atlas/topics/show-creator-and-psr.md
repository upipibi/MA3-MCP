# Show Creator, import/export, Partial Show Read: what we know, how sure we are

Written 2026-11-08 from the MA help 2.5 (chapter "Show Creator", 7 pages; keyword pages `AutoCreate`,
`AutoStore`, `Export`, `Import`, `Gel`, `PSR`, `/Gaps`, `/NoDependencies`), MA's MVR import/export
test, and our jobs (`ma3_export`, the curve import of 2026-11-08). Study pack: `python3
tools/atlas/pack.py "Show Creator" --terms showcreator,psr,export,import`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Import / Export (Menu > Show Creator) [D, C]

- Exports objects as small XML files with minimal show data; **referenced objects ride along** (a
  macro's appearance, for example) unless Include Dependencies is off (`/NoDependencies`). `/Gaps`
  keeps pool gaps. Object types: appearances, bitmaps, cameras, data pools, encoder bars, executor
  configurations, filters, gels, generators, gobos, groups, images, layouts, macros, MAtricks,
  meshes, pages, plugins, presets (each pool separately), quickeys, render qualities, scribbles,
  sequences, sounds, symbols, timecodes, timers, users, user profiles, views, videos, worlds.
- `Export Macro 1 "test"` (file named after the object when no name), `Export Macro 1 Thru 42`
  (one file each, or one shared file when a name is given), `... If Drive 2` for a USB drive; options
  `/Gaps`, `/GDTF`, `/HighPrecision`, `/NoDependencies`, `/Path`, `/Type`.
- `Import Macro Library "color.xml" At Macro 42`; in a destination: `Import Library "*.xml"`;
  without At, the first free slot; options `/Path`, `/Gaps`, `/NoDependencies`, `/NoRefresh`, `/Type`.
  Media imports can create appearances automatically.
- `ma3_export` writes these XML files and is our main deep-read tool [C]. The curve import of
  2026-11-08 went through the Patch import path, not Show Creator [C: job record].

## Generators of show content [D]

- Create Groups from fixture types, classes or layers (/All, /Single, /OddEven; Advanced picks a
  subset). Create Presets: universal dimmer steps (5-50 % increments) and universal mix colours (3-36
  hues by 1-20 saturations, or from a gel swatch book).
- Fixture-type presets: `AutoStore FixtureType "Mac Aura XB"`, `AutoStore Preset *.* At FixtureType 9`,
  `AutoStore Preset 4.1 Thru At Fixture 1 /Merge /NoConfirmation` (named presets only, global or
  universal advised, one value per attribute, not part of GDTF); Create Presets from FT rebuilds them
  in another show.
- `AutoCreate Selection At Group 1`, `AutoCreate FixtureType 10 At Group 42`, `AutoCreate FixtureClass
  "Spots" At Group 301`, `AutoCreate Preset "Dimmer" At Preset 1.11 "DimmerIncrement" 25`; options
  /All, /ChannelSet, /Merge, /OddEven, /Overwrite, /Single. Active MAtricks apply to selection sources.

## Partial Show Read (PSR) [D]

Brings objects, fixtures included, from another show file into the loaded one.

- **The source show must be saved with the same software version as the running one.** Aaron's old
  shows from before 2.5.1 would have to be opened and re-saved in 2.5.1 first (on onPC, never saving
  over the original).
- **PSR cannot be oopsed**, clears the programmer, and needs the station Standalone or IdleMaster.
  MA's advice: save the loaded show under a new name first. Phaser recipes lose their shape links;
  fixtures lose references to custom appearances.
- Prepare step: matches fixtures by FID, then CID, then GUID, then name; edit Stage, FID, ID type, CID
  on the PSR side; import Patch, Position and Rotation per property; Use PSR Only, Use Local Only,
  Merge PSR, Merge Local; filters by stage, match state (matched, unmatched, conflicted), fixture type,
  layer, class; fixture types can be exchanged. Unmatched ID types land in the PSR ID type.
- Import step: the source's object tree with checkboxes (references marked purple and taken along),
  Import Index per object (`<Auto>` merges with a same object), and an indicator per element: **green
  = newer data than the loaded show, orange = mixed, red = only older data**. That indicator is MA's
  own show-to-show comparison [D].
- The same menu integrates MVR files (fixtures and group objects by default).
- MVR import by command in MA's test: `AddOn 'MVR' 'MVRIMPORTPSR'` [M].

## For Aaron's multi-show questions

PSR's tree with newer / older markers answers "what changed between these two shows" visually on the
desk; our offline route (show files to onPC, snapshot, SQLite: `docs/research/2026-11-08-fast-show-
analysis.md`) answers it without loading anything on the console. PSR is the route to bring the
answer back into a show, onPC first, as a planned job.

## Plugin access today, and gaps

- `ma3_export` / imports by command are proven [C]. PSR is GUI-driven with pop-ups; not a plugin job.
