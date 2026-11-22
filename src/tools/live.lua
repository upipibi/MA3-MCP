-- Live state: what the console is doing right now, as opposed to what is stored in the show.
--
-- Rule for this file (console safety, 2026-11-08): a tool here may run on a console only with
-- calls that are proven there. ma3_playbacks uses HasActivePlayback() and CurrentChild() on
-- sequence objects, the two calls the Cue Display plugin has made five times a second on the
-- console since 2026-11-05, plus property reads the bulk tools already make. Anything new
-- (programmer, DMX output, protocol settings) is benched on onPC before it is added.
-- ma3_universes reads properties of DmxUniverse objects in the live patch (read on the console
-- 2026-11-19). ma3_ports reads DeviceConfigurations > OutputStations, read on onPC that day while it
-- was in the console's session; the guard lists that branch as readable by this tool only
-- (guard.READ_RULES), so no tool that takes an address can read or write there.
local console = require("console")
local bulk = require("tools.bulk")

local M = {}

local function num(v) if type(v) == "number" then return v end return tonumber(v) end
local function prop(h, name) return console.get(h, name) end
local function name_of(h) local n = h.name; if n == nil or n == "" then n = prop(h, "NAME") end return n end

-- true / false, or nil when the console answers neither call. HasActivePlayback is the call
-- proven on 2.5.1.1; MA's help names IsRunningPlayback as its successor (2.4).
local function is_running(s)
  local ok, v = pcall(function() return s:HasActivePlayback() end)
  if not ok then ok, v = pcall(function() return s:IsRunningPlayback() end) end
  if not ok then return nil end
  return v and true or false
end

local function child_of_class(h, class)
  for _, ch in ipairs(h:Children()) do if ch:GetClass() == class then return ch end end
  return nil
end

local function universes_pool(c)
  local p = c:patch()
  return p and child_of_class(p, "DmxUniverses")
end

local function universe_row(u, slot)
  return { universe = num(prop(u, "NO")) or slot, name = name_of(u), used = num(prop(u, "USED")) or 0,
    params = num(prop(u, "COARSEPARAMS")) or 0, port_out = prop(u, "PORTOUT") == true, port_in = prop(u, "PORTIN") == true,
    port_rdm = prop(u, "PORTRDM") == true, parked = num(prop(u, "PARKEDCOUNT")) or 0, tester = num(prop(u, "TESTERCOUNT")) or 0,
    granted = prop(u, "GRANTED"), merge_mode = prop(u, "MERGEMODE") }
end

local function universe_matters(r)
  return r.used > 0 or r.params > 0 or r.port_out or r.port_in or r.port_rdm or r.parked > 0 or r.tester > 0
end

local PORT_LETTERS = { "A", "B", "C", "D", "E", "F", "G", "H" }

-- A programmer part that holds nothing reports this MEMORYFOOTPRINT (2.5.1.1; read on onPC
-- 2026-11-21 on profiles 1, 2 and 5, Normal environment). Bigger means it holds values.
M.EMPTY_PART_BYTES = 297
-- Where the programmer sits below a user profile (same read): UserProfile > slot 1 Environments >
-- UserEnvironment (Normal, Preview) > slot ACTIVESELINDEX Selection, slot 3 Programmer > ProgPart.
-- Slot 5 of an environment is not an object on 2.5.1.1 (GetClass is nil): fixed slots, never a walk.
local ENVIRONMENTS_SLOT, PROGRAMMER_SLOT = 1, 3

local function class_is(h, class)
  if not h then return false end
  local ok, cls = pcall(function() return h:GetClass() end)
  return ok and cls == class
end

