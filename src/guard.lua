-- Console guard: keeps the plugin from touching anything on a console that is not proven safe
-- there, records every request in a black-box journal so a stall is identified and refused at
-- the next start, and caps the request rate on a console.
--
-- Why: 2026-11-08, during a Sunday service, one read from a client script that walked the whole
-- object tree never returned. A plugin runs on the console's screen thread, so the GUI froze
-- (playback and timecode kept running) until the console was restarted mid-service. A plugin
-- cannot interrupt a console call that hangs; it can only avoid making it.
-- Design: docs/superpowers/specs/2026-11-08-console-guard-design.md
local json = require("json")

local keywords = require("keywords")
local M = {}
M.__index = M
M.TAG = "[console-guard]"

-- Branches of the object tree (class paths below Root) proven safe on the console.
-- First matching rule wins. "exact" = that object only; "subtree" = it and everything below;
-- "deny" = refuse it and everything below. A branch is added here only after it has been read
-- on onPC with the journal on (record it in docs/research/2026-11-onpc-facts.md).
M.RULES = {
  { "", "exact" },                                        -- Root itself (class names of its children)
  { "ShowData > UserProfiles", "exact" },
  { "ShowData > UserProfiles > UserProfile", "exact" },
  { "ShowData > UserProfiles", "deny" },                  -- window settings, status center: unproven
  { "ShowData", "subtree" },                              -- pools, patch, timecode, agenda: every job
  { "Temp", "exact" },
  { "Temp > Cmdlines", "exact" },
  { "Temp > Cmdlines > Cmdline", "exact" },
  { "Temp > Cmdlines > Cmdline > Undos", "subtree" },     -- ma3_history
  { "Temp > DriveCollect", "subtree" },                   -- drives (2026-11-08 curve job)
  { "TimecodeSlots", "subtree" },                         -- Cue Display reads these every frame
  { "MAnetSocket", "exact" },                             -- show name for ma3_status
}
-- Branches a tool may read by itself but no address may reach: tools that take an address
-- (ma3_object, ma3_set, ma3_children, ...) never get these, so nothing can be written there.
-- DMX ports of every station in the session (ma3_ports). Read on onPC 2026-11-19, journal on,
-- while it was in the console's session: OutputStations > collect > station > OutputConfiguration.
-- DMXProtocols (sACN, Art-Net) next to it is not read yet and stays refused.
M.READ_RULES = {
  { "DeviceConfigurations", "exact" },
  { "DeviceConfigurations > OutputStations", "subtree" },
}
-- Root children that may be named by number in an address or command ("Root 14.9.9.5"):
-- ShowData. Temp (20) is allowed by class after resolve, not by number in a command.
M.ROOT_NUMBERS_IN_COMMANDS = { [14] = true }
M.ROOT_NUMBERS_IN_ADDRESSES = { [14] = true, [20] = true }

M.RATE_PER_S = 8
M.RATE_BURST = 16

function M.new(o)
  local self = setmetatable({}, M)
  self.console = o.console and true or false
  self.fs = o.fs
  self.journal_path = o.journal_path
  self.quarantine = o.quarantine or {}
  self.now = o.now or os.time
  self.log = o.log or function() end
  self.tokens = M.RATE_BURST
  self.last_refill = nil
  return self
end

local function path_string(list) return table.concat(list, " > ") end

-- Class names from just below Root down to the object. Uses Parent() and GetClass() only.
function M:class_path(handle)
  local list, h, guard_n = {}, handle, 0
  while h and guard_n < 40 do
    guard_n = guard_n + 1
    local ok, cls = pcall(function() return h:GetClass() end)
    if not ok or cls == nil or cls == "Root" then break end
    table.insert(list, 1, cls)
    local okp, parent = pcall(function() return h:Parent() end)
    if not okp or parent == nil or parent == h then break end
    h = parent
  end
  return list
end

