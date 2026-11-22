# The Nov 29 songs, programmed from Aaron's own cues (2026-11-21)

Aaron: "Once I'm done programming, I want you to program the Nov 29th weekend", then "im done
programming, go ahead with nov 29". First cues ever written by the MCP. His rules for it: learn from
his cues and old shows, do not ask how a song starts or ends, and "apply the why behind the past
shows, not hard values" because fixtures have moved.

Status: DONE, verified from fresh exports. Backup `Christmas 2026_mcp_1122_0412` (before the first
write). Sent through onPC as the `MCP` user: 244 commands plus 4 for a fix, undo groups `nov29-10`,
`nov29-11`, `nov29-12`, `nov29-12-fix`, `nov29-13` in the MCP user's Oops list. The show is not saved
since. `build.py` holds the full plan (`plan`, `run`, `verify`).

## Method

- **Cue list** = this year's Planning Center arrangement (plan 91338104, `song_prep`), in his naming.
- **Energy** = the words of his earlier cue list of the same song (`Breakdown`, `Drums In`, `Build`,
  `All In`, `Hits`, `Kick`): Thank The Lord, This Is Our God and King of Kings from the Easter 2026
  show, Manger to the Cross from Christmas 2025.
- **Every value** comes from his current show: each stored cue is a status copy (the whole look,
  tracked values included) of the cue that plays the same role in one finished song on this rig. One
  donor song per new song, so each has one palette, as his songs do.
- **Holds** are empty cues with a 2 s fade, as he leaves `Intro`, `Pre Chorus`, `Turnaround`, `Tag`.
- Cue 1 `Start - <title>`, cue 2 `-> Follows` (Follow), as in all his songs this season.

| Sequence | Song | Cues | Stored / holds | Looks from | Palette |
| --- | --- | ---: | --- | --- | --- |
| 10 | Thank The Lord (201 BPM) | 25 | 11 / 14 | 6 `Praise` | amber and orange, Tornado tilt phasers |
| 11 | This Is Our God (80 BPM) | 24 | 14 / 10 | 7 `Weight of Glory` | cyan with purple |
| 12 | Manger to the Cross (74 BPM) | 18 | 10 / 8 | 5 `Goodness Of God` | red with white |
| 13 | King Of Kings/Angels We Have Heard on High (68 BPM) | 32 | 18 / 14 | 8 `Abide` | warm white, peach, magenta accents |

## Calls I made

- Which finished song each one borrows from: by tempo and by having the roles the song needs.
- Thank The Lord: `Chorus / Hits` is Praise's strong static look, `Refrain 1 / All In` its moving peak,
  so the song climbs; the last `Chorus / Hits` uses the peak. `Bridge 1 / Kick` is Praise's pulsing
  ERA look.
- This Is Our God: both builds keep the source's 12 s fade; a `-> Follows` settles the first All In.
- Manger to the Cross: the last chorus is a breakdown, as he cued it in 2025; the lift is in the
  second `Bridge 2`.
- King of Kings: his 2026 energy map up to `Tag / Breakdown`. **Everything after it (Vamp, Bridge,
  Tag, the five `Angels We Have Heard on High` refrains) is my own arc**: he has no earlier cue list
  for that half. Least grounded part of the job.
- Named cue 1 of Sequence 13 `Start - King Of Kings`.

## What went wrong and was fixed

Sequence 12, cues 9 and 11: a status copy only holds what its source song had touched by that cue.
Used after a later source cue, the Q40 dimmer phaser kept tracking through. Fixed by copying with
`/CopyCueDestination "ForceRelease"` (values that track in and that the source look does not hold are
released). `build.py` now does that for every stored cue; the other three songs verified equal
without it.

## Proven on onPC by this job

- `Copy Sequence a Cue n At Sequence b Cue m /CopyCueSource "Status"` (also `/Overwrite`, and
  `/CopyCueDestination "Overwrite"` onto an existing cue, `"ForceRelease"` as above). Release is
  exported as `Absolute="Specials:Release"`.
- `Store Sequence b Cue m` from an empty programmer makes an empty cue (fade 0).
- `Label Sequence b Cue m "..."`, `Set Sequence b Cue m Part 0 Property "CueInFade" 2`,
  `Set Sequence b Cue m Property "TrigType" "Follow"`.
- An export of a song with 14 full-look cues passes 8 MB: ask `ma3_export` for `max_bytes` 80000000.

## Not known

- How it looks. I cannot see the stage; Aaron judges on a run-through.
- The new sequences are 1.0 to 1.6 MB in memory against 0.7 MB for his (more full-look cues).
