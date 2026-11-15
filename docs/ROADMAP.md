# Roadmap: to the heart of the console

**Written:** 2026-11-07, from Aaron's brief. **Status:** draft for his approval.
**Owner of the work:** Claude, in sessions with Aaron. **Owner of the goal:** Aaron.

> "I want you to have access, control, and insight to every single bit of this console. I want
> you to know it better than me, use it better than me, have access deeper than I do. We've only
> scratched the surface. A plan that keeps you trying, digging, and researching even after you
> think you've found the answer. When we think we've got all we can, we keep looking."

> **2026-11-08, read first:** an unasked read job (a class census) froze the console's screen during
> a Sunday service. Aaron: "We can NOT allow the MCP plugin to behave in a way that allows it to
> crash the console." Every program below now runs its exploration **on onPC only**; the console is
> touched only for Aaron's jobs and only through proven-safe objects (plugin console guard, alpha.6;
> rules in `CLAUDE.md`, "Console safety"). Where this plan says "census", "probe" or "bench", it
> means onPC.

This document is the standing plan for the MA3 MCP project. It is a living file: every session
that moves it forward updates the ledgers at the bottom. Nothing here is a promise about calendar
time; sizes are given in sessions, with what Aaron tests between them.

---

## 1. What "the heart of the console" means, measurably

Three capabilities, each with a test that says when it is reached.

| Capability | Reached when |
| --- | --- |
| **Insight** (know it better) | Every object class reachable from `Root()` is in the atlas with its properties, types and meaning; every Lua function the console exports is tried and classified; every console fact we rely on carries evidence and a date; Aaron's programming style and conventions are written down well enough that a cold session builds a correct page or song skeleton from them alone. |
| **Access** (reach deeper) | Everything the desk shows an operator can be read by a tool without a screen: show data, live playback and fade progress, programmer, DMX output, selection, masters, timecode, session and hardware state, messages. Everything an operator can change has a tool that changes it with a backup, an undo group and a read-back check. |
| **Control** (use it better) | A job Aaron describes in a sentence is done, verified and reported without him at the desk; a song is programmed in his style from a Planning Center plan and a timecode skeleton; a show is monitored live for errors; the plugin runs as its own user so it never shares his command line. |

Two boundaries that never move:

- **Never hang or endanger the desk.** No `Thru`, `+`, `*` on Page/Executor addresses; no blocking
  calls; no command that opens a dialog without `/NoConfirmation`; time-sliced work only; every
  write preceded by `ma3_backup`, grouped in one undo, verified by a fresh read.
- **Production freeze.** From the first line check of a production (Christmas 2026: Tuesday
  2026-12-08) to its last show (2026-12-22), the console gets reads and Aaron-requested jobs only:
  no plugin updates, no experiments, no new write tools. Experiments move to the onPC bench.

---

## 2. Where we are (2026-11-07)

- Plugin 0.2.0-alpha.5 built: PIN survives imports, Lua on by default, time-sliced reads. alpha.4
  on the console, verified. 23 tools: status, generic object reads, bulk reads, deep reads (cue
  timing, timecode, history, export), commands with undo groups, set, backup, save, Lua.
- Proven real work on a grandMA3 light: stage flip, five layout jobs, group build, agenda, 28
  timecode shows. Cue Display 2.1.0 (grid view) runs on the console.
- Knowledge: `docs/research/2026-11-onpc-facts.md` (console facts with evidence),
  `docs/CONVENTIONS.md` (how the show is organised), `docs/PROGRAMMING-STYLE.md` (how Aaron
  programs, from two show files), per-show digests (local).
- Known gaps: no live-state reads (programmer, output, fade progress), no programming helpers,
  no message access, no second user, no autonomous onPC bench, fixture-type writes only while the
  Patch menu is open, `ma3_history` without command text, `ma3_set` outside undo groups.

What the other projects teach (ideas, not code; one is AGPL):

- bdstark/gma3-mcp: report **command outcome and read-back verification separately**; refuse to
  store **unrequested content** in presets; build phasers in the **Preview** environment; a
  **cheatsheet resource** and **manual search** from the console's own help files; **owned input
  sessions** that lock other clients out while keys are pressed; a read-only **feedback** tool
  (masters, page, selection, fader levels, activity) that works without Lua.
