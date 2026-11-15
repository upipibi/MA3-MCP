# Masters: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapter "Masters", 8 pages, 9 keyword pages), MA's masters
and timing tests, the release notes 2.2 to 2.5, and Aaron's page layout (masters on executors
231-235: Era Dim/Pos, R1 Dim, Lowlight, Highlight; `docs/CONVENTIONS.md`). Study pack:
`python3 tools/atlas/pack.py "Masters" --terms master,solo,speed_timing,timeconfig`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## What masters are [D]

- Timing and level overrides in five groups, all assignable to executors and special executors
  (assign menu > Object > Master, a tree); the `Master` keyword addresses them (`Master 2.1`,
  `Master "Timing"."Timing1"`).
- Fader-specific settings in the assign menu's Edit Setting tab: **Normed Value** (current value, and
  the default position when assigned) and **Fader Enable** (the mode). Speed masters add SpeedScale and
  LearnMode.
- **Modes**: Toggle (on/off, grey/green; Temp works when off), Always On (white), Disabled (red; the
  master uses its default internally: grand master 100 %, program time 0 s). All modes in Menu >
  Preferences and Timings > Masters.
- **Membership**: Global masters (one set for every user, "(Global)") versus user-profile masters
  (each profile its own, for example "Selected (Admin)").
- **Masters window** (2.5; Add Window > More > Playback > Masters, or hold Group): tabs Group, World,
  Speed, Playback, Timing masters, Master Controls; Full / Zero or Flash / Black buttons; Label Action
  Locate or SelectFixtures; shows which masters are off default.

## The five groups

| Group | Members | Notes |
| --- | --- | --- |
| Selected (`Master 1.n`) | 1 Master, 2 XFade, 3 XFadeA, 4 XFadeB, 5 Temp, 6 Rate, 7 Speed, 8-10 Highlight/Lowlight/Solo (no function here), 11 Time | act on the selected sequence |
| Grand (`Master 2.n`) | 1 Master (grand master), 2 World, 3 Highlight, 4 Lowlight, 5 Solo, 6 Rate, 7 Reserved, 8 ProgramTime, 9 ProgramXFade, 10 ExecutorTime, 11 ExecutorXFade, 12 Blind, 13 SoundOut, 14 SoundIn, 15 SoundFade | the help says 14, lists 15 |
| Speed (16) | 0-225 BPM; SpeedScale multiplier/divider; LearnMode (Learn Ignores Speed Scale (default) / Respects / Auto Increase); **speed master 16 is the BPM master** from audio input | assign to sequences, cues, parts, attributes, presets, generators, phasers to sync them |
| Playback (50) | inhibitive dimmer master for every sequence assigned to it (sequence setting Playback Master) | |
| Timing (50) | 0-10 s; stand in for CueIn/Out Fade/Delay, feature group times, playback timings: `Cue 3 CueDelay "Timing2"`, `Timing1/Timing2` in condensed cells, `Goto Cue 5 Fade "Timing5"` | read when the cue fires |

## Highlight, Lowlight, Solo [D]

- Temporary output overrides that never write the programmer, cues or fixture data.
- **Highlight** (`[Highlt]`, `Highlight`, `Highlight Off`): selected fixtures go to their Highlight
  values (fixture type Highlight column, or Parameter List / `Store Highlight`). Use: check selection
  order with Next.
- **Lowlight** (MA + Highlt): only with Highlight; the sub-selection goes to Lowlight values.
- **Solo** (`Solo`, `Solo Off`): every non-selected fixture's **dimmer** to zero (non-dims on other
  attributes are untouched); sits very high in the output stack without changing priorities.
- Grand masters 2.3-2.5 scale those states; they may misbehave when positive, negative or scaling
  group masters affect the fixtures. Fixtures with Master React None ignore solo (patch).
- **These change the live stage**: never from a job during a service.

## Time control [D]

- **Program Time** (0-10 s): fade time for programmer changes when on (green marker); presets with
  stored timing keep theirs.
- **Executor Time** (0-10 s): overrides cue timing for sequences with Use Executor Time on (Aaron's
  songs have it on [C]); on/off with On / Off / Toggle on its executor or Master Controls.
- 2.5: their readout is seconds (was percent).

## Commands [D, M]

`Master 2.1 At 50` style levels via `FaderMaster`; `Set Master "Timing"."Timing1" Property
NormedValue 10` [M]; `On Root ShowData.Masters.Grand.ProgramTime` / `Off ...` [M]; `Blind`, `Blind
Off` (programmer output suppressed: the DMX sheet shows it); `Highlight`, `Store Highlight`,
`At Highlight`; `Solo`; `Assign Master "Timing"."Timing1" At Page 1.216`; `Label` for names.

## Traps

- A Disabled master silently uses its default (grand master 100 %): a fader that "does nothing" may be
  Disabled, not broken [D].
- User-profile masters differ per profile: a job reading masters must name the profile [D].
- Before 2.5 masters could not be recorded or assigned in timecode tracks [D].

## What we have proven

- Masters assigned on Aaron's pages are read through `ma3_pages` [C]. No master level, mode or
  membership has been read or set by a job.

## To bench on onPC

1. The object paths of the five groups (`ShowData.Masters...` and the user-profile set) and their
   properties (`NormedValue`, mode, membership).
2. Whether a master's level is readable live (useful for Cue Display or a status read).

## Plugin access today, and gaps

- Masters in the user profile are inside `ShowData > UserProfiles`, which the console guard refuses
  today; global masters under `ShowData > Masters` are allowed [C: guard rules]. Gap: no masters tool.
