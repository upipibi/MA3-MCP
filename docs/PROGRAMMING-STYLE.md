# How Aaron programs the grandMA3

What his show files show about the way he builds and runs the console. Read with
`CONVENTIONS.md` (where things live) before any job that creates or shapes content for him.
Sources so far: `Christmas 2026` as read live 2026-11-03, `Christmas 2025 (no audio)` and
`Weekend Experience Easter 2026` read 2026-11-04 (per-show reports in `docs/research/shows/`, local only: not in the public repo). Grows with each show.

## The two kinds of show

- **Weekend services.** One sequence per song, run by hand from the song row of a dated page.
  Cues follow the song form; fades are 2 s or 4 s; the operator presses Go on the downbeat.
- **Christmas production.** One sequence per song plus a `(Key)` twin, every song also a
  **Timecode** show (one per song, numbered in run order) that fires `Go+` events into the song
  sequence and into effect sequences (strobes, ladders, Portman duck) to the frame at 30 fps.
  Fades in production songs run from 0 (snaps on hits, strobes, raps) to 15 s (outros).

## Cues

- **Numbering.** Whole numbers from 1 in song order. A decimal cue (`12.2`, `12.4`) is a cue
  Aaron inserted later between two cues he had already programmed; he usually renumbers the
  song back to whole numbers afterward, not always (Aaron, 2026-11-04).
  Cue 1 is always `Start - <title>` (production: `Start - <nickname>` such as `Start - Drummer
  BOI`). Cue 2 is usually `-> Follows`, a Follow-triggered step that finishes the start look.
- **Names are the song form,** not the look: `Intro`, `Verse 1`, `Pre Chorus`, `Chorus`,
  `Interlude`, `Turnaround`, `Bridge`, `Build`, `Vamp`, `Tag`, `Refrain`, `Post Chorus`,
  `Instrumental`, `Breakdown`, `Outro`, `Ending` / `End` / `Blackout`. Two things happening at
  once are joined with a slash: `Chorus / All In`, `Bridge / Hits`, `Verse 3 / Breakdown`,
  `Chorus / Key Change Up`, `Ending / STROBE`. Parenthesised names are operator notes on a
  musical moment: `(Build)`, `(STOP)`, `(Hold)`, `(STROBE)`, `(Drums In)`, `(Flip 1)`,
  `(Continues)`. Production cues may name a person (`Ish`, `Margot`, `Dancers Move Center`) or
  a lyric (`''its only just begun''`, `KILL EM #`). Humor is allowed (`ENDING Cuz Aarons
  LAZZYYYYY`, `CAROL THESE BOI`).
- **Triggers.** Go for almost everything (480 of 558 cues in the 2025 production file, 1092 of
  1222 in Easter 2026), Follow for the `-> Follows` steps and chained hits, Time rarely.
- **Vocabulary is stable across years.** Easter 2026's top names: Verse, Chorus, -> Follows,
  Bridge, Intro, Refrain, Interlude, Ending/End, Pre Chorus, Tag, All In, Build, Outro, Vamp,
  Instrumental, Hits, with `(Hold)`, `(HIT)`, `(Hit 1)`, `(Vox)`, `(Strobe)` as moment notes.
- **Timing.** Set per cue in the cue's part 0: in fade only, delays 0, out fade/delay left at
  `CueTiming`. Weekend songs alternate 4 s (Start, Verse, Chorus, Hits, Ending) and 2 s (Pre
  Chorus, Interlude, Bridge, Build, Vamp, Outro). Production songs: 0 on hits/strobes/raps, 0.5
  on verses, 4–8 on builds and interludes, 15 on an outro. Key sequences: 0.5–3 s with out
  delays (1 s, 8 s) so one singer's key holds while the next fades up. MIB Early on key cues.
- **Sequence settings** are console defaults: Tracking on, Auto Stop on, LTP, Restart First
  Cue, Wrap Around, Soft LTP, Off When Overridden, Release First Cue, executor time on.
  Appearance set only on some (Key twins Orange 3, Drummer Boy Blank 71).
- **Hard values, not recipes.** Songs are reused for the life of a stage design and deleted
  at a stage flip (see CONVENTIONS).

## What is inside a cue (from exports of Greatest Show, A New Song, Walk In, Easter 2026)

- **Key light is a preset recall, every cue.** The 7–8 Fuze Profile follow spots take every
  attribute from `Preset 21.700 Worship` in almost every cue (3,223 references in one song).
  The preset itself holds hard values per unit: pan 40–135, tilt 54–68, zoom 16–20, frost 100,
  CTC 0–18, dimmer 0–100 with some units parked at 0.
- **Moving-light position, focus and zoom come from presets; colour is typed in.** Eras
  reference `Era Home` / `Era Out 2` / `Era Full` for Pan, Tilt, Focus, Zoom and often Dimmer,
  while their RGB sits as absolute numbers (R 97–100, G 67–98, B 43–98: warm amber to white).
  R1 washes do the same with `R1 Home` / `R1 Out 2` / `R1 Full`. When he does type a
  position, it is a fan: Pan -32 to +32 across 12 units, Tilt in a 10-degree spread.
