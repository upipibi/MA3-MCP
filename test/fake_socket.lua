-- A scripted stand-in for LuaSocket: non-blocking semantics only.
-- fs.new() -> module-like table with .bind(host, port), .gettime(); server:accept() pops
-- from fs.pending; clients are created with fs.client{chunks=...}.
local M = {}

local Client = {}
Client.__index = Client
function Client:settimeout(t) self.timeout = t end
function Client:setoption() return true end
function Client:getpeername() return self.ip, self.port end
function Client:receive(n)
  if self.closed then return nil, "closed" end
  local chunk = table.remove(self.chunks, 1)
  if chunk == nil then return nil, "timeout", "" end
  if chunk == "CLOSE" then self.closed_by_peer = true return nil, "closed", "" end
  return nil, "timeout", chunk   -- partial-return form, like a non-blocking socket
end
function Client:send(data, i)
  i = i or 1
  if self.closed then return nil, "closed" end
  local piece = data:sub(i)
  if self.send_limit and #piece > self.send_limit then
    self.sent = self.sent .. piece:sub(1, self.send_limit)
    return nil, "timeout", i + self.send_limit - 1
  end
  self.sent = self.sent .. piece
  return #data
end
function Client:close() self.closed = true end

function M.client(opts)
  return setmetatable({ chunks = opts.chunks or {}, sent = "", ip = opts.ip or "10.11.4.50", port = 50000,
    send_limit = opts.send_limit }, Client)
end

local Server = {}
Server.__index = Server
function Server:settimeout(t) self.timeout = t end
function Server:accept()
  local c = table.remove(self.fs.pending, 1)
  if not c then return nil, "timeout" end
  return c
end
function Server:getsockname() return self.host, self.port end
function Server:close() self.closed = true end

function M.new()
  local fs = { pending = {}, now = 1000.0 }
  fs.bind = function(host, port)
    if fs.fail_bind then return nil, fs.fail_bind end
    return setmetatable({ fs = fs, host = host, port = port }, Server)
  end
  fs.gettime = function() return fs.now end
  fs.feed = function(client, data) table.insert(client.chunks, data) end
  return fs
end

return M
