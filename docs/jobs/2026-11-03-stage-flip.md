# Job: stage flip + November pages, 2026-11-03

Show: `Christmas 2026` (console 2.5.1.1, plugin 0.1.0, Lua off). Undo group: `stage-flip-2026-11-03`.
Status: DONE 2026-11-03 (Aaron said go). Backup: `Christmas 2026_mcp_1103_2358` (6.7 MB, saved before
the first write). Results at the end of this file.

Before go: put the console on a page that this job does not delete or rebuild (Page 15, 16 or 17).
Pages 2 and 5–8 are deleted during the job.

## Part 1: what is in Sequence 1–89 today (read live 2026-11-03)

| Seq | Name | Cues | Assigned on |
| --- | --- | --- | --- |
| 1 | Thank The Lord | 25 | Sept 13 exec 106 |
| 2 | Highest Praise | 28 | Sept 13 exec 108 |
| 3 | Who Else | 22 | nowhere |
| 4 | Gratitude + Great Are You Lord | 23 | Sept 27 exec 109 |
| 5 | One True God | 23 | Sept 6 exec 106 |
| 6 | Weight of Glory | 20 | Sept 6 exec 107 |
| 7 | WayMaker | 23 | Sept 6 exec 108 |
| 8 | Goodness Of God | 17 | Sept 6 exec 109 |
| 9 | Mighty Name of Jesus | 15 | Sept 13 exec 107 |
| 10 | What a Father What a Friend | 17 | Sept 13 exec 109 |
| 11 | The Joy | 31 | Sept 20 exec 106 |
| 12 | We Praise You | 20 | Sept 20 exec 107 |
| 13 | Father of Lights | 16 | Sept 20 exec 108 |
| 14 | Living Hope | 20 | Sept 20 exec 109 |
| 15 | Be Glad | 33 | Sept 27 exec 106 |
| 16 | This Is Our God | 25 | Sept 27 exec 107 |
| 17 | I've Witnessed It | 28 | Sept 27 exec 108 |
| 18 | Sequence 18 (placeholder, not a song) | 1 | Sept 6 exec 210 |
| 80 | Worship Key (helper, not a song) | 1 | nowhere |
| 81 | Message Key (helper, not a song) | 1 | nowhere |
| 89 | Sequence 89 (placeholder, not a song) | 1 | nowhere |

17 songs and 4 non-song helpers. Nothing else exists between 1 and 89. Aaron asked for 1–89, so
the helpers go too unless he says otherwise. Four Nov 29 songs return from this list (Thank The
Lord, This Is Our God) or from earlier pools; they are recreated empty and reprogrammed by Aaron.

## Part 2: songs from Planning Center

Sunday Service (type 6401), November plans. Songs = items PCO types `song`, in plan order.

| Weekend | Plan | Songs (service order) | Sequences |
| --- | --- | --- | --- |
| Nov 8 | 90657843 | One True God, Highest Praise, I Speak Jesus, What A Beautiful Name, Goodness Of God | 1–5 |
| Nov 15 | 90657844 | Praise, Weight of Glory, Abide, Thank You Jesus | 6–9 |
| Nov 22 | 90657845 | none yet (plan holds a 22-minute `Worship` placeholder item) | none |
| Nov 29 | 91338104 | Thank The Lord, This Is Our God, Manger to the Cross, King Of Kings/Angels We Have Heard on High | 10–13 |

CHRISTMAS PRODUCTIONS (type 278341), plan 89767897, Dec 14–22, 15 songs in show order:
Rocking Around the Christmas Tree, He Is, What Christmas Means to Me, Hark The Herald Angels Sing
(Hillsong), The Present, Why We Sing Noel, Christmas Everyday, Carol of the Bells, This Is My
Wish/Let There Be Peace on Earth, Little Drummer Boy (What Can I Give), The One We've Waited For
(God Rest Ye Merry Gentlemen), King Of The World, Come and See, Before The King, Joyful, Joyful
(Pentatonix). Non-song items skipped: Overture, Welcome, Message, Prayer and Yes Packets.

## Part 3: pages today and the Weekend Base gap

Pages 5–8 (Sept 6, 13, 20, 27) share one layout. Weekend Base (Page 2) is behind it:

| Executor | Sept pages (all four) | Weekend Base today |
| --- | --- | --- |
| 104 / 105 | Walk In / Message | at 101 / 102 instead |
| 106–109 | the weekend's songs (height 2, key Off, fader Master) | absent |
| 201 Key (Group 700), 202 Spot (Seq 183) | present | absent |
| 304 / 305 R - Walk In / R - Message | present | at 301 / 302 instead |
| 401–404 Clear Layer 1–3, Right DF 50 Haze | present | absent |
| 291 | absent | stale empty executor shell |