local function quarantined(self, field, value)
  if value == nil then return nil end
  for _, q in ipairs(self.quarantine) do
    if q[field] ~= nil and q[field] == value then return q end
  end
  return nil
end

local function quarantine_msg(q)
  return string.format("%s quarantined: the console stopped during %s %s on %s; refused until cleared on the console (Plugin \"MA3 MCP\" \"quarantine clear\")",
    M.TAG, tostring(q.tool), tostring(q.address or q.path or q.args or ""), tostring(q.when or "?"))
end

local function rules_allow(rules, ps)
  for _, r in ipairs(rules) do
    local base, kind = r[1], r[2]
    local match_exact = (ps == base)
    local match_under = (base == "" and ps ~= "") or (ps:sub(1, #base + 3) == base .. " > ")
    if kind == "exact" and match_exact then return true end
    if kind == "subtree" and (match_exact or match_under) then return true end
    if kind == "deny" and (match_exact or match_under) then break end
  end
  return false
end

-- Decision for a class path (list). Console: allow-list; onPC: everything. Quarantine always.
-- tool_read = true is for a read-only tool walking a branch by itself (M.READ_RULES); address
-- resolution never passes it.
function M:allow_path(list, tool_read)
  local ps = path_string(list)
  local q = quarantined(self, "path", ps)
  if q then return false, quarantine_msg(q) end
  if not self.console then return true end
  if rules_allow(M.RULES, ps) then return true end
  if tool_read and rules_allow(M.READ_RULES, ps) then return true end
  return false, string.format("%s Root > %s is not proven safe on the console; explore it on onPC first",
    M.TAG, ps == "" and "(root)" or ps)
end

function M:allow_handle(handle, tool_read)
  local list = self:class_path(handle)
  local ok, why = self:allow_path(list, tool_read)
  return ok, why, list
end

-- Before resolving an address: quarantine by address, and Root numbers on a console.
function M:allow_address(address)
  local norm = tostring(address):gsub("^%s+", ""):gsub("%s+$", "")
  local q = quarantined(self, "address", norm)
  if q then return false, quarantine_msg(q) end
  if self.console then
    local n = norm:match("^[Rr][Oo][Oo][Tt]%s+(%d+)")
    if n and not M.ROOT_NUMBERS_IN_ADDRESSES[tonumber(n)] then
      return false, string.format("%s Root %s is not proven safe on the console; explore it on onPC first", M.TAG, n)
    end
  end
  return true
end

-- Object keywords whose objects live outside show data: stations and session, the station's
-- settings and displays, and the operator's user profile (views, screens, encoder bars, readouts,
-- colour theme). Shortcuts from the MA 2.5 keyword pages.
M.OUTSIDE_SHOWDATA_KEYWORDS = {
  { "stationsettings", "stations" }, { "station", "stat" }, { "console", "cons" }, { "onpc", "onp" },
  { "networknode", "networkn", { "node" } }, { "processingunit", "processingu", { "pu" } },
  { "extension", "exte" }, { "interface", "inter" }, { "session", "ses" }, { "ndi", "nd" },
  { "rdm", "rd" }, { "display", "disp" }, { "messagecenter", "mes" }, { "remotehid", "remoteh" },
  { "view", "v" }, { "viewbutton", "viewb", { "vb" } }, { "screencontent", "scre" },
  { "screenconfiguration", "screenconf" }, { "userprofile", "userp", { "upr" } },
  { "currentuserprofile", "currentu", { "cup" } }, { "camera", "cam" }, { "renderquality", "renderq" },
  { "encoderbar", "en" }, { "encoderbank", "encoderban" }, { "keyboard", "keyb" },
  { "keyboardshortcut", "keyboards" }, { "readout", "rea" }, { "dmxreadout", "dmxr" },
  { "color", "color" }, { "colortheme", "col" }, { "colordefinition", "colord" },
}

-- A command on a console may name Root only for ShowData (Root 14), and may not use an object
-- keyword that reaches outside show data. Quoted names do not count.
function M:allow_command(cmd)
  if not self.console then return true end
  local bare = keywords.unquote(cmd)
  for n in bare:gmatch("[Rr][Oo][Oo][Tt]%s+(%d+)") do
    if not M.ROOT_NUMBERS_IN_COMMANDS[tonumber(n)] then
      return false, string.format("%s commands may address Root 14 (ShowData) only on the console; Root %s is not proven safe", M.TAG, n)
    end
  end
  for _, w in ipairs(keywords.words(bare)) do
    local kw = keywords.match(w, M.OUTSIDE_SHOWDATA_KEYWORDS)
    if kw then
      return false, string.format("%s '%s' (%s) reaches outside show data (stations, settings or the operator's screens); commands on the console stay in show data. Explore it on onPC first", M.TAG, w, kw)
    end
  end
  return true
end

local function args_key(args)
  if type(args) ~= "table" then return tostring(args or "") end
  local keys = {}
  for k in pairs(args) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do
    local v = args[k]
    parts[#parts + 1] = json.encode(k) .. ":" .. (type(v) == "table" and "[table]" or json.encode(v))
  end
  return "{" .. table.concat(parts, ",") .. "}"
end
M.args_key = args_key

-- A tool call quarantined by tool + arguments (a stall in a call without an address).
function M:admit_call(tool, args)
  local key = tool .. " " .. args_key(args)
  local q = quarantined(self, "call", key)
  if q then return false, quarantine_msg(q) end
  return true
end

-- Token bucket, console only.
function M:admit()
  if not self.console then return true end
  local now = self.now()
  if self.last_refill == nil then self.last_refill = now end
  local dt = now - self.last_refill
  if dt > 0 then
    self.tokens = math.min(M.RATE_BURST, self.tokens + dt * M.RATE_PER_S)
    self.last_refill = now
  end
  if self.tokens >= 1 then self.tokens = self.tokens - 1 return true end
  return false, string.format("%s too many requests; slow down (at most %d a second on the console)", M.TAG, M.RATE_PER_S)
end

-- Black-box journal ---------------------------------------------------------------------------

local function write_journal(self, t)
  if not (self.fs and self.journal_path) then return end
  pcall(self.fs.write, self.journal_path, json.encode(t))
end

function M:begin(tool, args)
  self.current = { tool = tool, address = type(args) == "table" and type(args.address) == "string" and args.address or nil,
    args = args_key(args), started = self.now() }
  self.t0 = self.now()
  write_journal(self, self.current)
end

-- What the request is touching now: a handle (class path recorded) or a short text.
function M:target(what)
  if not self.current then return end
  if type(what) == "string" then self.current.path = what
  else self.current.path = path_string(self:class_path(what)) end
  write_journal(self, self.current)
end

-- Returns the request's duration in seconds.
function M:finish()
  local dt = self.t0 and (self.now() - self.t0) or 0
  write_journal(self, { done = true, last = self.current and self.current.tool })
  self.current, self.t0 = nil, nil
  return dt
end

-- At plugin start: an unfinished journal means the console stopped (froze, crashed, was
-- restarted) during that request. Quarantine it and close the journal. Returns the entry or nil.
function M.recover(fs, path, quarantine, when)
  if not (fs and path) then return nil end
  local raw = fs.read(path)
  if not raw then return nil end
  local ok, j = pcall(json.decode, raw)
  if not ok or type(j) ~= "table" or j.done or not j.tool then return nil end
  local entry = { tool = j.tool, address = j.address, path = j.path, when = when or j.started }
  if not j.address and not j.path then entry.call = j.tool .. " " .. tostring(j.args or "{}") end
  quarantine[#quarantine + 1] = entry
  pcall(fs.write, path, json.encode({ done = true, recovered = j.tool }))
  return entry
end

return M
