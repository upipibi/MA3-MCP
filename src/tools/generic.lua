-- The generic "full window" tools: status, object, children, dump, set, command, undo close.
local addr = require("addr")
local console = require("console")

local M = {}

local NOCONFIRM_PREFIXES = { "delete", "store", "oops", "import", "export", "cut", "merge", "off", "assign", "copy", "move", "clone" }

-- First keywords ma3_command never sends: Lua would bypass the ma3_lua gate; show-file
-- commands open dialogs on the plugin thread (ma3_save / ma3_backup are the save paths).
local REFUSED = {
  lua = "use ma3_lua (it is gated by the window toggle)", luafile = "use ma3_lua (it is gated by the window toggle)",
  saveshow = "use ma3_save or ma3_backup", loadshow = "refused: load shows from the console", newshow = "refused: create shows from the console",
}

local function needs_noconfirmation(cmd)
  local first = cmd:match("^%s*(%a+)")
  if not first then return false end
  first = first:lower()
  for _, p in ipairs(NOCONFIRM_PREFIXES) do if first == p then return true end end
  return false
end

local function resolve(c, address)
  if address == nil then return nil, "address is required" end
  local ok, why = addr.check(address)
  if not ok then return nil, why .. " " .. tostring(address) end
  local h = c:object(address)
  if not h then return nil, "object not found: " .. address end
  return h
end