Only on Sept 27 (the newest page): 203 Spot 2 (Seq 184), 409 Sp 1 (Seq 221). Only on Sept 6:
210 Sequence 18 (deleted with the song pool). Everything else (191–198, 216, 218, 221–227,
231–235, 294, 298, 306–309) matches.

Decision taken: the new Weekend Base is a copy of Sept 27 with the four songs removed, so it
includes Spot 2 and Sp 1. Each November page is then a copy of the new Weekend Base.

## Commands, in order (all with undo group `stage-flip-2026-11-03`)

### A. Delete the song pool

1. `Delete Sequence 1 Thru 89` (Thru on Sequence is safe; the Page/Executor hazard does not apply)

### B. Create the weekend song sequences (empty; Aaron programs the cues)

2. `Store Sequence 1 "One True God"`
3. `Store Sequence 2 "Highest Praise"`
4. `Store Sequence 3 "I Speak Jesus"`
5. `Store Sequence 4 "What A Beautiful Name"`
6. `Store Sequence 5 "Goodness Of God"`
7. `Store Sequence 6 "Praise"`
8. `Store Sequence 7 "Weight of Glory"`
9. `Store Sequence 8 "Abide"`
10. `Store Sequence 9 "Thank You Jesus"`
11. `Store Sequence 10 "Thank The Lord"`
12. `Store Sequence 11 "This Is Our God"`
13. `Store Sequence 12 "Manger to the Cross"`
14. `Store Sequence 13 "King Of Kings/Angels We Have Heard on High"`

### C. Create the Christmas show sequences

15. `Store Sequence 54 "Rocking Around the Christmas Tree"`
16. `Store Sequence 55 "He Is"`
17. `Store Sequence 56 "What Christmas Means to Me"`
18. `Store Sequence 57 "Hark The Herald Angels Sing (Hillsong)"`
19. `Store Sequence 58 "The Present"`
20. `Store Sequence 59 "Why We Sing Noel"`
21. `Store Sequence 60 "Christmas Everyday"`
22. `Store Sequence 61 "Carol of the Bells"`
23. `Store Sequence 62 "This Is My Wish/Let There Be Peace on Earth"`
24. `Store Sequence 63 "Little Drummer Boy (What Can I Give)"`
25. `Store Sequence 64 "The One We've Waited For (God Rest Ye Merry Gentlemen)"`
26. `Store Sequence 65 "King Of The World"`
27. `Store Sequence 66 "Come and See"`
28. `Store Sequence 67 "Before The King"`
29. `Store Sequence 68 "Joyful, Joyful (Pentatonix)"`

### D. Create the Christmas key duplicates (one pool row up: 54 + 18 = 72)

30. `Store Sequence 72 "Rocking Around the Christmas Tree (key)"`
31. `Store Sequence 73 "He Is (key)"`
32. `Store Sequence 74 "What Christmas Means to Me (key)"`
33. `Store Sequence 75 "Hark The Herald Angels Sing (Hillsong) (key)"`
34. `Store Sequence 76 "The Present (key)"`
35. `Store Sequence 77 "Why We Sing Noel (key)"`
36. `Store Sequence 78 "Christmas Everyday (key)"`
37. `Store Sequence 79 "Carol of the Bells (key)"`
38. `Store Sequence 80 "This Is My Wish/Let There Be Peace on Earth (key)"`
39. `Store Sequence 81 "Little Drummer Boy (What Can I Give) (key)"`
40. `Store Sequence 82 "The One We've Waited For (God Rest Ye Merry Gentlemen) (key)"`
41. `Store Sequence 83 "King Of The World (key)"`
42. `Store Sequence 84 "Come and See (key)"`
43. `Store Sequence 85 "Before The King (key)"`
44. `Store Sequence 86 "Joyful, Joyful (Pentatonix) (key)"`

Checkpoint: re-read Sequence 1–89. Any sequence whose name did not take gets
`Label Sequence <n> "<name>"` in the same group (the manual confirms Store on an empty
programmer creates an empty object; the quoted name on Store is the convention in CONVENTIONS.md).

### E. Rebuild Weekend Base from Sept 27

45. `Delete Page 2`
46. `Copy Page 8 At Page 2`
47. `Label Page 2 "Weekend Base"`
48. `Delete Page 2.106`
49. `Delete Page 2.107`
50. `Delete Page 2.108`
51. `Delete Page 2.109`

