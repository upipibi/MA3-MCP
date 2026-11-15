-- The generic "full window" tools: status, object, children, dump, set, command, commands (batch), undo close.
local addr = require("addr")
local console = require("console")
local keywords = require("keywords")

local M = {}

local NOCONFIRM_PREFIXES = { "delete", "store", "oops", "import", "export", "cut", "merge", "off", "assign", "copy", "move", "clone" }

-- First keywords ma3_command never sends. Lua would bypass the ma3_lua gate; show-file commands
-- open dialogs on the plugin thread (ma3_save / ma3_backup are the save paths); the station,
-- software, session and login commands restart, shut down, update, log out or regroup the
-- console and its session, and menus or help open pop-ups on the operator's screens.
-- The console accepts shortcuts (Lu = Lua, Sa = SaveShow, R = Reboot), so a word is refused when it
-- is the keyword, one of its documented aliases, or a prefix of the keyword at least as long as
-- `min` (MA's documented shortcut, or the shortest prefix no other keyword shares). Keywords from
-- the MA 2.5 help, keyword pages; `min` checked against the full keyword list (2026-11-08).
local REFUSED_KEYWORDS = {
  { "lua", "lu", nil, "use ma3_lua (it is gated by the window toggle)" },
  { "luafile", "luaf", nil, "use ma3_lua (it is gated by the window toggle)" },
  { "saveshow", "sa", nil, "use ma3_save or ma3_backup" },
  { "loadshow", "lo", nil, "refused: load shows from the console" },
  { "newshow", "new", nil, "refused: create shows from the console" },
  { "reboot", "r", nil, "refused: restarts the station" },
  { "restart", "res", nil, "refused: restarts the console software" },
  { "shutdown", "sh", nil, "refused: shuts the station down" },
  { "reloadui", "reloadu", { "ru" }, "refused: reloads every window on the operator's screens" },
  { "reloadallplugins", "reloada", { "rp" }, "refused: reloads the plugins, this one included" },
  { "softwareupdate", "softwareu", nil, "refused: software updates are done at the console" },
  { "softwareimport", "so", nil, "refused: software updates are done at the console" },
  { "deleteotherversion", "deleteo", nil, "refused: software updates are done at the console" },
  { "cancelsoftwareupdate", "can", nil, "refused: software updates are done at the console" },
  { "switchtograndma2software", "sw", { "swgma2" }, "refused: switches the station's software" },
  { "switchtograndma3software", "switchtograndma3", { "swgma3" }, "refused: switches the station's software" },
  { "joinsession", "j", nil, "refused: session changes are done at the console" },
  { "leavesession", "le", nil, "refused: session changes are done at the console" },
  { "invite", "inv", nil, "refused: session changes are done at the console" },
  { "dismiss", "di", nil, "refused: session changes are done at the console" },
  { "disconnect", "disc", nil, "refused: session changes are done at the console" },
  { "reconnect", "recon", nil, "refused: session changes are done at the console" },
  { "remotecommand", "remotec", nil, "refused: sends commands to other stations" },
  { "changemulticastbase", "changem", { "changemultcastbase" }, "refused: session changes are done at the console" },
  { "networkspeedtest", "net", nil, "refused: loads the lighting network" },
  { "login", "log", nil, "refused: logs the operator out" },
  { "logout", "logo", nil, "refused: logs the operator out" },
  { "menu", "men", nil, "refused: opens a menu on the operator's screens" },
  { "help", "h", nil, "refused: opens a pop-up on the operator's screens" },
  { "helpkeyword", "helpk", nil, "refused: opens a pop-up on the operator's screens" },
  { "helplua", "helpl", nil, "refused: opens a pop-up on the operator's screens" },
  { "dumplog", "du", nil, "refused: may ask for a drive in a pop-up" },
  { "copycrashlog", "copyc", nil, "refused: may ask for a drive in a pop-up" },
  { "eject", "ej", nil, "refused: ejects the operator's drive" },
}
-- Full keywords that are prefixes of a refused one and mean something else.
local ALLOWED_EXACT = { load = true }

-- Returns the refused keyword and the reason when `word` would run one, else nil.
function M.refused_keyword(word) return keywords.match(word, REFUSED_KEYWORDS, ALLOWED_EXACT) end

local function needs_noconfirmation(cmd)
  local first = cmd:match("^%s*(%a+)")
  if not first then return false end
  first = first:lower()
  for _, p in ipairs(NOCONFIRM_PREFIXES) do if first == p then return true end end
  return false
end

local function resolve(c, address) return c:resolve(address) end

-- A dump visits at most DUMP_NODE_CAP objects and paces itself like the other walks; on a
-- console, children the guard refuses are named by class and not entered.
M.DUMP_NODE_CAP = 2000

local function dump_text(c, h, path, depth, indent, out, st)
  if st.n >= M.DUMP_NODE_CAP then st.truncated = true return end
  st.n = st.n + 1
  out[#out + 1] = string.format("%s%s %q (%s)", indent, h:ToAddr(), tostring(h.name or ""), h:GetClass())
  local props = console.properties(h)
  local names = {}
  for k in pairs(props) do names[#names + 1] = k end
  table.sort(names)
  for _, k in ipairs(names) do out[#out + 1] = string.format("%s  %s = %s", indent, k, tostring(props[k])) end
  c:pace()
  if depth > 0 then
    for _, ch in ipairs(h:Children()) do
      if st.n >= M.DUMP_NODE_CAP then st.truncated = true return end
      local ok, why, child_path, cls = c:child_allowed(path, ch)
      if ok then
        dump_text(c, ch, child_path, depth - 1, indent .. "    ", out, st)
      else
        out[#out + 1] = string.format("%s    (refused %s: %s)", indent, tostring(cls), tostring(why))
      end
    end
  end
end

-- Splits a command line at ";" outside double or single quotes.
function M.segments(cmd)
  local out, buf, quote = {}, {}, nil
  for ch in tostring(cmd):gmatch(".") do
    if quote then
      buf[#buf + 1] = ch
      if ch == quote then quote = nil end
    elseif ch == '"' or ch == "'" then
      quote = ch; buf[#buf + 1] = ch
    elseif ch == ";" then
      out[#out + 1] = table.concat(buf); buf = {}
    else
      buf[#buf + 1] = ch
    end
  end
  out[#out + 1] = table.concat(buf)
  return out
end

-- True when `cmd` has one of `chars` outside single or double quotes.
function M.has_unquoted(cmd, chars)
  local quote = nil
  for ch in tostring(cmd):gmatch(".") do
    if quote then
      if ch == quote then quote = nil end
    elseif ch == '"' or ch == "'" then
      quote = ch
    elseif chars:find(ch, 1, true) then
      return true
    end
  end
  return false
end

-- True when a command segment addresses this plugin: the Plugin keyword (or a shortcut) with this
-- plugin's name in quotes or its pool number.
local PLUGIN_RULE = { { "plugin", "pl" } }
function M.calls_self(seg, self_plugin)
  if not self_plugin then return false end
  local words = keywords.words(seg)
  local has_plugin = false
  for _, w in ipairs(words) do
    if keywords.match(w, PLUGIN_RULE) then has_plugin = true end
  end
  if not has_plugin then return false end
  if self_plugin.name and seg:lower():find('["\']%s*' .. self_plugin.name:gsub("%p", "%%%0") .. '%s*["\']') then return true end
  if self_plugin.number then
    local bare = keywords.unquote(seg)
    for n in bare:gmatch("%f[%w][Pp][Ll]%a*%s+(%d+)%f[%D]") do
      if tonumber(n) == self_plugin.number then return true end
    end
  end
  return false
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
      local h, err, path = resolve(c, args.address)
      if not h then return nil, err end
      c:start_slice()
      local total = h:Count()
      local offset = math.max(0, math.floor(tonumber(args.offset) or 0))
      local limit = math.min(500, math.max(1, math.floor(tonumber(args.limit) or 500)))
      local out = {}
      local i = offset + 1
      while i <= total and #out < limit do
        local ch = h:Ptr(i)
        local allowed, why, _, cls = true, nil, nil, nil
        if ch then allowed, why, _, cls = c:child_allowed(path, ch) end
        if ch and not allowed then
          out[#out + 1] = { index = i, class = cls, refused = why }
        elseif ch then
          local row = console.child_summary(ch, i)
          if args.fields then
            row.properties = {}
            for _, f in ipairs(args.fields) do row.properties[f] = console.get(ch, f) end
          end
          out[#out + 1] = row
        end
        i = i + 1
        c:pace()
      end
      local next_offset = (i <= total) and (i - 1) or nil
      return { address = h:ToAddr(), total = total, children = out, next_offset = next_offset }
    end,
  }

  tools.ma3_dump = {
    description = "Text dump of an object: its properties and, to {depth} levels (default 1, max 4), its children's. Like the console's Dump but returned to the client. Read-only.",
    inputSchema = { type = "object", required = { "address" }, properties = { address = { type = "string" }, depth = { type = "integer" } } },
    handler = function(args)
      local h, err, path = resolve(c, args.address)
      if not h then return nil, err end
      local depth = math.min(4, math.max(0, math.floor(tonumber(args.depth) or 1)))
      local out, st = {}, { n = 0 }
      c:start_slice()
      dump_text(c, h, path or {}, depth, "", out, st)
      return { address = h:ToAddr(), text = table.concat(out, "\n"), nodes = st.n, truncated = st.truncated or nil }
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

  -- Validates one command-line string and appends /NoConfirmation where a dialog could open.
  -- Returns the command to send and whether the option was added, or nil + reason.
  local function prepare(raw)
    local cmd = tostring(raw or "")
    if cmd:match("^%s*$") then return nil, nil, "command is empty" end
    if cmd:find("[%c]") then return nil, nil, "command contains control characters" end
    -- An unquoted ( ... ) asks the operator for input in a text-input pop-up (MA help, Extended
    -- Command Line); the plugin would wait on a dialog nobody at the desk expects.
    if M.has_unquoted(cmd, "()") then
      return nil, nil, "parentheses outside quotes open a text-input pop-up on the console; put names in quotes"
    end
    -- $name expands a user or global variable into command text the checks below never see.
    if M.has_unquoted(cmd, "$") then
      return nil, nil, "$variables outside quotes expand into commands ma3_command cannot check; write the command out"
    end
    -- The console runs several commands on one line separated by ";" (MA's own example macros do),
    -- so every segment outside quotes gets the same checks as the first.
    for _, seg in ipairs(M.segments(cmd)) do
      local first = (seg:match("^%s*(%a[%w]*)") or ""):lower()
      local kw, why = M.refused_keyword(first)
      if kw then return nil, nil, string.format("%s is not sent by ma3_command (%s): %s", first, kw, why) end
      if M.calls_self(seg, ctx.self_plugin) then
        return nil, nil, "commands that call this plugin are not sent by ma3_command; its arguments are for the operator at the desk"
      end
      -- Thru, + or * on a Page or Executor address hung the console (2026-11); Go+ / Go- are not ranges.
      local okr, whyr = addr.check((seg:gsub("%f[%w][Gg][Oo]([%+%-])", "Go")))
      if not okr then return nil, nil, whyr .. " " .. seg end
    end
    if c.guard then
      local okg, whyg = c.guard:allow_command(cmd)
      if not okg then return nil, nil, whyg end
    end
    local added = false
    if needs_noconfirmation(cmd) and not cmd:lower():find("/noconfirmation", 1, true) then
      cmd = cmd .. " /NoConfirmation"
      added = true
    end
    return cmd, added
  end

  local function undo_for(name)
    if not name then return nil end
    local undo = ctx.undos[name]
    if not undo then
      undo = c:create_undo(name)
      ctx.undos[name] = undo
    end
    return undo
  end

  tools.ma3_command = {
    description = "Run one command-line command exactly as typed on the console (Store, Label, Assign, Delete, Go, ...). Returns the console's result string ('OK', 'Object not found', ...). Adds /NoConfirmation to Delete/Store/Oops/Import/Export/Cut/Merge/Off/Assign/Copy/Move/Clone so no dialog can stall the plugin. Refuses Lua/LuaFile (use ma3_lua), SaveShow/LoadShow/NewShow (use ma3_save/ma3_backup), station, software, session and login commands (Reboot, Restart, ShutDown, JoinSession, RemoteCommand, LogIn, ...), Menu and Help, keyword shortcuts of all of these, calls to this plugin, and unquoted ( ) or $variables; on a console also commands that reach outside show data (Root other than 14, StationSettings, View, UserProfile, ...). {undo_group:'name'} groups commands into one console undo (close it with ma3_undo_close). The console cannot interrupt a command; a timeout proves nothing, check state before resending. Changes the live show.",
    inputSchema = { type = "object", required = { "command" }, properties = { command = { type = "string" }, undo_group = { type = "string" } } },
    handler = function(args)
      local cmd, added, why = prepare(args.command)
      if not cmd then return nil, why end
      local undo = undo_for(args.undo_group)
      local t0 = c:now()
      local ok, res = pcall(function() return c:cmd(cmd, undo) end)
      if not ok then return nil, "command failed: " .. tostring(res) end
      return { command = cmd, result = res ~= nil and tostring(res) or "", noconfirmation_added = added,
        undo_group = args.undo_group, duration_ms = math.floor((c:now() - t0) * 1000 + 0.5) }
    end,
  }

  tools.ma3_commands = {
    description = "Run a list of command-line commands in order in one request (up to 200). Each command gets the same checks and /NoConfirmation handling as ma3_command, and the whole list is validated before anything is sent, so a refused command stops the batch before the console sees it. Stops at the first result that is not 'OK' unless {stop_on_error:false}. {undo_group:'name'} puts every command in one console undo; {close_undo:true} closes that group at the end. Returns per-command results, sent count, and stopped_at (1-based index of the failing command). Changes the live show.",
    inputSchema = { type = "object", required = { "commands" }, properties = {
      commands = { type = "array", items = { type = "string" }, minItems = 1, maxItems = 200 },
      undo_group = { type = "string" }, stop_on_error = { type = "boolean" }, close_undo = { type = "boolean" } } },
    handler = function(args)
      local list = args.commands
      if type(list) ~= "table" or #list == 0 then return nil, "commands must be a non-empty array" end
      if #list > 200 then return nil, "at most 200 commands per batch" end
      local prepared = {}
      for i, raw in ipairs(list) do
        local cmd, added, why = prepare(raw)
        if not cmd then return nil, string.format("command %d rejected, nothing sent: %s", i, why) end
        prepared[i] = { command = cmd, noconfirmation_added = added }
      end
      local stop = args.stop_on_error ~= false
      local undo = undo_for(args.undo_group)
      local t0 = c:now()
      local results, sent, stopped_at = {}, 0, nil
      for i, p in ipairs(prepared) do
        local ok, res = pcall(function() return c:cmd(p.command, undo) end)
        sent = sent + 1
        local text = ok and (res ~= nil and tostring(res) or "") or ("command failed: " .. tostring(res))
        results[i] = { command = p.command, result = text, noconfirmation_added = p.noconfirmation_added }
        if (not ok or text ~= "OK") and stop then stopped_at = i break end
        if i % 10 == 0 then c:yield() end
      end
      local closed = false
      if args.close_undo and undo then
        pcall(function() c:close_undo(undo) end)
        ctx.undos[args.undo_group] = nil
        closed = true
      end
      return { sent = sent, total = #prepared, stopped_at = stopped_at, results = results, undo_group = args.undo_group,
        undo_closed = closed, duration_ms = math.floor((c:now() - t0) * 1000 + 0.5) }
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
