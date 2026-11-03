# Showfile conventions

How Aaron wants the grandMA3 light showfile organized. Every model reads this before a
housekeeping job; a job's own instructions override it for that job only.

**Status: skeleton.** Lines marked `TODO(Aaron)` are questions still to answer. The
`ma3-housekeeping` skill refuses destructive jobs while any `TODO(Aaron)` remains.

## Sequences

- Which sequences are songs, and how is a song sequence recognized? `TODO(Aaron)`
  (name pattern, pool range, tag, appearance, number of cues, assigned page?)
- Which sequences are never songs and must never be deleted by a job (walk-in, house,
  lyrics, message, warmers, relays)? `TODO(Aaron)` (names or number ranges)
- Where do new song sequences go (number range, naming: song title only? service
  date?), and how are old ones handled (delete, or move to an archive range)? `TODO(Aaron)`
- Standard cue layout inside a song sequence (cue names such as Intro, Verse, Chorus,
  Bridge, Ending; OffCue behavior)? `TODO(Aaron)`

## Pages and executors

- The weekend page: one per weekend or one reused page? Naming (date? "Weekend")?
  `TODO(Aaron)`
- Executor layout on a weekend page: which executor numbers hold songs in service order,
  which hold the fixed items (walk-in, message, house), key and fader functions?
  `TODO(Aaron)`
- Pages that must never be touched (busking, system)? `TODO(Aaron)`

## Groups

- Naming and numbering for groups built from a multi-instance fixture's instances (per
  fixture, per row, odds/evens, all)? `TODO(Aaron)`
- Group number ranges per fixture family (the show uses 100 Era, 200 Screens, 300 Fuze,
  400 Portman, 500 Q40, 600 Tornado, 700 Key, 800 LED, 900 Resolume, 1100 Relays as of
  2026-11-03; confirm and extend). `TODO(Aaron)`

## Names, appearances, tags

- Capitalization and punctuation rules for names; use of tags or appearances to mark
  "song" / "fixed"? `TODO(Aaron)`

## Planning Center

- Which PCO service type and plan the songs come from, and which items are songs vs.
  other elements? `TODO(Aaron)`

## Always

- Every job that deletes or rewrites starts with `ma3_backup` and a shown plan.
- Nothing is saved to disk by a job except through `ma3_backup` / `ma3_save`.
- A timeout proves nothing: re-read before resending a command.
