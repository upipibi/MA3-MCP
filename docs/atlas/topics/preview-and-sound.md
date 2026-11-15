# Preview and sound: what we know, how sure we are, how to do the work

Written 2026-11-08 from the MA help 2.5 (chapters "Preview" 1 page and "Sound" 3 pages), MA's preview
and sound tests, and the release notes 2.4 (preview introduced). Study packs: `pack.py "Preview"
--terms preview`, `pack.py "Sound" --terms sound`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Preview [D]

- Run objects without changing the stage: the programmer is isolated from output. **Enabled for every
  user sharing the user profile**: in a session, someone who wants to preview alone needs their own
  profile.
- `Prvw` + tap a sequence, or `Prvw Sequ 1 Cue 5 Please`; hold Prvw + tap to add or remove objects;
  `Prvw Off Sequ 2`; double Prvw switches live / preview; Prvw + Off leaves. Coloured binoculars mark
  the primary previewed object, white the others. Previewing a running sequence starts on its running
  cue.
- **Storing or updating in preview writes the live show** (and can change the stage through tracking).
- Windows with a red frame follow preview: 3D Viewer (Follow Preview, on by default), DMX Sheet (Follow
  Preview, off by default), fixture, content and sequence sheets, layout viewer, masters, MAtricks,
  phaser and recipe editors, Off menu, Running Playbacks, selection grid and bar, sMArt, Special
  Dialog, Step Bar. Highlight, Lowlight and Solo in preview stay in preview; the master section is live
  only.
- Preview uses **Data Pool 128**. Encoder bar (orange): preparation bar with Transfer Selection /
  Transfer Programmer; in preview Object, Cue, `<<<`, Pause, `>>>`, Go-, Toggle, Go+, AutoStart (Off,
  Single, Multi), Copy Selection, Copy Programmer, Copy Playbacks.
- One preview programmer in the whole session (users can overwrite each other) [D: programmer page].

## Sound [D]

- Audio in (console or onPC device) drives phasers and cue triggers; Sound Viewer modes **Wave** (VU,
  raw waveform, Sound In master), **Sound** (11 bars = channels All, Bass, Mid, High, Band1-7 and the
  inverse channels; Sound Fade master), **Beat** (beat candidates; the BPM speed master 16 locks on).
  Attributes follow a channel with `SoundChannel` or the calculator's Sound Codes. Cues can trigger on
  Sound (one of 22 bands) or BPM [D: cues].
- Sounds pool (media): files in `gma3_library/media/sounds`, **100 MB for sounds, 300 MB for all media
  pools**; play with Go+, Off, Toggle, Pause; add to timecode tracks (waveform shown, plays with the
  show).

## Plugin access today, and gaps

- Neither is used in Aaron's shows today [C]. Preview would be the safe way for a future plugin job to
  rehearse playback without touching the stage [?].
