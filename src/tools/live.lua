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

function M.register(tools, c, ctx)
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
end

return M