- **Panels and pixels are absolute colour plus a dimmer level.** The 48 Q40 panels carry one
  RGBW colour per look (R 100, G 70, B 0, W 83 = amber; R 0, G 45, B 100, W 12 = blue walk-in)
  and a dimmer that steps between 4.7 (hold), 17–25 (verse), 100 (chorus, hit). Infinibars
  (192 cells) and P1 Minis (84–90 cells) run 2–4 step colour and dimmer phasers in choruses and
  sit at a static colour in verses.
- **Conventional dimmers are the dynamic bed.** The 15 house/stage dimmers move every cue:
  10 as the floor, 30–45 in verses and holds, 60–80 on hits, 2–3 step dimmer phasers in builds.
- **Effects come from the Phaser pool, not typed:** `Dim Sinus#2` and `Snap On#2` on dimmers
  for chases and hits (Snap On with 3, 5 or 9 steps depending on fixture count), `Circle` as a
  relative pan/tilt phaser on the Eras during holds. Nothing else is animated.
- **Hits are a one-cue burst:** Q40 and Era dimmers to 100 on `Snap On#2`, house dimmers 60,
  fade 0; the `(Strobe)` cue adds Shutter1 16 on the Eras. The `(Vox)` cues knock the key and
  Eras back with 0.2 s fades and use `Release` on attributes so tracking stops.
- **Fade curves:** SCurve everywhere except `Fast+` on a verse snap.
- **Start cues are full-stage states** (every family present, 2–6 s fade); later cues touch
  only what changes. Tracking does the rest, which is why `-> Follows` cues often set only
  Dimmer and a position.

## Hit sequences (production, Easter style)

