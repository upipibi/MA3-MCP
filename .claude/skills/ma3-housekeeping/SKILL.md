---
name: ma3-housekeeping
description: Use for any job on the grandMA3 light through the MA3 MCP server (the `ma3` MCP tools) — creating, deleting or organizing sequences, pages, executors, groups, presets or macros, building pages from a Planning Center order, grouping new fixtures, or any read of the showfile. Use before calling any ma3_* tool that changes the show.
---

# MA3 housekeeping

You are working on a production lighting console. Read first, show the plan, then act.

## 1. Orient

1. Read `docs/CONVENTIONS.md`. If any line still says `TODO(Aaron)` that your job depends
   on, ask Aaron that question before planning; refuse to delete or rewrite anything while
   a relevant `TODO(Aaron)` is open.
2. `ma3_status`: confirm the show name is the one Aaron expects and note `lua_enabled`.
3. Read what the job touches with the bulk tools, paging with `next_offset` until
   `partial` is false: `ma3_sequences` (with `include_cues` only if cue detail matters),
   `ma3_pages`, `ma3_groups`, `ma3_fixtures`, `ma3_presets`, `ma3_macros`.
   Use `ma3_object` / `ma3_children` / `ma3_dump` for anything the bulk reads do not show.

## 2. Plan

Write the plan as a numbered list of the exact commands you will send, grouped as
deletes, creates, labels, assigns. For each delete, say what the object is (name, cue
count, where it is assigned) and why it qualifies. Then **stop and show Aaron the plan**.
Do not execute until he says go.

## 3. Execute

1. `ma3_backup` first. Keep the returned backup name for the report.
2. Send each command with `ma3_command`, all with the same `undo_group` (the job name),
   in the planned order. The tool appends `/NoConfirmation` where a dialog would open.
3. After the last command, `ma3_undo_close` with the same group so one Oops on the
   console reverts the whole job.
4. Re-read with the same bulk tools and compare against the plan.

## 4. Report

What changed (counts and names), what did not match the plan, the backup name, and
that one Oops reverts the job.

## Hazards (console facts, not style)

- Never put `Thru`, `+` or `*` on a `Page` or `Executor` address; the console hangs until
  relaunched. The tools refuse it with `[unsafe-range]`; do not work around that.
- A timeout proves nothing. The command may have run. Re-read state before resending.
- `SaveShow` and other dialogs stall the plugin; `ma3_backup` and `ma3_save` are the only
  save paths. Do not send `SaveShow` through `ma3_command`.
- `Set ... Tags` does not work; tags are assigned with `Assign Tag <n> At <object>`.
- Cue numbering: `CueZero` and `OffCue` are the console's; `cue_count` excludes them.
- Names on show files are cut to 31 characters; the backup tool handles it.
- `ma3_lua` is off unless the operator enabled it in the window; do not ask for it to be
  turned on unless no tool can do the job.
