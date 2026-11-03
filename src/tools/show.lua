-- Show-file tools: backup copy before destructive jobs, plain save.
-- SaveShow goes through CmdIndirect so its dialog never lands on the plugin thread.
local M = {}

M.STEM_LENGTH = 16
M.KEEP = 5

local function listed(c, name)
  local ok, list = pcall(function() return c:dirlist(c:path("Showfiles"), "*.show") end)
  if not ok or type(list) ~= "table" then return false end
  for _, it in ipairs(list) do
    local n = type(it) == "table" and it.name or it
    if n == name .. ".show" then return true end
  end
  return false
end

local function wait_for_file(c, ctx, name)
  local t0 = c:now()
  local budget = (tonumber(ctx.budget_ms) or 10000) / 1000
  while true do
    if listed(c, name) then return true end
    if c:now() - t0 > budget then return false end
    c:yield()
  end
end

function M.register(tools, c, ctx)
  ctx.backups = ctx.backups or {}

  tools.ma3_backup = {
    description = "Save a backup copy of the current show as '<first 16 chars of show name>_mcp_<MMDD_HHMM>' and then save again under the current name, so the current show is unchanged. Returns {backup, current, stem}. Waits until the file is listed. Never deletes show files; the last five backup names are kept in the plugin window. Call this before any job that deletes or rewrites.",
    inputSchema = { type = "object", properties = {} },
    handler = function()
      local show = c:show_name()
      if not show or show == "" then return nil, "no show name available (is a show loaded?)" end
      local stem = show:sub(1, M.STEM_LENGTH)
      local stamp = ctx.now_date and ctx.now_date() or os.date("%m%d_%H%M")
      local backup = stem .. "_mcp_" .. stamp
      c:cmd_indirect(string.format('SaveShow "%s"', backup))
      if not wait_for_file(c, ctx, backup) then
        return nil, "backup " .. backup .. " is not listed in the shows folder after the time budget; check the console (a dialog may be open) before retrying"
      end
      c:cmd_indirect(string.format('SaveShow "%s"', show))
      table.insert(ctx.backups, 1, backup)
      while #ctx.backups > M.KEEP do table.remove(ctx.backups) end
      ctx.last_backup = backup
      if ctx.on_backup then pcall(ctx.on_backup, backup) end
      return { backup = backup, current = show, stem = stem }
    end,
  }

  tools.ma3_save = {
    description = "Save the show under its current name (no dialog). Returns {saved}.",
    inputSchema = { type = "object", properties = {} },
    handler = function()
      local show = c:show_name()
      if not show or show == "" then return nil, "no show name available (is a show loaded?)" end
      c:cmd_indirect(string.format('SaveShow "%s"', show))
      return { saved = show }
    end,
  }
end

return M
