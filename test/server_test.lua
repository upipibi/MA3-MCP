local server = require("server")
local fake = require("fake_socket")
local h = require("helpers")

local REQ = "POST /mcp HTTP/1.1\r\nHost: x\r\ncontent-length: 2\r\n\r\n{}"

local function make(handler_fn)
  local fs = fake.new()
  local calls = {}
  local srv = server.new({
    bind = "127.0.0.1", port = 9800, socket = fs, now = fs.gettime, idle_timeout = 5,
    handler = function(req, ip)
      calls[#calls + 1] = { req = req, ip = ip }
      if handler_fn then return handler_fn(req, ip) end
      return 200, { ["Content-Type"] = "application/json" }, "{}"
    end,
  })
  h.truthy(srv:start())
  return fs, srv, calls
end

h.describe("server_assembles_split_request", function()
  local fs, srv, calls = make()
  local c = fake.client({ chunks = { "POST /mcp HTTP/1.1\r\nHost: x\r\ncontent-length: 2\r\n\r\n" } })
  table.insert(fs.pending, c)
  srv:step(); srv:step(); srv:step()
  h.eq(#calls, 0, "handler not called before the body arrives")
  fs.feed(c, "{}")
  srv:step()
  h.eq(#calls, 1)
  h.eq(calls[1].req.body, "{}"); h.eq(calls[1].ip, "10.11.4.50")
  h.truthy(c.sent:find("^HTTP/1.1 200 OK\r\n"))
  h.eq(c.closed, true, "closed after the response")
end)

h.describe("server_drops_idle_client_and_serves_next", function()
  local fs, srv, calls = make()
  local a = fake.client({ chunks = {}, ip = "10.11.4.51" })
  table.insert(fs.pending, a)
  srv:step()
  fs.now = fs.now + 6
  local b = fake.client({ chunks = { REQ }, ip = "10.11.4.52" })
  table.insert(fs.pending, b)
  srv:step()
  h.eq(a.closed, true, "idle client dropped")
  h.eq(#calls, 1); h.eq(calls[1].ip, "10.11.4.52")
  h.truthy(b.sent:find("^HTTP/1.1 200"))
end)

h.describe("server rejects oversize body with 413 and closes", function()
  local fs, srv, calls = make()
  local c = fake.client({ chunks = { "POST /mcp HTTP/1.1\r\ncontent-length: 2000000\r\n\r\n" } })
  table.insert(fs.pending, c)
  srv:step()
  h.eq(#calls, 0); h.truthy(c.sent:find("^HTTP/1.1 413")); h.eq(c.closed, true)
  h.eq(srv.stats.bad_requests, 1)
end)

h.describe("server answers bad request with 400", function()
  local fs, srv, calls = make()
  local c = fake.client({ chunks = { "GARBAGE\r\n\r\n" } })
  table.insert(fs.pending, c)
  srv:step()
  h.eq(#calls, 0); h.truthy(c.sent:find("^HTTP/1.1 400")); h.eq(c.closed, true)
end)

h.describe("server serves one request per step in arrival order", function()
  local fs, srv, calls = make()
  local a = fake.client({ chunks = { REQ }, ip = "10.11.4.61" })
  local b = fake.client({ chunks = { REQ }, ip = "10.11.4.62" })
  table.insert(fs.pending, a); table.insert(fs.pending, b)
  srv:step()
  h.eq(#calls, 1); h.eq(calls[1].ip, "10.11.4.61")
  srv:step()
  h.eq(#calls, 2); h.eq(calls[2].ip, "10.11.4.62")
  h.eq(srv.stats.requests, 2)
  h.eq(srv.last_step, fs.now)
end)

h.describe("server finishes a partial send on later steps", function()
  local fs, srv = make()
  local c = fake.client({ chunks = { REQ }, send_limit = 10 })
  table.insert(fs.pending, c)
  srv:step()
  h.eq(c.closed, nil, "still open: output pending")
  for _ = 1, 20 do srv:step() end
  h.truthy(c.sent:find("\r\n\r\n{}$"), "whole response eventually sent")
  h.eq(c.closed, true)
end)

h.describe("server handler crash becomes 500", function()
  local fs, srv = make(function() error("kaboom") end)
  local c = fake.client({ chunks = { REQ } })
  table.insert(fs.pending, c)
  srv:step()
  h.truthy(c.sent:find("^HTTP/1.1 500")); h.eq(c.closed, true)
end)

h.describe("server peer-closed mid request is dropped", function()
  local fs, srv, calls = make()
  local c = fake.client({ chunks = { "POST /mcp HTTP/1.1\r\n", "CLOSE" } })
  table.insert(fs.pending, c)
  srv:step(); srv:step()
  h.eq(#calls, 0); h.eq(c.closed, true)
end)

h.describe("server start failure and stop", function()
  local fs = fake.new(); fs.fail_bind = "address already in use"
  local srv = server.new({ bind = "127.0.0.1", port = 9800, socket = fs, now = fs.gettime, handler = function() end })
  local ok, err = srv:start()
  h.eq(ok, nil); h.eq(err, "address already in use")
  local fs2, srv2 = make()
  local ip, port = srv2:address(); h.eq(ip, "127.0.0.1"); h.eq(port, 9800)
  srv2:stop(); h.eq(srv2.running, false)
end)
