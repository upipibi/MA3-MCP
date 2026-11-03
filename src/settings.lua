-- Plugin settings persisted as JSON through an injected fs {read, write}.
local json = require("json")
local auth = require("auth")

local M = {}

local function defaults(rand)
  return { pin = auth.new_pin(rand), port = 9800, bind = nil, display = 1, lua_default = false, backups = {}, clients = {} }
end

local function valid_pin(p)
  return type(p) == "string" and #p == auth.PIN_LENGTH and p:match("^[" .. auth.ALPHABET .. "]+$") ~= nil
end

function M.load(fs, path, rand)
  local d = defaults(rand)
  local raw = fs.read(path)
  if not raw then d.generated = true return d end
  local ok, t = pcall(json.decode, raw)
  if not ok or type(t) ~= "table" then d.generated = true return d end
  if valid_pin(t.pin) then d.pin = t.pin end
  if math.type(t.port) == "integer" and t.port > 0 and t.port < 65536 then d.port = t.port end
  if type(t.bind) == "string" and t.bind ~= "" then d.bind = t.bind end
  if math.type(t.display) == "integer" and t.display >= 1 then d.display = t.display end
  if type(t.lua_default) == "boolean" then d.lua_default = t.lua_default end
  if type(t.backups) == "table" then d.backups = t.backups end
  if type(t.clients) == "table" then d.clients = t.clients end
  return d
end

-- Deterministic encoding (sorted keys, arrays by index) so the file is byte-for-byte
-- stable across saves; rxi json's pairs() order is not.
local function is_array(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n == #t
end

local function encode(v)
  if type(v) ~= "table" then return json.encode(v) end
  if is_array(v) then
    local parts = {}
    for i = 1, #v do parts[i] = encode(v[i]) end
    return "[" .. table.concat(parts, ",") .. "]"
  end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = json.encode(k) .. ":" .. encode(v[k]) end
  return "{" .. table.concat(parts, ",") .. "}"
end
M.encode = encode

local KEYS = { "pin", "port", "bind", "display", "lua_default", "backups", "clients" }

function M.save(fs, path, s)
  local parts = {}
  for _, k in ipairs(KEYS) do
    if s[k] ~= nil then parts[#parts + 1] = json.encode(k) .. ":" .. encode(s[k]) end
  end
  return fs.write(path, "{" .. table.concat(parts, ",") .. "}\n")
end

return M