local function dump_text(h, depth, indent, out)
  out[#out + 1] = string.format("%s%s %q (%s)", indent, h:ToAddr(), tostring(h.name or ""), h:GetClass())
  local props = console.properties(h)
  local names = {}
  for k in pairs(props) do names[#names + 1] = k end
  table.sort(names)
  for _, k in ipairs(names) do out[#out + 1] = string.format("%s  %s = %s", indent, k, tostring(props[k])) end
  if depth > 0 then
    for _, ch in ipairs(h:Children()) do dump_text(ch, depth - 1, indent .. "    ", out) end
  end
end

function M.register(tools, c, ctx)
  ctx.undos = ctx.undos or {}

  tools.ma3_status = {
    description = "Console and plugin status: show name, software version, host type, plugin version, Lua enabled, uptime, request count, last backup, listening address. {log:true} adds the plugin's last log lines. Read-only.",
    inputSchema = { type = "object", properties = { log = { type = "boolean", description = "include recent log lines" } } },
    handler = function(args)
      local r = {
        show = c:show_name(), version = c:version(), host_type = c:host_type(),
        plugin_version = ctx.plugin_version, lua_enabled = ctx.lua_enabled(),
        uptime_s = math.floor((c:now() - (ctx.started_at or 0)) + 0.5), requests = ctx.request_count,
        last_backup = ctx.last_backup, address = ctx.address,
      }
      if args and args.log and ctx.log then r.log_lines = ctx.log:lines() end
      return r
    end,
  }

  tools.ma3_object = {
    description = "Read one object by command-line address (e.g. 'Sequence 12', 'Fixture 101.3', 'Page 2.5', 'DataPool 1 Preset 4.1'): class, name, child count and every non-empty property (handles rendered as addresses). {schema:true} adds the property names and types. Refuses Page/Executor ranges and wildcards ([unsafe-range]). Read-only.",
    inputSchema = { type = "object", required = { "address" }, properties = { address = { type = "string" }, schema = { type = "boolean" } } },
    handler = function(args)
      local h, err = resolve(c, args.address)
      if not h then return nil, err end
      local props, schema = console.properties(h, args.schema)
      return { address = h:ToAddr(), class = h:GetClass(), name = h.name, child_count = h:Count(), properties = props, schema = schema }
    end,
  }

  tools.ma3_children = {
    description = "List an object's direct children (index, class, number, name, address) with paging (offset, limit ≤ 500, next_offset). {fields:[...]} adds those properties per child. Read-only.",
    inputSchema = { type = "object", required = { "address" }, properties = { address = { type = "string" }, offset = { type = "integer" }, limit = { type = "integer" }, fields = { type = "array", items = { type = "string" } } } },
    handler = function(args)
      local h, err = resolve(c, args.address)
      if not h then return nil, err end
      local total = h:Count()
      local offset = math.max(0, math.floor(tonumber(args.offset) or 0))
      local limit = math.min(500, math.max(1, math.floor(tonumber(args.limit) or 500)))
      local out = {}
      local i = offset + 1
      while i <= total and #out < limit do
        local ch = h:Ptr(i)
        if ch then
          local row = console.child_summary(ch, i)
          if args.fields then
            row.properties = {}
            for _, f in ipairs(args.fields) do row.properties[f] = console.get(ch, f) end
          end
          out[#out + 1] = row
        end
        i = i + 1
        if (i - offset) % 50 == 0 then c:yield() end
      end
      local next_offset = (i <= total) and (i - 1) or nil
      return { address = h:ToAddr(), total = total, children = out, next_offset = next_offset }
    end,
  }

  tools.ma3_dump = {
    description = "Text dump of an object: its properties and, to {depth} levels (default 1, max 4), its children's. Like the console's Dump but returned to the client. Read-only.",
    inputSchema = { type = "object", required = { "address" }, properties = { address = { type = "string" }, depth = { type = "integer" } } },
    handler = function(args)
      local h, err = resolve(c, args.address)
      if not h then return nil, err end
      local depth = math.min(4, math.max(0, math.floor(tonumber(args.depth) or 1)))
      local out = {}
      dump_text(h, depth, "", out)
      return { address = h:ToAddr(), text = table.concat(out, "\n") }
    end,
  }

  tools.ma3_set = {
    description = "Set one property on one object and read it back: returns before/after. Refuses 'Tags' (use ma3_command with Assign Tag). Changes the live show.",
    inputSchema = { type = "object", required = { "address", "property", "value" }, properties = { address = { type = "string" }, property = { type = "string" }, value = { type = { "string", "number", "boolean" } } } },
    handler = function(args)
      local h, err = resolve(c, args.address)
      if not h then return nil, err end
      local prop = tostring(args.property or "")
      if prop:upper() == "TAGS" then return nil, "Tags cannot be set directly; use ma3_command with 'Assign Tag <n> At <object>'" end
      local exists = false
      for i = 1, h:PropertyCount() do if h:PropertyName(i):upper() == prop:upper() then exists = true break end end
      if not exists then return nil, "no property " .. prop .. " on " .. h:ToAddr() end
      local before = console.get(h, prop)
      local ok, res = pcall(function() return h:Set(prop, args.value) end)
      if not ok then return nil, "set failed: " .. tostring(res) end
      return { address = h:ToAddr(), property = prop, before = before, after = console.get(h, prop) }
    end,
  }

  tools.ma3_command = {
    description = "Run one command-line command exactly as typed on the console (Store, Label, Assign, Delete, Go, ...). Returns the console's result string ('OK', 'Object not found', ...). Adds /NoConfirmation to Delete/Store/Oops/Import/Export/Cut/Merge/Off/Assign/Copy/Move/Clone so no dialog can stall the plugin. Refuses Lua/LuaFile (use ma3_lua) and SaveShow/LoadShow/NewShow (use ma3_save/ma3_backup). {undo_group:'name'} groups commands into one console undo (close it with ma3_undo_close). The console cannot interrupt a command; a timeout proves nothing, check state before resending. Changes the live show.",
    inputSchema = { type = "object", required = { "command" }, properties = { command = { type = "string" }, undo_group = { type = "string" } } },
    handler = function(args)
      local cmd = tostring(args.command or "")
      if cmd:match("^%s*$") then return nil, "command is empty" end
      if cmd:find("[%c]") then return nil, "command contains control characters" end
      local first = (cmd:match("^%s*(%a+)") or ""):lower()
      if REFUSED[first] then return nil, string.format("%s is not sent by ma3_command: %s", first, REFUSED[first]) end
      local added = false
      if needs_noconfirmation(cmd) and not cmd:lower():find("/noconfirmation", 1, true) then
        cmd = cmd .. " /NoConfirmation"
        added = true
      end
      local undo
      if args.undo_group then
        undo = ctx.undos[args.undo_group]
        if not undo then
          undo = c:create_undo(args.undo_group)
          ctx.undos[args.undo_group] = undo
        end
      end
      local t0 = c:now()
      local ok, res = pcall(function() return c:cmd(cmd, undo) end)
      if not ok then return nil, "command failed: " .. tostring(res) end
      return { command = cmd, result = res ~= nil and tostring(res) or "", noconfirmation_added = added,
        undo_group = args.undo_group, duration_ms = math.floor((c:now() - t0) * 1000 + 0.5) }
    end,
  }

  tools.ma3_undo_close = {
    description = "Close an undo group opened by ma3_command {undo_group}. After this, one Oops on the console reverts the whole group.",
    inputSchema = { type = "object", required = { "undo_group" }, properties = { undo_group = { type = "string" } } },
    handler = function(args)
      local undo = args.undo_group and ctx.undos[args.undo_group]
      if not undo then return nil, "no open undo group named " .. tostring(args.undo_group) end
      local ok, res = pcall(function() return c:close_undo(undo) end)
      ctx.undos[args.undo_group] = nil
      if not ok then return nil, "close failed: " .. tostring(res) end
      return { closed = args.undo_group, result = res }
    end,
  }
end

return M
