-- Thin wrapper over the grandMA3 Lua API so tools can be tested with a fake.
-- console.new(api) takes a table of the globals it uses; console.real() reads them from _G.
local M = {}
M.__index = M

local NAMES = { "ObjectList", "Cmd", "CmdIndirect", "CreateUndo", "CloseUndo", "Root", "DataPool", "ShowData",
  "Patch", "Version", "HostType", "GetPath", "Echo", "Printf", "DirList", "Enums", "GetSubfixtureCount" }

function M.new(api)
  local self = setmetatable({}, M)
  self.api = api
  self.yield_fn = api.yield or function() coroutine.yield() end
  self.now_fn = api.now or (function() local s = package.loaded.socket return s and s.gettime or os.time end)()
  return self
end

function M.real()
  local api = {}
  for _, n in ipairs(NAMES) do api[n] = _G[n] end
  local socket = require("socket")
  api.yield = function() coroutine.yield() end
  api.now = socket.gettime
  return M.new(api)
end

-- Single object lookup: nil when the address resolves to nothing.
function M:object(address)
  local list = self.api.ObjectList(address)
  if type(list) ~= "table" then return nil end
  return list[1]
end

function M:cmd(text, undo) return self.api.Cmd(text, undo) end
function M:cmd_indirect(text) return self.api.CmdIndirect(text) end
function M:create_undo(name) return self.api.CreateUndo(name) end
function M:close_undo(u) return self.api.CloseUndo(u) end
function M:root() return self.api.Root() end
function M:datapool() return self.api.DataPool() end
function M:showdata() return self.api.ShowData() end
function M:patch() return self.api.Patch() end
function M:version() return self.api.Version and self.api.Version() or "?" end
function M:host_type() return self.api.HostType and self.api.HostType() or "?" end
function M:path(kind) return self.api.GetPath(self.api.Enums.PathType[kind]) end
function M:dirlist(path, pattern) return self.api.DirList(path, pattern) end
function M:echo(fmt, ...)
  local s = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
  if self.api.Printf then self.api.Printf(s) elseif self.api.Echo then self.api.Echo(s) end
end
function M:yield() return self.yield_fn() end
function M:now() return self.now_fn() end

-- The show name from the MAnetSocket object (SHOWFILE), nil if unavailable.
function M:show_name()
  local ok, v = pcall(function()
    local root = self:root()
    local sock = root and (root.maNetSocket or root.MAnetSocket)
    if not sock then
      for _, ch in ipairs(root:Children()) do if ch:GetClass() == "MAnetSocket" then sock = ch break end end
    end
    return sock and (sock:Get("SHOWFILE"))
  end)
  if ok and v ~= nil and v ~= "" then return tostring(v) end
  return nil
end

-- Property value as JSON-friendly data: handles become addresses, empties nil.
function M.render(v)
  if v == nil then return nil end
  local t = type(v)
  if t == "string" or t == "number" or t == "boolean" then return v end
  if t == "userdata" or t == "table" then
    local ok, addr = pcall(function() return v:ToAddr() end)
    if ok and addr then return addr end
    local ok2, s = pcall(tostring, v)
    return ok2 and s or "?"
  end
  return tostring(v)
end

-- Reads one property safely (Get may return no value, may error on exotic types).
function M.get(handle, name)
  local ok, v = pcall(function() return (handle:Get(name)) end)
  if not ok then return nil end
  return M.render(v)
end

function M.properties(handle, with_schema)
  local props, schema = {}, with_schema and {} or nil
  local n = handle:PropertyCount()
  for i = 1, n do
    local name = handle:PropertyName(i)
    local v = M.get(handle, name)
    if v ~= nil and v ~= "" then props[name] = v end
    if schema then
      local ok, t = pcall(function() return handle:PropertyType(i) end)
      schema[i] = { name = name, type = ok and tostring(t) or "?" }
    end
  end
  return props, schema
end

function M.child_summary(handle, index)
  local no = M.get(handle, "NO")
  return { index = index, class = handle:GetClass(), name = handle.name, no = no, address = handle:ToAddr() }
end

return M