function M.register(tools, c, ctx, deps)
  deps = deps or {}
  -- Read-only branches no address can reach (guard.READ_RULES): ask the guard per object.
  local function may_read(h)
    if not c.guard then return true end
    local ok, why = c.guard:allow_handle(h, true)
    if not ok then return false, why end
    c.guard:target(h)
    return true
  end
  tools.ma3_playbacks = {
    description = "What is running right now: every sequence with an active playback as {no, name, address, priority, cue (as the console shows it, 12.2 not 12200), cue_name, cue_address, trigger, in_fade, in_delay, executors=[{page, executor, page_name, label}] (every place it is assigned; executors:false skips that page walk)}. running = how many. unreadable lists sequences the console would not answer for. Live state changes between calls: read again before acting on it. Read-only.",
    inputSchema = { type = "object", properties = { executors = { type = "boolean" } } },
    handler = function(args)
      args = args or {}
      local b = bulk.budget(c, ctx)
      local pool = c:datapool().Sequences
      if not pool then return nil, "no Sequences pool" end
      local rows, handles, unreadable = {}, {}, {}
      local next_offset, partial = bulk.walk_pool(pool, 0, pool:Count() + 1, b, function(s, slot)
        local running = is_running(s)
        if running == nil then unreadable[#unreadable + 1] = s:ToAddr() return false end
        if not running then return false end
        local row = { no = num(prop(s, "NO")) or slot, name = name_of(s), address = s:ToAddr(), priority = prop(s, "PRIORITY") }
        local okC, cue = pcall(function() return s:CurrentChild() end)
        if okC and cue then
          local no = num(prop(cue, "NO"))
          row.cue = no and no / 1000 or nil
          row.cue_name = name_of(cue)
          row.cue_address = cue:ToAddr()
          row.trigger = prop(cue, "TRIGTYPE")
          local part = cue:Ptr(1)
          if part then row.in_fade = prop(part, "CUEINFADE"); row.in_delay = prop(part, "CUEINDELAY") end
        end
        rows[#rows + 1] = row
        handles[#handles + 1] = s
      end)
      -- The executor index walks every page: only when something runs and the caller wants it.
      if #rows > 0 and args.executors ~= false then
        local index = bulk.executor_index(c, b)
        for _, row in ipairs(rows) do row.executors = index[row.address] or {} end
      end
      return { running = #rows, rows = rows, unreadable = #unreadable > 0 and unreadable or nil,
        next_offset = next_offset, partial = partial }
    end,
  }

  tools.ma3_universes = {
    description = "DMX universes as the console holds them: {universe, used (fixtures patched), params, port_out / port_in / port_rdm (a physical DMX port of some station in the session is mapped to it), parked (channels parked), tester (channels held by the DMX tester), granted, merge_mode}. Lists only universes with something on them; {all:true} lists every slot, {universe:n} reads one. warnings names what makes fixtures act by themselves: an input port on a patched universe, parked channels, tester values. Read this first when a fixture shows values nobody programmed. Paged (offset, limit, next_offset, partial). Read-only.",
    inputSchema = { type = "object", properties = { universe = { type = "integer" }, all = { type = "boolean" }, offset = { type = "integer" }, limit = { type = "integer" } } },
    handler = function(args)
      args = args or {}
      local b = bulk.budget(c, ctx)
      local pool = universes_pool(c)
      if not pool then return nil, "no DmxUniverses pool in the patch" end
      local rows = {}
      local next_offset, partial
      if args.universe then
        local u = pool:Ptr(math.floor(num(args.universe) or 0))
        if not u then return nil, "universe not found: " .. tostring(args.universe) end
        rows[1] = universe_row(u, args.universe)
      else
        local offset = math.max(0, math.floor(num(args.offset) or 0))
        local limit = math.min(1024, math.max(1, math.floor(num(args.limit) or 1024)))
        next_offset, partial = bulk.walk_pool(pool, offset, limit, b, function(u, slot)
          local row = universe_row(u, slot)
          if not args.all and not universe_matters(row) then return false end
          rows[#rows + 1] = row
        end)
      end
      local warnings = {}
      for _, r in ipairs(rows) do
        if r.port_in and r.used > 0 then
          warnings[#warnings + 1] = string.format("universe %d: a DMX input port is mapped here and %d fixtures are patched on it; incoming DMX drives them until something else takes over (ma3_ports names the port)", r.universe, r.used)
        end
        if r.parked > 0 then warnings[#warnings + 1] = string.format("universe %d: %d parked channels", r.universe, r.parked) end
        if r.tester > 0 then warnings[#warnings + 1] = string.format("universe %d: %d channels held by the DMX tester", r.universe, r.tester) end
      end
      return { rows = rows, warnings = warnings, next_offset = next_offset, partial = partial or false }
    end,
  }

  tools.ma3_ports = {
    description = "Physical DMX ports of every station in the session: stations=[{name, kind (Console, onPC, PU, NetworkNode), ip, type, in_my_session, ports=[{port (A..H), mode (Out / In / ...), universe, merge, priority (inputs), failure_mode, fixtures_on_universe}]}]. warnings names every input port mapped onto a universe with patched fixtures: incoming DMX on that port drives those fixtures. Device configuration is stored in each station, not in the show file. Read-only.",
    inputSchema = { type = "object", properties = {} },
    handler = function()
      c:start_slice()
      local dc = child_of_class(c:root(), "DeviceConfigurations")
      local stations_root = dc and child_of_class(dc, "OutputStations")
      if not stations_root then return nil, "no DeviceConfigurations > OutputStations on this console" end
      if c.guard then
        local ok, why = c.guard:allow_handle(stations_root, true)   -- read-only branch: no address reaches it
        if not ok then return nil, why end
        c.guard:target(stations_root)
      end
      local pool = universes_pool(c)
      local stations, warnings = {}, {}
      for _, collect in ipairs(stations_root:Children()) do
        local kind = name_of(collect)
        for _, st in ipairs(collect:Children()) do
          local row = { name = name_of(st), kind = kind, ip = prop(st, "IP"), type = prop(st, "TYPE"),
            in_my_session = prop(st, "INMYSESSION"), ports = {} }
          local cfg = child_of_class(st, "OutputConfiguration")
          if cfg then
            for _, letter in ipairs(PORT_LETTERS) do
              local mode = prop(cfg, "MODE" .. letter)
              if mode ~= nil then
                local port = { port = letter, mode = mode, universe = num(prop(cfg, "XLR" .. letter)),
                  merge = prop(cfg, "MERGE" .. letter), priority = prop(cfg, "PRIO" .. letter), failure_mode = prop(cfg, "FAILUREMODE" .. letter) }
                local u = pool and port.universe and pool:Ptr(port.universe)
                if u then port.fixtures_on_universe = num(prop(u, "USED")) or 0 end
                if tostring(mode) == "In" and (port.fixtures_on_universe or 0) > 0 then
                  warnings[#warnings + 1] = string.format("%s port %s is a DMX input on universe %d (%s), where %d fixtures are patched: whatever feeds that port drives them",
                    tostring(row.name), letter, port.universe, tostring(port.priority or "?"), port.fixtures_on_universe)
                end
                row.ports[#row.ports + 1] = port
              end
            end
          end
          stations[#stations + 1] = row
          c:pace()
        end
      end
      return { stations = stations, warnings = warnings }
    end,
  }

  local function command_lines()
    local temp = child_of_class(c:root(), "Temp")
    local pool = temp and child_of_class(temp, "Cmdlines")
    local out = {}
    if pool then
      for _, cl in ipairs(pool:Children()) do
        out[#out + 1] = { name = name_of(cl), user = prop(cl, "USER"), profile = prop(cl, "PROFILE") }
      end
    end
    return out
  end

  local function export_part(part)
    local fs = deps.fs
    if not fs or not fs.read then return nil, "no filesystem access in this build" end
    local dir, file = c:path("Temp"), "ma3_mcp_programmer.xml"
    local ok, res = pcall(function() return part:Export(dir, file) end)
    if not ok or res == false then return nil, "export failed" end
    for _, cand in ipairs({ dir .. "/" .. file, dir .. "/" .. file .. ".xml" }) do
      local data = fs.read(cand)
      if data then return #data > 200000 and data:sub(1, 200000) or data end
    end
    return nil, "export reported success but no file appeared"
  end

  local function environment_row(env, active_name, with_values)
    local name = name_of(env)
    local row = { name = name, active = name == active_name }
    local prog = env:Ptr(PROGRAMMER_SLOT)
    if class_is(prog, "Programmer") and may_read(prog) then
      local parts, bytes = {}, 0
      for _, part in ipairs(prog:Children()) do
        if class_is(part, "ProgPart") and may_read(part) then
          local b = num(prop(part, "MEMORYFOOTPRINT")) or 0
          local p = { part = num(prop(part, "PART")), name = name_of(part), bytes = b }
          if with_values and b > M.EMPTY_PART_BYTES then p.xml, p.xml_error = export_part(part) end
          parts[#parts + 1] = p
          bytes = bytes + b
        end
      end
      row.programmer = { parts = parts, bytes = bytes, empty = bytes <= #parts * M.EMPTY_PART_BYTES }
    end
    local sel = env:Ptr(math.floor(num(prop(env, "ACTIVESELINDEX")) or 1))
    if class_is(sel, "Selection") and may_read(sel) then
      row.selection = { selected = num(prop(sel, "COUNTTOTALSELECTED")) or 0, fully_selected = num(prop(sel, "COUNTFULLYSELECTED")) or 0,
        active = prop(sel, "ACTIVE") == true }
    end
    return row
  end

  tools.ma3_programmer = {
    description = "What every user has in the programmer and the selection right now: profiles=[{profile, name, command_lines, environments=[{name (Normal / Preview), active, programmer={empty, bytes, parts=[{part, name, bytes}]}, selection={selected, fully_selected, active}}]}]. holding_values lists every profile and environment whose programmer is not empty. plugin = the command line this plugin types on, its profile, and programmer_empty: when false, a Store sent through ma3_command would take those values (copy an empty object instead, or wait). {profile:n} reads one profile. {values:true} adds the XML of each part that holds values (fixtures, attributes, values). The programmer belongs to the operator: read again before acting on it. Read-only.",
    inputSchema = { type = "object", properties = { profile = { type = "integer" }, values = { type = "boolean" } } },
    handler = function(args)
      args = args or {}
      c:start_slice()
      local sd = c:showdata()
      local pool = sd and child_of_class(sd, "UserProfiles")
      if not pool then return nil, "no UserProfiles in this show" end
      local wanted = args.profile and math.floor(num(args.profile) or 0) or nil
      local lines = command_lines()
      local profiles, holding = {}, {}
      for _, up in ipairs(pool:Children()) do
        local no = num(prop(up, "NO"))
        if wanted == nil or no == wanted then
          local addr = up:ToAddr()
          local row = { profile = addr, no = no, name = name_of(up), command_lines = {}, environments = {} }
          for _, cl in ipairs(lines) do if cl.profile == addr then row.command_lines[#row.command_lines + 1] = cl.name end end
          local envs = up:Ptr(ENVIRONMENTS_SLOT)
          if class_is(envs, "Environments") then
            local okE, whyE = may_read(envs)
            if not okE then return nil, whyE end
            local active_name = prop(envs, "ACTIVEENVIRONMENT")
            for _, env in ipairs(envs:Children()) do
              if class_is(env, "UserEnvironment") and may_read(env) then
                local e = environment_row(env, active_name, args.values == true)
                row.environments[#row.environments + 1] = e
                if e.programmer and not e.programmer.empty then holding[#holding + 1] = addr .. " " .. tostring(e.name) end
              end
              c:pace()
            end
          end
          profiles[#profiles + 1] = row
        end
      end
      if wanted and #profiles == 0 then return nil, "user profile not found: " .. tostring(wanted) end
      local plugin
      if lines[1] then
        plugin = { command_line = lines[1].name, user = lines[1].user, profile = lines[1].profile }
        for _, p in ipairs(profiles) do
          if p.profile == plugin.profile then
            for _, e in ipairs(p.environments) do
              if e.active and e.programmer then plugin.programmer_empty = e.programmer.empty end
            end
          end
        end
      end
      return { profiles = profiles, holding_values = holding, plugin = plugin }
    end,
  }

  -- Playback masters rest at 100 and timing masters at 0: at rest they are left out unless {all}.
  local REST = { MasterPoolPlayback = 100, MasterPoolTiming = 0 }

  tools.ma3_masters = {
    description = "Every master and its level: pools=[{pool (Selected, Grand, Speed, Playback, Timing), address, masters=[{no, name, address, level (percent, the console's NormedValue), fader_enabled}]}], plus grand_master (the level of Grand 'Master'). Playback and timing masters at rest (100 / 0) are left out; {all:true} lists every slot; {pool:'Grand'} reads one pool. Levels move while the operator works: read again before acting. Read-only.",
    inputSchema = { type = "object", properties = { pool = { type = "string" }, all = { type = "boolean" } } },
    handler = function(args)
      args = args or {}
      c:start_slice()
      local sd = c:showdata()
      local root = sd and child_of_class(sd, "Masters")
      if not root then return nil, "no Masters in this show" end
      local want = args.pool and tostring(args.pool):lower() or nil
      local pools, grand_master = {}, nil
      for _, pool in ipairs(root:Children()) do
        local pname, pclass = name_of(pool), pool:GetClass()
        if want == nil or tostring(pname):lower() == want then
          local row = { pool = pname, address = pool:ToAddr(), masters = {} }
          for _, m in ipairs(pool:Children()) do
            local level = num(prop(m, "NORMEDVALUE"))
            if args.all or REST[pclass] == nil or level ~= REST[pclass] then
              row.masters[#row.masters + 1] = { no = num(prop(m, "NO")), name = name_of(m), address = m:ToAddr(), level = level,
                fader_enabled = num(prop(m, "FADERENABLE")) == 1 }
            end
            if pclass == "MasterPoolGrand" and name_of(m) == "Master" then grand_master = level end
            c:pace()
          end
          pools[#pools + 1] = row
        end
      end
      if want and #pools == 0 then return nil, "no master pool named " .. tostring(args.pool) end
      return { pools = pools, grand_master = grand_master }
    end,
  }

  -- API reads: functions of the console's Lua API rather than objects, so the guard's class-path
  -- rules cannot judge them. Benched on onPC 2026-11-21. On a console they are refused until the
  -- supervised first call there ({console_ok:true}, outside a service); the journal names the call,
  -- so a stall is quarantined at the next start.
  local function api_gate(args, tool, ...)
    for _, fn in ipairs({ ... }) do
      if type(c.api[fn]) ~= "function" then return nil, "this console build does not offer " .. fn .. "()" end
    end
    if c.guard and c.guard.console then
      if not (args and args.console_ok == true) then
        return nil, "[console-guard] " .. tool .. " is proven on onPC only; call it through onPC, or pass console_ok for the supervised first call on the console"
      end
      c.guard:target("api > " .. tool)
    end
    return true
  end
  local function addr_of(h) if h == nil then return nil end local ok, a = pcall(function() return h:ToAddr() end) return ok and a or nil end
  local function call(fn, ...) local ok, v = pcall(c.api[fn], ...) if ok then return v end return nil end
  local FULL = 16777215   -- channel values are 24 bit
  local function pct(v) v = num(v) if not v then return nil end return math.floor(v / FULL * 1000 + 0.5) / 10 end

  tools.ma3_selection = {
    description = "The fixtures selected right now by the user this plugin runs as, in selection order: {selected, fixtures=[{sf_index, fid, cid, name, address}], truncated, user, profile}. {limit} caps the list (default 1000, max 5000). Other users' selections: ma3_programmer gives their counts. The selection moves while the operator works: read again before acting. Read-only.",
    inputSchema = { type = "object", properties = { limit = { type = "integer" }, console_ok = { type = "boolean" } } },
    handler = function(args)
      args = args or {}
      local ok, why = api_gate(args, "ma3_selection", "SelectionFirst", "SelectionNext", "SelectionCount", "GetSubfixture")
      if not ok then return nil, why end
      c:start_slice()
      local limit = math.min(5000, math.max(1, math.floor(num(args.limit) or 1000)))
      local rows, i = {}, call("SelectionFirst")
      local truncated = false
      while i do
        if #rows >= limit then truncated = true break end
        local sf = call("GetSubfixture", i)
        local row = { sf_index = i }
        if sf then row.fid = num(prop(sf, "FID")); row.cid = num(prop(sf, "CID")); row.name = name_of(sf); row.address = addr_of(sf) end
        rows[#rows + 1] = row
        i = call("SelectionNext", i)
        c:pace()
      end
      return { selected = num(call("SelectionCount")) or #rows, fixtures = rows, truncated = truncated,
        user = addr_of(call("CurrentUser")), profile = addr_of(call("CurrentProfile")) }
    end,
  }

  tools.ma3_dmx = {
    description = "What one DMX universe carries right now, as this station computes it: {universe, unit (dmx 0-255, or percent with percent:true), nonzero, values=[{address, value}] for every address that is not 0}. {all:true} returns values as the plain list of all 512. An error means the universe is not granted or out of range. For one fixture's attributes use ma3_values. Output moves: read again before acting. Read-only.",
    inputSchema = { type = "object", required = { "universe" }, properties = { universe = { type = "integer" }, percent = { type = "boolean" }, all = { type = "boolean" }, console_ok = { type = "boolean" } } },
    handler = function(args)
      args = args or {}
      local ok, why = api_gate(args, "ma3_dmx", "GetDMXUniverse")
      if not ok then return nil, why end
      local u = num(args.universe)
      if not u then return nil, "universe is required (1 to 1024)" end
      u = math.floor(u)
      local t = call("GetDMXUniverse", u, args.percent == true)
      if type(t) ~= "table" then return nil, "universe " .. u .. " is not granted or out of range" end
      local values, nonzero = {}, 0
      for a = 1, 512 do
        local v = num(t[a]) or 0
        if v ~= 0 then nonzero = nonzero + 1 end
        if args.all then values[a] = v elseif v ~= 0 then values[#values + 1] = { address = a, value = v } end
      end
      return { universe = u, unit = args.percent == true and "percent" or "dmx", nonzero = nonzero, values = values }
    end,
  }

  tools.ma3_values = {
    description = "What one fixture is doing right now, per channel: {fixture, name, channels=[{attribute, universe, address (of the coarse channel; virtual:true when the channel has no DMX address), programmed (percent before the masters), value (percent after the masters: what goes out), default (percent), flags (highlight, lowlight, solo, group_master, additive_master when set)}]}. {fixture: FID} or {address:'Fixture 101.2'} for a sub-fixture. It does not say which cue or programmer owns a value. Read-only.",
    inputSchema = { type = "object", properties = { fixture = { type = "integer" }, address = { type = "string" }, console_ok = { type = "boolean" } } },
    handler = function(args)
      args = args or {}
      local ok, why = api_gate(args, "ma3_values", "GetRTChannels", "GetRTChannel", "GetAttributeByUIChannel")
      if not ok then return nil, why end
      local address = args.address or (args.fixture and ("Fixture " .. math.floor(num(args.fixture) or 0)))
      if not address then return nil, "fixture (FID) or address is required" end
      c:start_slice()
      local h, err = c:resolve(address)
      if not h then return nil, err end
      local list = call("GetRTChannels", h, false)
      if type(list) ~= "table" then return nil, "no channels for " .. address end
      local channels = {}
      for _, idx in ipairs(list) do
        local r = call("GetRTChannel", idx)
        if type(r) == "table" then
          local attr = r.ui_index_first and call("GetAttributeByUIChannel", r.ui_index_first)
          local row = { attribute = attr and attr.name or nil, default = pct(r.dmx_default) }
          local coarse = r.patch and num(r.patch.coarse)
          if coarse and coarse >= 0 then row.universe = coarse // 512 + 1; row.address = coarse % 512 + 1 else row.virtual = true end
          local info = r.info or {}
          row.programmed = pct(info.value_before_master); row.value = pct(info.value_after_master)
          local flags = {}
          for _, f in ipairs({ "highlight", "lowlight", "solo", "group_master", "additive_master" }) do
            if info.flags and num(info.flags[f]) and num(info.flags[f]) ~= 0 then flags[#flags + 1] = f end
          end
          row.flags = flags
          channels[#channels + 1] = row
        end
        c:pace()
      end
      return { fixture = addr_of(h), name = name_of(h), channels = channels }
    end,
  }

  tools.ma3_user = {
    description = "Who this plugin is working as, and what that user has in hand: {user, user_name, profile, environment (Normal / Preview), page, page_name (the current executor page), selected_sequence, selected_layout, selected_timecode, selection_count, show_needs_save}. Commands sent through ma3_command run as this user, in this user's programmer and selection. Read-only.",
    inputSchema = { type = "object", properties = { console_ok = { type = "boolean" } } },
    handler = function(args)
      local ok, why = api_gate(args, "ma3_user", "CurrentUser", "CurrentProfile")
      if not ok then return nil, why end
      local function opt(fn) if type(c.api[fn]) == "function" then return call(fn) end return nil end
      local user, page, env = call("CurrentUser"), opt("CurrentExecPage"), opt("CurrentEnvironment")
      local seq = opt("SelectedSequence")
      return { user = addr_of(user), user_name = user and user.name or nil, profile = addr_of(call("CurrentProfile")),
        environment = env and env.name or nil, page = addr_of(page), page_name = page and page.name or nil,
        selected_sequence = addr_of(seq), selected_sequence_name = seq and seq.name or nil,
        selected_layout = addr_of(opt("SelectedLayout")), selected_timecode = addr_of(opt("SelectedTimecode")),
        selection_count = num(opt("SelectionCount")), show_needs_save = opt("NeedShowSave") }
    end,
  }
end

return M
