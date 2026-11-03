-- Show-file tools. ma3_backup never renames the current show (SaveShow "<new name>" opens a
-- "change show file name?" dialog that would stall the plugin): it saves the show under its
-- own name through CmdIndirect, waits for the file to be rewritten, then copies the file.
local M = {}

M.STEM_LENGTH = 16
M.KEEP = 5

local function entry_for(c, name)
  local ok, list = pcall(function() return c:dirlist(c:path("Showfiles"), "*.show") end)
  if not ok or type(list) ~= "table" then return nil end
  for _, it in ipairs(list) do
    if type(it) == "table" and it.name == name .. ".show" then return it end
  end
  return nil
end

local function wait_for_rewrite(c, ctx, name, before_time, before_size)
  local t0 = c:now()
  local budget = (tonumber(ctx.budget_ms) or 10000) / 1000
  while true do
    local e = entry_for(c, name)
    if e and (e.time ~= before_time or e.size ~= before_size) then return e end
    if c:now() - t0 > budget then return nil end
    c:yield()
  end
end

local function io_fs()
  return {
    read = function(path) local f = io.open(path, "rb") if not f then return nil end local d = f:read("a") f:close() return d end,
    write = function(path, data) local f, err = io.open(path, "wb") if not f then return nil, err end f:write(data) f:close() return true end,
  }
end

function M.register(tools, c, ctx)
  ctx.backups = ctx.backups or {}
  local fs = ctx.fs or io_fs()

  tools.ma3_backup = {
    description = "Make a backup copy of the current show file: saves the show under its current name (no dialog), waits for the file, then copies it to '<first 16 chars of show name>_mcp_<MMDD_HHMM>.show'. Returns {backup, current, stem}. Never deletes or renames show files; the last five backup names are kept in the plugin window. Call this before any job that deletes or rewrites.",
    inputSchema = { type = "object", properties = {} },
    handler = function()
      local show = c:show_name()
      if not show or show == "" then return nil, "no show name available (is a show loaded?)" end
      if show:find('"', 1, true) then return nil, "the show name contains a quote; rename the show on the console first" end
      local stem = show:sub(1, M.STEM_LENGTH)
      local stamp = ctx.now_date and ctx.now_date() or os.date("%m%d_%H%M")
      local backup = stem .. "_mcp_" .. stamp
      local before = entry_for(c, show) or {}
      local before_time, before_size = before.time, before.size   -- captured before the save
      c:cmd_indirect(string.format('SaveShow "%s"', show))
      local saved = wait_for_rewrite(c, ctx, show, before_time, before_size)
      if not saved then
        return nil, "the show file was not rewritten within the time budget; check the console (a dialog may be open) before retrying"
      end
      local dir = c:path("Showfiles")
      local data = fs.read(dir .. "/" .. show .. ".show")
      if not data then return nil, "copy failed: could not read " .. show .. ".show" end
      local ok, err = fs.write(dir .. "/" .. backup .. ".show", data)
      if not ok then return nil, "copy failed: " .. tostring(err) end
      table.insert(ctx.backups, 1, backup)
      while #ctx.backups > M.KEEP do table.remove(ctx.backups) end
      ctx.last_backup = backup
      if ctx.on_backup then pcall(ctx.on_backup, backup) end
      return { backup = backup, current = show, stem = stem, bytes = #data }
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
