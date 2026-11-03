-- MA3 MCP Gate Zero: throwaway. Proves a LuaSocket listener can bind the console's
-- production-network address and answer an HTTP request from a laptop, without
-- blocking the console UI. Delete after the test.
local pluginName, componentName, signalTable, my_handle = select(1, ...), select(2, ...), select(3, ...), select(4, ...)
local socket = require("socket")

local function P(fmt, ...) Printf("GateZero: " .. string.format(fmt, ...)) end

local function Main(display_handle, argument)
  local host = (argument and argument ~= "") and argument or "127.0.0.1"
  local port = 9800
  P("Lua %s, %s", _VERSION, tostring(socket._VERSION))
  local server, err = socket.bind(host, port)
  if not server then P("BIND FAILED on %s:%d: %s", host, port, tostring(err)) return end
  server:settimeout(0)
  local ip, p = server:getsockname()
  P("listening on %s:%s for 60 s; from a laptop: curl -s http://%s:%d/", tostring(ip), tostring(p), host, port)
  local t0, served, passes = socket.gettime(), 0, 0
  local body = "MA3 MCP OK\n"
  local reply = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: " .. #body .. "\r\nConnection: close\r\n\r\n" .. body
  while socket.gettime() - t0 < 60 do
    passes = passes + 1
    local c = server:accept()
    if c then
      c:settimeout(0)
      local peer = select(1, c:getpeername())
      local data, rerr, partial = c:receive(4096)
      local got = data or partial or ""
      c:send(reply)
      c:close()
      served = served + 1
      P("served %s (%d bytes in, first line: %s)", tostring(peer), #got, tostring(got:match("^[^\r\n]*")))
    end
    coroutine.yield()
  end
  server:close()
  P("done: %d requests served, %d loop passes in 60 s", served, passes)
end

return Main
