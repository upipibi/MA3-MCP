# MA3 MCP — project context

A grandMA3 Lua plugin that makes the grandMA3 light an MCP server. Public personal repo:
https://github.com/upipibi/MA3-MCP (Aaron's, not the Northwoods org). State as of 2026-11-03:
v0.1.0-alpha.1 installed on the console and answering Claude Code from Aaron's laptop.

## Read first

- `README.md`: what it is, tools, install, build.
- `docs/CONVENTIONS.md`: how Aaron's showfile is organized. Every job reads it. No open questions.
- `.claude/skills/ma3-housekeeping/SKILL.md`: the job workflow (orient, plan, show Aaron, go, backup, execute in one undo group, verify, report).
- `docs/research/2026-11-onpc-facts.md`: console facts that cost hours. Read before changing the plugin.
- `docs/superpowers/specs/...` and `plans/...`: the design and the plan it was built from.

## Running a job

- The console server is registered in Claude Code user scope as `ma3` (tools `mcp__ma3__ma3_*`).
  The PIN lives in the plugin window on the console and in Claude Code's config, never in this repo.
- Planning Center comes from Weekend Rundown's read-only `pco-mcp`, wired here as `planning_center`
  through `.mcp.json` (gitignored: absolute paths). Tools: `list_service_types`, `list_plans`,
  `get_plan`, `get_plan_items`, ... Service type: Sunday services. Songs = items PCO types as song.
- A session started before the servers were added needs `/mcp` to reconnect, or a fresh session.
- Writes go through `ma3_command` only after Aaron says go, with `ma3_backup` first.
  `ma3_backup` has not yet been exercised on the console: the first time, Aaron watches.

## Developing the plugin

- `make test` (Lua 5.5, the console's version; `LUAV=5.4` as a check), `make build`, `make release`.
- onPC bench on this Mac: `make install-onpc`, then in onPC `ReloadAllPlugins` and `Plugin "MA3 MCP"`.
  onPC settings/PIN: `~/MALightingTechnology/gma3_library/ma3_mcp_settings.json`; log in
  `gma3_2.5.1/onpc/temp/ma3_mcp.log`.
- Console update: copy `dist/MA3 MCP.lua` + `.xml` to the MA3 USB stick's
  `grandMA3/gma3_library/datapools/plugins/`, then on the console `Plugin "MA3 MCP" "off"`,
  `Delete Plugin 91 /NoConfirmation`, `Import Plugin Library "MA3 MCP.xml" At Plugin 91`,
  `Plugin "MA3 MCP"`. Full guide: `docs/INSTALL-CONSOLE.md`.
- Never drive onPC or anything else on this Mac with keystrokes or mouse automation while Aaron is
  using it (2026-11-03: two batches landed in his VS Code window). Use HTTP calls or ask him.

## Open items

- `ma3_backup` and the optional pool-button Appearance unverified on console hardware.
- Review minors deferred (see git history of the fix pass): no 4 MB response cap, `ma3_pages`
  ignores the time budget, bad-PIN rows not red, undo groups never closed by a client stay open.
- Future idea Aaron mentioned: build a simple song sequence from his existing programming. Not a job yet.
