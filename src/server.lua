-- Non-blocking HTTP socket server driven by step(): one pass per call, never blocks.
-- Accepts a few clients per pass, buffers reads, serves the oldest complete request,
-- flushes pending output, drops idle or finished clients.
local http = require("http")

local M = {}
M.__index = M

function M.new(opts)
  local self = setmetatable({}, M)
  self.bind_host = opts.bind or "127.0.0.1"
  self.port = opts.port or 9800
  self.socket = opts.socket or require("socket")
  self.now = opts.now or self.socket.gettime
  self.handler = opts.handler
  self.idle_timeout = opts.idle_timeout or 5
  self.log = opts.log or function() end
  self.clients = {}
  self.stats = { requests = 0, bad_requests = 0, clients_now = 0 }
  self.running = false
  self.last_step = nil
  return self
end

function M:start()
  local s, err = self.socket.bind(self.bind_host, self.port)
  if not s then return nil, err end
  s:settimeout(0)
  self.server = s
  self.running = true
  return true
end

function M:address()
  return self.bind_host, self.port
end

local function close_client(self, i, why)
  local c = self.clients[i]
  pcall(function() c.sock:close() end)
  table.remove(self.clients, i)
  if why then self.log("client %s closed: %s", tostring(c.ip), why) end
end

function M:stop()
  for i = #self.clients, 1, -1 do close_client(self, i, "shutdown") end
  if self.server then pcall(function() self.server:close() end) end
  self.server = nil
  self.running = false
end

local function accept_new(self)
  for _ = 1, 4 do
    local sock = self.server:accept()
    if not sock then break end
    sock:settimeout(0)
    pcall(function() sock:setoption("tcp-nodelay", true) end)
    local ip = "?"
    pcall(function() ip = select(1, sock:getpeername()) or "?" end)
    self.clients[#self.clients + 1] = { sock = sock, ip = ip, buf = "", out = nil, out_i = 1, since = self.now(), done = false }
  end
end

local function read_client(self, c)
  local data, err, partial = c.sock:receive(4096)
  local chunk = data or partial
  if chunk and #chunk > 0 then c.buf = c.buf .. chunk end
  if err == "closed" then c.peer_closed = true end
end

local function respond(c, status, headers, body)
  c.out = http.response(status, headers, body)
  c.out_i = 1
  c.done = true
end

local function flush(self, i)
  local c = self.clients[i]
  if not c.out then return end
  local sent, err, last = c.sock:send(c.out, c.out_i)
  if sent then
    c.out = nil
    close_client(self, i)
  elseif err == "timeout" then
    c.out_i = (last or (c.out_i - 1)) + 1
  else
    close_client(self, i, "send failed: " .. tostring(err))
  end
end

function M:step()
  if not self.running then return end
  accept_new(self)

  -- read everything available
  for _, c in ipairs(self.clients) do
    if not c.done then read_client(self, c) end
  end

  -- parse; serve the oldest complete request only
  local served = false
  for i, c in ipairs(self.clients) do
    if not c.done then
      local req, st = http.parse(c.buf)
      if st == "ok" then
        if not served then
          served = true
          self.stats.requests = self.stats.requests + 1
          local ok, status, headers, body = pcall(self.handler, req, c.ip)
          if ok and type(status) == "number" then
            respond(c, status, headers or {}, body or "")
          else
            self.log("handler error: %s", tostring(status))
            respond(c, 500, { ["Content-Type"] = "text/plain" }, "internal error")
          end
        end
      elseif st == "bad" then
        self.stats.bad_requests = self.stats.bad_requests + 1
        respond(c, 400, { ["Content-Type"] = "text/plain" }, "bad request")
      elseif st == "too_large" then
        self.stats.bad_requests = self.stats.bad_requests + 1
        respond(c, 413, { ["Content-Type"] = "text/plain" }, "payload too large")
      end
    end
  end

  -- flush output, drop peer-closed and idle clients
  local now = self.now()
  for i = #self.clients, 1, -1 do
    local c = self.clients[i]
    if c.out then
      flush(self, i)
    elseif c.peer_closed then
      close_client(self, i, "peer closed")
    elseif now - c.since > self.idle_timeout then
      close_client(self, i, "idle")
    end
  end
  self.stats.clients_now = #self.clients
  self.last_step = now
end

return M
