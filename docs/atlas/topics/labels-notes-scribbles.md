# Labels, notes, scribbles: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapters "Label Objects", "Notes" 3 pages, "Scribbles" 4
pages; keyword pages `Label`, `Note`, `Delete`, `Edit`), MA's label and note system tests, and our jobs
(the stage flip and the Christmas pages labelled sequences and pages by command). Study packs:
`pack.py "Label Objects" --terms label`, `pack.py "Notes" --terms note`, `pack.py "Scribbles" --terms
scribble`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Labels [D, C]

- `Label <Object> <n | "name"> "New name"`; Assign twice on the keypad types `Label`; shortcut `L`.
  Without a name a Label pop-up opens (name, keyboard, scribble pad, appearance editor, tags, note).
- **Forbidden characters in names: `\ " $ & * ? , . ; ^ { | } ~`** [D]. MA's label test exercises
  ASCII, extended ASCII and unicode names and checks export file names [M].
- A range enumerates a free-standing number: `Label Fixture 1 Thru 10 "Mac700 1"` gives Mac700 1..10.
- `Label Preset "Color"."Red" "Dark Red"`, `Label Group 1 At Attribute` (name from the selected
  attribute), `Label Group 5 At Sequence` (name of the selected sequence) [D: macros chapter].
- **`Label` with no object addresses a cue in the selected sequence** (`Label 42` relabels cue 42, or
  sequence 42 when the selected sequence is disabled; bare `Label` = current cue). A plugin command
  must always name the object type [D]. Our jobs always did [C].
- Show-file names are cut to 31 characters; `ma3_backup` handles it [C].

## Notes [D]

- Free text on any object that has a Note button or cell: pool objects, cues, macro lines, fixture
  types, patch lines. Multi-line (Shift + Please for a new line). Seen and edited in the Info window.
- `Note Macro 5` (opens the editor), `Note Plugin 42 "Important"`; shortcut `Not`. MA's test proves
  `Note Fixture ...` is refused: fixtures take notes through the patch Note cell only [D, M].
- Sequence sheet: Show Notes (a live-editable field for the selected cue; turns Show Recipes off),
  Line Height Auto for multi-line notes. Timecode viewer and editor hide the Note column by default
  (2.4). Leading and trailing spaces and empty lines are trimmed except in the sequence sheet (2.2).
- Property name on objects: `NOTE` [?: confirm on onPC]. Cue notes are a natural place for the plugin
  to leave job marks, but only with Aaron's agreement.

## Scribbles [D]

- Small drawings in the Scribbles pool, assigned to objects as a label alternative. Made in the pool
  (Edit opens a pad with colour picker, B fader, Thickness, Set Scribble to Color, Use Color as
  Filter, Oops, Clear, Revert) or from an object's Label pop-up or Scribble setting (**every scribble
  made there lands in the pool's first free slot**: MA advises making them in the pool first).
- Assign: Assign + scribble + object, swipey Assign, the object's Scribble setting, or the `Scribble`
  keyword. Deleting a scribble drops its links; Oops restores them.

## Plugin access today, and gaps

- Labels by command are proven [C]. Notes and scribbles are plain properties [?: not read or set by a
  job yet].
