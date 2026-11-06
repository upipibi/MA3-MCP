# Timecode shows for every song (2026-11-05)

Aaron: "Can you also create the timecodes for each of the PCO and Christmas songs, with similar
organization in the pool".

The Timecode pool was empty. Built 28 timecode shows, each at the same pool number and with the same
name as its song sequence: `Timecode 1-13` for the Planning Center songs (`One True God` ..
`King Of Kings/Angels We Have Heard on High`) and `Timecode 54-68` for the Christmas songs
(`Rocking Around the Christmas Tree` .. `Joyful Joyful (Pentatonix)`). `Sequence 53` (an unnamed
placeholder) and the `(key)` twins 72-86 got no timecode show of their own.

Each show has the structure of last year's (`docs/research/shows/christmas-2025.md`, "Timecode"):
`TrackGroup 1` with the marker track and one track that targets the song sequence, holding one empty
time range. No events: placing or recording them is Aaron's. The key twin has no track, as last
year (the key ran by hand on its own executor); the console adds a track when he records one.

Settings were not touched. A new timecode show on this console already comes up as slot 1,
`S1<30 fps>` readout, offset `1h00m00:00`, the same as last year's Timecode 1. Every show has the
same 1 hour offset; if the songs sit at different hours on the timecode source, that is his to set
(`OFFSETTCSLOT`).

Backup `Christmas 2026_mcp_1105_2359`; 58 commands in undo group `song timecodes` (closed). Read
back: pool holds exactly 1-13 and 54-68, names equal the sequence names, each show has one track
with target `Sequence <n>` and one time range. The job did not save the show.

Syntax proven on 2.5.1.1:

- `Store Timecode <n> "<name>"` creates an empty show (no track group).
- `Assign Sequence <n> At Timecode <n>.1.1` on that empty show creates `TrackGroup 1`, its marker
  track (`.1.0`) and track `.1.1` with the sequence as `TARGET` and one `TimeRange`. The track is
  named `<sequence name>` in angle brackets by the console.
- `Store Timecode <n>.1.1` (storing the track first) makes a track with TWO time ranges; the spare
  one goes with `Delete Timecode <n>.1.1.2`. Use the Assign form alone.
