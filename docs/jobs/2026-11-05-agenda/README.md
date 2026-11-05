# Agenda entries for Christmas 2026 (2026-11-05)

Aaron pasted the production schedule and asked for it in the MA Agenda. Show `Christmas 2026`,
backup `Christmas 2026_mcp_1105_2213`. Added `Agenda 14` to `Agenda 28` (15 entries; the list, `entries.json`, is local only); the 13 old entries from 2022 (`Agenda 1-13`, all expired 01.01.2023) were left alone.
Each entry is a point in time with no command, no repeat, enabled, like his old ones; the time
range lives in the name because an agenda event has a start but no duration.

My calls: one entry per show night instead of a repeating one; weekday in the names (the console
forces unique names and had appended `#2`...`#5`); a day with two shows as one entry at the first
start time; an entry with no end time where none was given; the gear pickup as its own entry.
Undo: group `agenda-christmas-2026` (45 commands) and `agenda-christmas-2026-names` (12 labels).
The job did not save the show.

Syntax proven on 2.5.1.1: `Store Agenda <n> "<name>"`, `Set Agenda <n> Property "StartDate"
"DD.MM.YYYY"`, `Set Agenda <n> Property "StartTime" "HH:MM:SS"`, `Label Agenda <n> "<name>"`. A new
event defaults to no repeat, enabled, Absolute, empty command. `COUNTDOWN` reads "in N days".
