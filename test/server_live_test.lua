-- Real LuaSocket on loopback: curl posts to the server while a plain loop steps it.
local server = require("server")
local socket = require("socket")
local h = require("helpers")

h.describe("server live loopback with curl", function()
  local seen
  local srv = server.new({ bind = "127.0.0.1", port = 19800, socket = socket, handler = function(req, ip)
    seen = { req = req, ip = ip }
    return 200, { ["Content-Type"] = "application/json" }, '{"live":true}'
  end })
  local ok, err = srv:start()
  h.truthy(ok, "bind 127.0.0.1:19800: " .. tostring(err))
  os.remove("test/out/live.txt")
  os.execute("(sleep 0.3; curl -s -X POST -H 'Content-Type: application/json' --data '{\"q\":1}' http://127.0.0.1:19800/mcp > test/out/live.txt) >/dev/null 2>&1 &")
  local t0 = socket.gettime()
  while socket.gettime() - t0 < 5 do
    srv:step()
    socket.sleep(0.005)
    if seen and #srv.clients == 0 then break end
  end
  srv:stop()
  h.truthy(seen, "handler called")
  if seen then
    h.eq(seen.req.method, "POST"); h.eq(seen.req.path, "/mcp"); h.eq(seen.req.body, '{"q":1}'); h.eq(seen.ip, "127.0.0.1")
  end
  socket.sleep(0.2)
  local f = io.open("test/out/live.txt"); local body = f and f:read("a") or ""; if f then f:close() end
  h.eq(body, '{"live":true}')
end)