One-cue sequences parked right after the song they serve, Purple 2 appearance, named with the
song's initials: `IRIAG HIT 1–3`, `GS HIt 1–2`, `Goodbye Hit1/2`, `I Thank Bump`, `Thats Who
Chase`. Timecode (or a finger) fires them over the running song for accents the song's own cue
list does not carry. Easter timecode runs on the internal clock (slot 255, seconds readout) and
its tracks also fire `R - Song n` and `Clear Layer n`, so video follows the same timeline.

## Key sequences (production)

`<title> (Key)` at song number + 18 (54 → 72), run on the executor one row right of the song
(song 106–110, key 111–115). Cue 1 `(KEY) Start - <title>` (note "Position zero"), then cues
named for who is lit (`Ish`, `Margot`, `Dancers`, `Taiko / Fly Drummers`, `Key Up`, `Move
Center`), last cue `Blackout` / `OUT` / `Key Up`. 2–12 cues each.

## Pages and executors

- **Weekend page** = a dated page (`Nov 8`, `Dec 7`), copied from the base, songs on the song
  row in service order. In 2025 the song row was 111–114 with Walk In / Message on 104–107; in
  late 2026 it is 106–109 (110 for a fifth) with Walk In 104, Message 105. The rest of the
  page is fixed: Clear Layers, Shuffle macros, Key group, Spot, Main House 216, R - Walk In
  218, Resolume/Transition masters 221–222, Banner Black Out 223, Portman presets 226–227,
  speed/Lowlight/Highlight masters 231–235, R - Douse 294, `@ 0` macro 298, R - Walk In /
  Message / Song 1–4 on 304–309, Clear Layers + haze 401–404.
- **Production page** (`Christmas 1–4`) = one page per act/segment: 101 the segment's
  Walk In / Welcome / Message sequence, 105 a follow-spot helper, 106–110 songs in run order,
  111–115 their Key twins, 191–194 Douse + Clear Layers, 301–305 one-shot hits (`ROTB - Era
  HIT 1–3`, `R - Welcome`), 306–310 `R - Song n`, 401–406 strobe/effect sequences also driven
  by timecode, 408–409 `Sp` sequences, 412 a key for the speaker. The last song of a page is
  repeated as the first song of the next page so he can run the transition from the last song
  into the next one and flip pages afterward, never during a transition (Aaron, 2026-11-04).
- **Executor look for songs:** two rows tall, key Off, fader Master, lower half key Select.
  Single-row utility executors: Temp for clears and Resolume one-shots, Toggle for spots /
  douse / banner, Go+ for Main House and macros, Speed1 for speed masters, Black for Resolume
  master.
- **Fixed pages:** 1 Busking Base (legacy), 2 Weekend Base (copy source), 15 Relays, 16 X Keys,
  17 Utility (every R - sequence, pager, `Sp`), 30/31 Remote 1/2 (cue lights: Back Stage,
  Speaker, Usher / Doors, FOH Call, Lighting Call). A `Follow Testing` scratch page may exist.

## Groups

- Hundreds by family: 1xx Era, 2xx R1 / screens, 3xx Fuze + audience, 4xx Portman, 5xx Q40
  (band/bell sections), 6xx Infinibars (2025) / Tornado (2026), 7xx Key, 8xx LED (ladders,
  platforms, blinders, tutu, crop), 9xx Resolume fixtures + catwalk/house, 10xx house, 1100
  relays, 22xx Resolume layer/song/clear groups, 23xx single-fixture groups.
- The master group of a family sits on the hundred (`100 Era`, `200 Stage R1`, `400 Portman
  Dimmer`, `800 Ladders`, `1000 Main House`), Red 1 appearance on the two moving-light
  masters. Sub-groups follow: halves (`Half Era`, `Half R1`), sections (`Band Sections`,
  `Bell Sections`, `Ring Sections`), directions (`Left -> Right`, `Center -> OUT`, `Inside ->
  Outside`), mapped/grid variants for pixel work (`Infinibars Mapped` 96 wide, `Ladders
  Mapped` 12 × 50, `Platforms Mapped` 8 × 34, `Ladders Vertical`), and one group per ladder
  (`Ladder 1–12`). Grid order inside a group is deliberate (fan-outs run x across the rig).
- Resolume is driven as fixtures: groups `2201 Resolume Master`, `2202 Transition Master`,
  `2208 Resolume Side to Side`, `2222–2237 Song 1–16`, `2252–2258 Sp1–7`, `2270–2273 Walk In /
  Welcome / Message / Douse`, `2279–2289 Banner Black Out, Clear Layer 1–5, Layer 3–5 Master`.

## Presets

- One global pool (`Preset 21 Presets`) numbered like the groups: 1xx Era, 2xx R1, 3xx
  audience/screen/R2, 4xx Portman, 5xx people and positions for a production (`Margot`, `Ish`,
  `Dancers`, `Drummers`), 6xx specials, 7xx key light (`Worship`, `Message`, `<date> Key`,
  `Band`, `Key Home CMY/CTC`).
- Each moving-light family gets the same ladder: `Home`, `Full`, `Tight`, `Mid`, `Wide`,
  `Out 1–3`, plus a stage-position preset (`Era Half Stage`, `R1 House Stage`). Colour-coded:
  Home Red 3, Full Orange 3, zooms Blue 2, Outs Green 2.
- `Preset 22 Phaser`: generic dim/snap/circle/tilt phasers 100–107, per-family phasers 200+.
- `Preset 25 Busking`: house levels 1–4 (100/50/15/0 %), blinder levels 10–12, Portman shapes
  20–23 (`X`, `Y`, `I`, `-`). These sit on executors (226–227) for live use.

## Macros

- Rig state: `RELAYS ON/OFF` park Group 1100 at 100/0; `Everything Off` = Off RunningSequence
  + Off Running Timecode.
- Programmer keys on executors: `@ 0`, `Store`, `Clear`, `Undo` (Oops), `Delete`.
- Busking helpers: `Load Home / Zoom Wide / Dimmer Sin / Tilt Sin` load matching cues in the
  Era (5xx) and R1 (6xx) effect sequences together; `Busking Off` offs 500–960 by tens;
  `Stop Phasers` loads Cue 100 (the STOMP cue) of each phaser sequence.
- `Shuffle 1–4` = MAtricks 16–19 (XSHUFFLE 1..4 only). `R1 Mirror` MAtricks = XGROUP 2,
  XWINGS 2.
- Cue lights: `Speaker Cue 1/2`, `Back Stage Cue 1/2`, `Ushers Off / Cue 2 / Cue 3` = Goto on
  the Remote page sequences.

## Effect / busking sequences (171–1009 range)

House looks 171–174 (Appearance Orange 1), `Walk In` 177, `Message` 178 (first cue is a
preset stack `[Message/Era Half Stage/R1 House Stage]`), Resolume control `R - ...` 204–252,
remote/cue-light 306–310, sizing helpers 312–321 (`100`…`600`, `Net`, `Tutu`, `Upper`). Phaser
"menus" per family: 501–507 Era (Position, Gobo / Focus, Zoom, Dim, Tilt / Pan), 600–603 R1,
700/702 Q40, 800–802 Portman, 950 Color. Each menu's cues are named looks (`Era Home`, `Gobo
Lines`, `Shuffled Dimmer`, `R1 Dimmer Shuffle`) and the last cue is the `STOMP` / `STOP`.

## Visual language

- Appearances: one 3-shade palette (`<Colour> 1/2/3` for Blue, Green, Purple, Red, Orange,
  Yellow; 18 White, 70 Grey, 71 Blank). Red = masters, Green = Resolume, Orange = house /
  key, Blue = zoom presets.
- Views: Playback, Busking, Groups, Fixtures, Spot, Timecode Editor, Video, Resolume, Masters,
  Color, Layouts, 3D, plus `Sequence Library A/B/C` for the song pools. Layouts: Portmans,
  House Dimmers, Boxes, Key, Extras. Worlds: Full, Cue Lights.

## Naming

Title Case song names copied from Planning Center (the console strips commas). Short labels
elsewhere (`Sp 1`, `R - Song 3`, `Clear Layer 2`, `Q40 Dim`). `R - ` prefix = Resolume
control. `(Key)` suffix = key-light twin. Nicknames and jokes are fine in cue names; object
names stay clean.
