# Showfile conventions

How Aaron's grandMA3 light showfile is organized. Every model reads this before a
housekeeping job; a job's own instructions override it for that job only. Written
2026-11-03 from Aaron's answers and a read of the live show (sequences, pages, groups).

## Sequences

**Songs live in 1–89.** Each song is one sequence named exactly as the song title in
Planning Center (Title Case as PCO has it, e.g. `Thank The Lord`, `Gratitude + Great Are
You Lord`). New songs take the next free number from 1 upward; a song that returns in a
later weekend keeps its number. Three or four new songs arrive most weeks.

Inside 1–89 there are also a few non-song helpers Aaron keeps there (`Message Key`,
`Worship Key`, a `Sequence 18` placeholder). Never treat "numbered under 90" as "is a
song": a song has many cues (15–35) whose first cue is `Start - <title>`; a helper has one.

**Everything that is not a song lives in 171–322**: house looks (`Main House`, `Aux
House`, `Stage Wash`, `Tech Booth`), `Walk In`, `Message`, `Spot`, haze, Resolume control
sequences (`R - ...`, including `R - Song 1..15`), clear layers, banner, spot pages,
remote/call sequences (306–310) and sizing helpers. **Never delete or renumber anything
in 171–322.**

Aaron switches between two views that act as two sequence pools (songs, everything else).

**Cues are Aaron's.** A job never creates, edits or deletes cues; it creates empty song
sequences (`Store Sequence <n> "<title>"`) and Aaron programs them. For reference, his
layout is cue numbers in thousands (`1000 Start - <title>`, `2000 Verse 1`, `3000 Pre
Chorus 1`, ... `Chorus / Hits`, `Bridge`, `Tag`, `Refrain`, `Ending`), `-> Follows` cues as
follow steps, and sub-steps like `12200`, `12400` between sections.

**Deleting old songs is the one decision a job must put in front of Aaron every time.**
A song still assigned on a page that is kept is never a candidate. Songs assigned only
on older weekend pages are candidates; list them with name, cue count and the pages
they sit on, and wait for a go. `TODO(Aaron)`: is there a rule of thumb (older than N
weekends, or not in the next N PCO plans) that makes a song safe to delete without
asking?

## Pages and executors

**One page per weekend**, named by date as `Sept 6`, `Sept 13`, `Sept 20`, `Sept 27`
(month abbreviation, day, no year). Pages 5–8 are the current run.

A new weekend page is a **copy of the previous weekend's page** with the songs swapped
(Aaron no longer copies `Weekend Base`, Page 2, which is slightly out of date; `Busking
Base`, Page 1, is deprecated and empty). So: `Copy Page <last weekend> At Page <next
free>`, label it, then reassign executors 106–109.

Executor layout on a weekend page (executors are two rows tall: the 2xx executor under
each 1xx one is the lower half of the same button, so assign only to the 1xx row):

| Executor | Holds | Source |
| --- | --- | --- |
| 104 | Walk In | Sequence 177 |
| 105 | Message | Sequence 178 |
| 106–109 | the weekend's songs, in service order | song sequences |
| 191–194 | Clear Layer 1–3, Clear Banner | 205–208 |
| 196–198 | Shuffle 2–4 | Macros 55–57 |
| 201 | Key | Group 700 |
| 202–203 | Spot, Spot 2 | 183, 184 |
| 216 | Main House | 171 |
| 218 | R - Walk In | 215 |
| 221–227 | Resolume/Transition masters, Banner Black Out, Key, Portman presets | groups, 220, presets |
| 231–235 | masters (Era Dim/Pos, R1 Dim, Lowlight, Highlight) | Masters |
| 294, 298 | R - Douse, @ 0 | 214, Macro 4 |
| 304–309 | R - Walk In, R - Message, R - Song 1–4 | 215, 217, 238–241 |
| 401–404 | Clear Layer 1–3, Right DF 50 Haze | 205–207, 186 |

A fifth song goes on 110 (unused today); more than that is a question for Aaron.

**Pages that are never touched by a job:** 15 `Relays`, 16 `X Keys`, 17 `Utility`,
30/31 `Remote 1/2`, and 1/2 (`Busking Base`, `Weekend Base`).

## Groups

Number ranges by fixture family, confirmed: 100 Era, 200 Screens / Stage R1, 300 Fuze,
400 Portman, 500 Q40, 600 Tornado (602 Rings, 603 Ring Sections, 605 Yokes, 606 Yoke
Sections), 700 Key, 800 LED (802 Dimmers, 804 InfiniBars, 808 LED Crop, 809 Tutu,
811–822 Ladder 1–12), 900 Resolume fixtures, 910–912 catwalk/house, 1000 house (1000
Main House, 1001 Lower, 1002 Upper, 1003 Side, 1004 Back Wall, 1005 Rear Upper Balcony,
1006 Stairs, 1007 Stage Wash, 1008 Haze), 1100 Relays, 2200+ Resolume layer/song
groups. New groups for a fixture family go in that family's hundred, next free number;
instance groups follow the existing pattern (`Rings`, `Ring Sections`, `Yokes`, `Ladder n`).

## Names

Lower key is Aaron's taste; song names copy PCO exactly. Match the style already in the
pool for everything else (`Main House`, `R - Song 1`, `Clear Layer 2`). No tags, no
appearances to mark songs or fixed items; the ranges above are the marker.

## Planning Center

Songs come from the **Sunday services** service type, the next upcoming plan. In a plan,
songs are the items PCO types as songs (item type `song`); headers, announcements,
message and media items are not songs. Service order in the plan is the executor order
106–109.

## Always

- Every job that deletes or rewrites starts with `ma3_backup` and a shown plan.
- Nothing is saved to disk by a job except through `ma3_backup` / `ma3_save`.
- A timeout proves nothing: re-read before resending a command.
- Future idea, not a job yet: build a simple song sequence from Aaron's existing
  programming. Do not attempt it unasked.