(Per the manual, Delete on an executor removes only the assignment, never the object. After step 1
these four executors are already empty of sequences; steps 48–51 clear any leftover shell so the
base has no stale song slots. "Object not found" on any of them is fine.)

Checkpoint: read Page 2. Expected: Sept 27 layout, nothing at 106–109.

### F. Delete the September pages

52. `Delete Page 5`
53. `Delete Page 6`
54. `Delete Page 7`
55. `Delete Page 8`

(No Thru on Page: one command each.)

### G. Build the November pages

Nov 8 (Page 4):
56. `Copy Page 2 At Page 4`
57. `Label Page 4 "Nov 8"`
58. `Assign Sequence 1 At Page 4.106`
59. `Assign Sequence 2 At Page 4.107`
60. `Assign Sequence 3 At Page 4.108`
61. `Assign Sequence 4 At Page 4.109`
62. `Assign Sequence 5 At Page 4.110` (fifth song: executor 110, per CONVENTIONS.md)

Nov 15 (Page 5):
63. `Copy Page 2 At Page 5`
64. `Label Page 5 "Nov 15"`
65. `Assign Sequence 6 At Page 5.106`
66. `Assign Sequence 7 At Page 5.107`
67. `Assign Sequence 8 At Page 5.108`
68. `Assign Sequence 9 At Page 5.109`

Nov 22 (Page 6), no songs in PCO yet:
69. `Copy Page 2 At Page 6`
70. `Label Page 6 "Nov 22"`

Nov 29 (Page 7):
71. `Copy Page 2 At Page 7`
72. `Label Page 7 "Nov 29"`
73. `Assign Sequence 10 At Page 7.106`
74. `Assign Sequence 11 At Page 7.107`
75. `Assign Sequence 12 At Page 7.108`
76. `Assign Sequence 13 At Page 7.109`

### H. Match the song executors to Aaron's layout

A freshly assigned executor gets the console's defaults. For each of the 13 song executors
(4.106–4.110, 5.106–5.109, 7.106–7.109), read it and set what differs with `ma3_set`:
`HEIGHT` = 2, `KEYPRESS` = `Off`, `FADER` = `Master` (the values every song executor on the Sept
pages has). No change where the value already matches.

### I. Close

77. `ma3_undo_close stage-flip-2026-11-03`

Verify: `ma3_sequences 1–89` (41 sequences, names as above, 1 cue each), `ma3_pages` (pages 1, 2,
4–7, 15, 16, 17, 30, 31; no 5–8 September pages; 2 has no songs; 4–7 as planned). Then update
`docs/CONVENTIONS.md`: pages 4–7 are the current run, Weekend Base is current and is the copy
source, song pool renumbered from 1, Christmas rows at 54–68 and 72–86.

## Not done by this job (say the word)

- `R - Song 5` (Sequence 242) at executor 310 for Nov 8's fifth song. The Sept pages carry only
  R - Song 1–4; Utility (Page 17) has 1–15.
- Nov 22 songs: none in PCO yet. Re-run the weekly job once the plan has songs.
- Cues: none created. All 41 new sequences are empty.

## Results (verified by re-reading sequences and pages after the run)

- 77 planned commands sent, all `OK` except steps 48–51 (`Object not found`: the song executor
  shells on the copied page vanished with their sequences, so there was nothing to clear).
- 41 sequences exist in 1–89, 1 empty cue each, names as planned with one exception: the console
  strips commas from object names, so 68 and 86 read `Joyful Joyful (Pentatonix)` and
  `Joyful Joyful (Pentatonix) (key)`. Tried Store, Label and the NAME property; all three drop it.
- Pages: 1 Busking Base, 2 Weekend Base (Sept 27 layout, no songs), 4 Nov 8 (songs on 106–110),
  5 Nov 15 (106–109), 6 Nov 22 (no songs), 7 Nov 29 (106–109), then 15, 16, 17, 30, 31 untouched.
  Sept 6–27 are gone.
- Step H was needed: a fresh executor arrives height 1, key Temp, fader Master. Set HEIGHT 2 and
  KEYPRESS Off on all 13. Their lower halves (2xx, class Proxy) arrive with no key or fader; set
  KEYPRESS Select and FADER Master on all 13 to match the September pages.
- Undo: the command-line steps sit in undo group `stage-flip-2026-11-03` (closed). The property
  writes through `ma3_set` are not in the group; an Oops reverts the commands and the pages, and the
  property writes go with the pages.
- Not saved to disk after the run. The backup holds the pre-job show.
