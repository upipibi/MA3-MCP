-- PIN authentication, bad-PIN lockout per IP, and the recent-clients registry.
local M = {}
M.__index = M

M.ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
M.PIN_LENGTH = 8
M.MAX_BAD = 5          -- bad PINs ...
M.BAD_WINDOW = 60      -- ... within this many seconds ...
M.LOCK_SECONDS = 300   -- ... lock the IP for this long
M.MAX_CLIENTS = 10

function M.new_pin(rand)
  rand = rand or math.random
  local out = {}
  for i = 1, M.PIN_LENGTH do
    local k = rand(#M.ALPHABET)
    out[i] = M.ALPHABET:sub(k, k)
  end
  return table.concat(out)
end

function M.new(opts)
  local self = setmetatable({}, M)
  self.pin = opts.pin or M.new_pin(opts.rand)
  self.now = opts.now or os.time
  self.rand = opts.rand
  self.origin_allowed = opts.origin_allowed
  self.clients = {}
  self.bad = {}      -- ip -> list of timestamps
  self.locked = {}   -- ip -> unlock time
  return self
end

function M:regenerate()
  self.pin = M.new_pin(self.rand)
  return self.pin
end

local function find_client(self, ip)
  for i, c in ipairs(self.clients) do
    if c.ip == ip then return i, c end
  end
end

-- Moves (or inserts) the client to the front, bumps counters, trims to MAX_CLIENTS.
local function touch(self, ip, name, bad)
  local i, c = find_client(self, ip)
  if c then table.remove(self.clients, i) else c = { ip = ip, name = name, calls = 0, bad_pin = 0 } end
  if name then c.name = name end
  c.last_seen = self.now()
  if bad then c.bad_pin = c.bad_pin + 1 else c.calls = c.calls + 1 end
  table.insert(self.clients, 1, c)
  while #self.clients > M.MAX_CLIENTS do table.remove(self.clients) end
  return c
end

function M:record_client(ip, name)
  return touch(self, ip, name, false)
end

local function note_bad(self, ip)
  local now = self.now()
  local list = self.bad[ip] or {}
  local kept = {}
  for _, t in ipairs(list) do if now - t < M.BAD_WINDOW then kept[#kept + 1] = t end end
  kept[#kept + 1] = now
  self.bad[ip] = kept
  if #kept >= M.MAX_BAD then
    self.locked[ip] = now + M.LOCK_SECONDS
    self.bad[ip] = nil
  end
  touch(self, ip, nil, true)
end

-- Returns ok, http_status, reason.
function M:check(req, ip)
  local now = self.now()
  if self.locked[ip] then
    if now < self.locked[ip] then return false, 429, "locked" end
    self.locked[ip] = nil
  end
  local origin = req.headers and req.headers["origin"]
  if origin and origin ~= "" and self.origin_allowed and origin ~= self.origin_allowed then
    return false, 403, "origin"
  end
  local a = req.headers and req.headers["authorization"]
  if not a or a == "" then
    note_bad(self, ip)
    return false, 401, "missing"
  end
  local token = a:match("^[Bb]earer%s+(%S+)%s*$")
  if token ~= self.pin then
    note_bad(self, ip)
    return false, 401, "wrong"
  end
  return true, 200, "ok"
end

return M