- Pahegi/ma3-mcp: small, obvious helpers (`select`, `set_attribute`, `store_cue`, `playback`,
  `executor_fader`); **OSC to reload a plugin** on onPC, which is the key to a hands-free bench.

---

## 3. The method: how we keep digging

This is the part Aaron asked for by name. It applies to every question, every session.

### 3.1 The digging protocol

For any question about the console ("can a plugin read X", "what does property Y mean", "does
command Z hang"):

1. **Docs.** MA's help for the running version (keyword pages, Lua pages, release notes).
2. **Census.** Our own API and object atlas (section 4.1). If the answer is not there, the atlas
   has a hole: fill it, do not work around it.
3. **Bench.** Probe on onPC on this Mac, through the plugin itself (never keystrokes).
4. **Desk, read-only.** Confirm on the console with reads. Writes only in a disposable scratch
   object, with backup and undo, outside production freeze.
5. **Community.** MA forum, the other MCP projects, plugin collections. Evidence only; licences
   respected.
6. **Record.** The answer, the evidence, the date and the software version go into the facts
   file. An unanswered question goes into the unknowns ledger with the next approach to try.

### 3.2 Rules that keep us honest

- **A negative needs a second method.** "It can't be done" is recorded only after two different
  approaches failed (for instance: object tree AND Lua function AND file on disk). The Message
  Center answer today is "not through the object tree"; it is not yet "not at all".
- **A positive needs the desk.** Something that works on onPC is "proven onPC" until the console
  says so. The grid view's first build is why: it ran perfectly on a fake and on onPC-like
  assumptions and died on the desk.
- **Every fact carries evidence and a date.** Facts file lines read "measured", "documented", or
  "inferred", with the version. Inferred facts are re-tested when they start to matter.
- **Found the answer? Look once more.** When a probe answers a question, the next step is one
  more probe that would *break* the answer: a second object of the class, a second show, a
  restart, a different user. Only then is it recorded.
- **Re-probe after every MA update.** A software update re-opens every "measured" fact that the
  update's release notes touch, and a sample of the rest.
- **Hands off the keyboard.** The bench is driven through the plugin and OSC, never by sending
  keystrokes or mouse events to onPC on Aaron's Mac.
- **The console is never a bench.** No census, walk, probe or looping read runs against the
  console, at any hour. Unknown objects, classes, properties and commands are explored on onPC, and
  reach the console only after they are proven there and added to the plugin's allow-list.
  (2026-11-08: one census read froze the console mid-service.)

### 3.3 Session rhythm

Each working session: start from "Resume here" in `CLAUDE.md`, open the unknowns ledger, pick
work from the current phase, finish with the ledgers updated and `/save`. Research sessions have
one question each and end with a facts-file entry, even when the answer is "not yet".

---

## 4. Programs of work

Six programs run in parallel at different weights. Phases (section 5) say what order they land in.

### 4.1 Atlas: know every object, function, keyword

- **Function census.** `HelpLua` exports the console's full Lua function list; read it, call
  every function that is safe to call with no arguments or with read-only arguments, record what
  it returns. Classify: read / write / UI / dangerous / unknown.
- **Object atlas.** A tool (`ma3_atlas`, read-only) walks `Root()` to a depth, recording every
  class, its property names and types (`PropertyType`), child classes, counts, and one sample
  value. Written to a file the session reads, then distilled into `docs/research/atlas/<class>.md`
  with what each property means, learned by changing something on the desk and watching the
  property move.
- **Keyword census.** `GetTokenName`/`GetTokenNameByIndex` enumerate command-line keywords;
  cross-check with MA's keyword pages; mark the ones we know hang or open dialogs.
- **Enums.** Dump `Enums` (path types, content types, everything).
- **Hooks.** For each promising object (RunningSequences, MessageCenter, Programmer, Selection,
  Executors): does `HookObjectChange` fire for a plugin, with and without its window open?
- **Files.** What the console writes to disk and where (show files, logs, `message_center.dat`,
  settings, backups); which are readable from a plugin; which are parseable.
- **UI model.** Displays, windows, `UIChildren`, what a window exposes (the Message Center
  window, the command line, the System Monitor), and what `GetScreenContent` returns.

### 4.2 Live state: read what the desk is doing

Tools, in order of value to Aaron's actual work:

- `ma3_playbacks`: every running sequence with current cue, next cue, fade progress and timing
  state, speed and rate masters, from `Root().Temp.RunningSequences` or the executors.
- `ma3_programmer`: what is in the programmer (fixtures, attributes, values, as the Programmer
  window shows them), using `Programmer()`, `GetUIChannels`, `GetRTChannels`.
- `ma3_output`: DMX output per universe or per fixture (`GetDMXUniverse`, `GetDMXValue`),
  and the fixture's output values as the console computes them.
- `ma3_selection`, `ma3_masters`, `ma3_session` (users, stations, cmdlines, who owns what),
  `ma3_hardware` (battery, temperatures, fans if readable), `ma3_timecode_live` (slots rolling).
- `ma3_messages`: the Message Center, by whichever route the atlas proves (window scrape, hook,
  file). Until then, both plugins log their own errors where `ma3_status` can read them.
- A `watch` mode: subscribe-like polling for a short window, returning a timeline (cues fired,
  messages, timecode), so a session can "watch" a run-through.

### 4.3 Programming: do the work, not just the housekeeping

Every write tool follows one pattern, taken from the strongest of the other projects:
**plan → backup → one undo group → command(s) → read back → report outcome and verification
separately**. A tool never claims success it did not read back.

- Level 1, thin helpers over commands: `select` (fixtures, groups, ranges), `set_attribute`
  (attribute, value, with the console's attribute names), `set_color`, `set_position`,
  `store_cue` (number, name, timing, parts), `label`, `cue_timing`, `cue_trigger`,
  `assign_executor` (with Aaron's executor layout rules), `executor_fader`, `go`/`off`/`top`,
  `store_preset` (mode, scope; refusing unrequested content), `store_group` (with grid),
  `matricks`.
- Level 2, Aaron's shapes: `new_weekend_page` (copy Weekend Base, assign songs in service order,
  set executor looks), `new_song_skeleton` (empty song sequence named from Planning Center, Start
  cue in his style, key twin, timecode show with track), `effect_sequence` from his templates.
- Level 3, blind first: programming happens in the **Preview** environment or on a scratch
  sequence until a read-back matches the plan, then is copied live. Phasers and recipes come
  here, built from structured steps.
- Level 4, from his own programming: a song sequence generated from his past songs of the same
  feel (the "future idea" in CONVENTIONS), always presented as a plan first.

### 4.4 Presence: act like a second operator, not a hand on his keyboard

- **Own user.** A dedicated MA user and profile for the plugin, so its commands run on its own
  command line and its selections never touch his (open item since 2026-11-05; needs the session
  atlas first: `Root 20.1` cmdlines, user objects, how a plugin's `Cmd` chooses its line).
- **Own screens, none.** The plugin never changes his views; the overlay stays the only UI.
- **Owned input, later.** If a job ever needs real key presses (some dialogs), the owned-session
  pattern: declared, exclusive, released, never silent.

### 4.5 Show intelligence: know his show better than he remembers it

- Digest after every save: what changed since the last digest (sequences, cues, pages, groups,
  presets), in a report he can skim. Diff tools over exports.
- Style file kept current from his new programming, not only from two old shows.
- Planning Center joined to the show: which songs are programmed, which are missing, what the
  weekend page needs, what Sunday's service order implies.
- Pre-show check: a read-only report before a service (pages assigned, sequences present,
  timecode shows valid, masters at expected levels, messages since last check).

### 4.6 Engineering: the plugin that carries all of this

- **Bench without hands.** onPC on this Mac driven by the plugin (HTTP) and by OSC for reload
  and plugin start, so builds are tested end to end before the stick. The fake console gains
  fidelity from every desk surprise (it already starts dirty and charges for yields).
- **Reliability.** Time-sliced work (done), budgets everywhere, no partial without progress
  (done), request size caps, per-tool timing in `ma3_status`.
- **Security.** PIN as the key (persistence fixed in alpha.5), lockout that counts only guesses,
  `;` chaining check on command refusals, Lua sandbox kept, a security review before each release.
- **Observability.** Plugin log readable (`ma3_status {log:true}`, done), Cue Display errors
  readable, settings path logged, a `ma3_selftest` that runs the known-safe probes and reports.
- **Releases.** Pre-releases while alpha; 0.3.0 when live-state reads land; 1.0 when programming
  level 1 and the own-user mode are proven on the desk through one production.

---

## 5. Phases and milestones

Sizes are in working sessions (one session: a few hours with Aaron reachable). Between phases
Aaron tests on the desk; the production freeze (2026-12-08 to 2026-12-22) falls after phase 1.

| Phase | Lands | Sessions | Aaron tests |
| --- | --- | --- | --- |
| **0. Now** | alpha.5 on the desk; Cue Display grid checked with timecode and a song (Sunday 2026-11-08); `/save` and releases. | this week | imports alpha.5; rolls timecode; runs a song |
| **1. Atlas + bench** | `HelpLua` census, `ma3_atlas` tool and first atlas pages, Enums dump, keyword census, hook probes, Message Center route decided; onPC bench driven by plugin + OSC; unknowns ledger live. | 3 to 4 | nothing on the desk beyond reads; confirms the onPC bench may use OSC |
| **2. Live state** | `ma3_playbacks`, `ma3_programmer`, `ma3_output`, `ma3_selection`, `ma3_masters`, `ma3_session`, `ma3_messages` (whatever route proved), `watch`. Release 0.3.0. | 3 to 4 | watches one rehearsal through the tools; compares to the desk |
| **3. Programming level 1** | thin helpers with the plan/backup/undo/read-back pattern, on scratch objects first; Preview use; `new_weekend_page`, `new_song_skeleton`. Release 0.4.0. | 4 to 5 | gives one real weekend page job and one song skeleton to the tools |
| **4. Presence** | own user and profile for the plugin; `ma3_set` inside undo groups; owned-input design if needed. | 2 to 3 | works beside the plugin for a session and reports what it touched |
| **5. Show intelligence** | digests and diffs after saves, Planning Center join, pre-show check, style file kept current. | 3 | reads a pre-show report before a service |
| **6. Programming levels 2 to 4** | effect sequences from templates, phasers and recipes in Preview, song generation from his own programming as proposals. Release 1.0 after one production. | open-ended | approves generated proposals cue by cue at first |

Phases 1 and 2 are mostly research and reads and can run during the Christmas production weeks
on the bench; writes and plugin updates wait for the freeze to lift.

---

## 6. Risks and how they are held

| Risk | Hold |
| --- | --- |
| A probe hangs the desk | **It happened, 2026-11-08** (census read, GUI froze mid-service). Hold: exploration on onPC only; console guard in the plugin (allow-list by class path, call journal with automatic quarantine after a stall, 8 requests/s cap, Lua off at start on the console); the page/executor range hang refused in code |
| An MA update breaks the API | Facts carry versions; the plugin reports the console version; a re-probe pass follows every update; all console access stays in a few files |
| Writes damage the show | Backup before every job, one undo group, read-back, scratch objects first, production freeze |
| The plugin eats console time | Time-sliced work, measured budgets, per-tool timings in status, slice length tunable |
| Someone on the LAN with the PIN | PIN rotation offered in the window, lockout, sandboxed Lua, no file access from Lua, security review per release |
| Scope grows faster than proof | Each phase ends with Aaron testing on the desk; nothing moves to the next level without a read-back record |
| Knowledge rots | Ledgers in this file; facts file dated; digests after saves |

---

## 7. Ledgers

### 7.1 Unknowns (open questions, with the next approach)

| Question | Tried | Next |
| --- | --- | --- |
| How can a plugin read Message Center entries? | Object tree (`Root 1` empty, export empty); Lua function list (none) | Window scrape with the window open; `HookObjectChange` on `Root 1`; parse `message_center.dat`; the Terminal app's `sysmon` for the System Monitor (`docs/atlas/topics/system-and-messages.md`) |
| Does `TimecodeSlot.TIME` advance live for a plugin? | Read three times while nothing rolled | Sunday 2026-11-08 with timecode rolling |
| Can a plugin run commands on a different user's command line? | `Root 20.1` lists cmdlines per user; help: a user profile holds programmer, selection, page, views; `LogIn` switches the whole station (`docs/atlas/topics/users-and-sessions.md`) | A second station (onPC elsewhere) logged in as a plugin user; never join this Mac's onPC to the console's session (show files swap) |
| Does `GetPath(Library)` really follow the selected drive after a USB import? | Inferred from three PIN changes and their timing | Look for `ma3_mcp_settings.json` on the stick |
| Does the desk feel normal during a long paced read (10 ms slices)? | Not asked yet | Ask Aaron after alpha.5; lower `SLICE_SECONDS` if not |
| Fade progress of a running cue: readable, or computed only? | Not probed | `RunningSequences`, executor properties, `GetRTChannels` during a fade |
| Does `;` chain commands past the refusal list? | MA's example macros chain with `;` (help); alpha.6 checks every segment | onPC bench to confirm the console splits the same way |
| Why do `ma3_children` and `Export` see one entry in `Root 14.9.9` (RTChannels, 11,618 by count) while `Root 14.9.9.<n>` resolves for every n? | Both tried 2026-11-08 | A tool that reads a collection by index when `Ptr` fails; check `Children()` vs `Ptr` on it with Lua on |
| Which step dropped the two DMX curves (`Rear House`, `Seat Lights`) and their 11 dimmer assignments between `Late 2026 2` and `Christmas 2026`? | The old file had them in the pool; the new file's pool had only the default. Restored 2026-11-08 (`docs/jobs/2026-11-08-dimmer-curves/`) | Ask Aaron how the new show was made (Save As, new show + patch import, MVR); test that step on onPC |
| Import a library file from the USB stick by command, so Aaron does not have to use the GUI | `Import Library "x.xml" At Root 14.10.1.n` works from the console's own library only; `If Drive 2`, `SelectDrive 2`, `/Path "<folder>"` all "Object not found" (2026-11-08) | Bench on onPC with a second drive folder; with Lua on (alpha.5) write the file into the library with `io.open`, then import from the internal drive |
| Can a plugin start itself on show load on a console? | MA docs say no supported hook | Re-check each release; `Startshow Import` plugin in the pool hints at a mechanism |
| Does the console resolve keyword shortcuts as the help documents (`R` = Reboot, `Lu` = Lua)? | Help keyword pages (2026-11-08); alpha.6 refuses by that table | `GetTokenName()` on onPC for every refused keyword's shortcut; then use it as a second check |
| Does a `Plugin` command sent through `Cmd` re-enter the plugin's `Main` synchronously? | alpha.6 assumes yes (refuses arguments while a request runs) and also refuses commands naming the plugin | onPC bench with a harmless argument (`status`) |
| Is there a crash log or system monitor dump from the 2026-11-08 freeze? | Not checked | Aaron at the desk with the stick in: `ListCrashLog`, `CopyCrashLog If Drive 2`, `DumpLog` (not through the plugin) |

### 7.2 Facts promoted this period

Kept in `docs/research/2026-11-onpc-facts.md`; this ledger lists only what moved from "inferred"
to "measured" and when. (Empty until phase 1.)

### 7.3 Ideas parked

- Audio-to-cue skeletons (beat and section detection feeding timecode events).
- A visual check path (the console has no screenshot API; the Cue Display web views are the
  current substitute).
- Cue Display: a second fixed frame for the whole song list and a run-of-show view.

---

## 8. Decisions this plan rests on (Aaron's, pending)

1. **The onPC bench may be driven by OSC and HTTP** on this Mac (network messages, not keystrokes).
2. **Writes during the Christmas production (2026-12-08 to 2026-12-22) are frozen** to jobs Aaron
   asks for; experiments go to the bench.
3. **Programming tools work blind first** (Preview environment or scratch objects) and copy live
   only after a read-back matches.
4. **The plugin gets its own MA user** when phase 4 arrives (a user and profile Aaron creates).
5. **The repo stays public under MIT**; ideas from the other projects are learned, their code is
   not copied.
6. **Phase order** as in section 5: atlas and live reads before programming tools.

## Document history

| Date | Change |
| --- | --- |
| 2026-11-07 | First draft from Aaron's brief ("reach the heart of the console"). |
| 2026-11-08 | After the console froze from a census read during a service: exploration moved to onPC only (banner, rules, risks). Atlas work started offline: whole help downloaded and itemized, `docs/atlas/CHECKLIST.md` (7,533 items, 168 ticked). Fast multi-show analysis researched: `docs/research/2026-11-08-fast-show-analysis.md`. |
| 2026-11-08 (evening) | Atlas phase 1 offline work done: every chapter of the help studied into topic pages (`docs/atlas/topics/`, entry skill `ma3-console`); generated keyword index; checklist now counts the topic pages (2,204 named, 441 ticked). The study found five holes in the unreleased alpha.6 guard (keyword shortcuts, station/session/login commands, unquoted `(` and `$`, object keywords outside show data, the plugin's own arguments through `ma3_command`); all fixed and tested. Unknowns ledger updated. |
