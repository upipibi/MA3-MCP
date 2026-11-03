local auth = require("auth")
local h = require("helpers")

local function req(pin, extra)
  local headers = { host = "10.11.3.10:9800" }
  if pin then headers.authorization = "Bearer " .. pin end
  for k, v in pairs(extra or {}) do headers[k] = v end
  return { method = "POST", path = "/mcp", headers = headers, body = "" }
end

h.describe("auth.new_pin alphabet and length", function()
  local seen = {}
  for _ = 1, 1000 do
    local p = auth.new_pin()
    h.eq(#p, 8)
    h.truthy(p:match("^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]+$"), p)
    seen[p] = true
  end
  local n = 0; for _ in pairs(seen) do n = n + 1 end
  h.truthy(n > 990, "pins are random")
  local fixed = auth.new_pin(function() return 1 end)
  h.eq(fixed, "AAAAAAAA", "rand injected")
end)

h.describe("auth check right, wrong, missing", function()
  local now = 1000
  local a = auth.new({ pin = "ABCD2345", now = function() return now end, origin_allowed = "http://10.11.3.10:9800" })
  local ok, status, reason = a:check(req("ABCD2345"), "10.11.3.50")
  h.eq(ok, true); h.eq(status, 200)
  ok, status, reason = a:check(req("WRONG123"), "10.11.3.50")
  h.eq(ok, false); h.eq(status, 401); h.eq(reason, "wrong")
  ok, status, reason = a:check(req(nil), "10.11.3.50")
  h.eq(ok, false); h.eq(status, 401); h.eq(reason, "missing")
  ok, status, reason = a:check(req("abcd2345"), "10.11.3.50")
  h.eq(ok, false, "case sensitive")
end)

h.describe("auth lockout after five bad pins per ip", function()
  local now = 1000
  local a = auth.new({ pin = "ABCD2345", now = function() return now end })
  for _ = 1, 5 do a:check(req("WRONG123"), "10.11.3.50") end
  local ok, status, reason = a:check(req("ABCD2345"), "10.11.3.50")
  h.eq(ok, false); h.eq(status, 429); h.eq(reason, "locked")
  ok, status = a:check(req("ABCD2345"), "10.11.3.51")
  h.eq(ok, true, "other ip unaffected")
  now = now + 301
  ok, status = a:check(req("ABCD2345"), "10.11.3.50")
  h.eq(ok, true, "lock expired")
  -- four bad pins spread over more than a minute do not lock
  local b = auth.new({ pin = "ABCD2345", now = function() return now end })
  for i = 1, 4 do b:check(req("WRONG123"), "10.11.3.60"); now = now + 20 end
  ok = b:check(req("ABCD2345"), "10.11.3.60")
  h.eq(ok, true, "window is 60 s")
end)

h.describe("auth origin", function()
  local a = auth.new({ pin = "ABCD2345", now = function() return 0 end, origin_allowed = "http://10.11.3.10:9800" })
  local ok, status, reason = a:check(req("ABCD2345", { origin = "http://evil.example" }), "10.11.3.50")
  h.eq(ok, false); h.eq(status, 403); h.eq(reason, "origin")
  ok = a:check(req("ABCD2345", { origin = "http://10.11.3.10:9800" }), "10.11.3.50")
  h.eq(ok, true)
  ok = a:check(req("ABCD2345", { origin = "" }), "10.11.3.50")
  h.eq(ok, true, "empty origin passes")
end)

h.describe("auth client registry", function()
  local now = 1000
  local a = auth.new({ pin = "ABCD2345", now = function() return now end })
  for i = 1, 12 do a:record_client("10.11.3." .. i, "client" .. i); now = now + 1 end
  h.eq(#a.clients, 10)
  h.eq(a.clients[1].ip, "10.11.3.12", "newest first")
  h.eq(a.clients[10].ip, "10.11.3.3")
  a:record_client("10.11.3.12", "client12")
  h.eq(#a.clients, 10); h.eq(a.clients[1].calls, 2); h.eq(a.clients[1].name, "client12"); h.eq(a.clients[1].last_seen, now)
  a:check(req("WRONG123"), "10.11.3.99")
  h.eq(a.clients[1].ip, "10.11.3.99"); h.eq(a.clients[1].bad_pin, 1)
end)

h.describe("auth regenerate", function()
  local a = auth.new({ pin = "ABCD2345", now = function() return 0 end })
  local p = a:regenerate()
  h.eq(#p, 8); h.truthy(p ~= "ABCD2345"); h.eq(a.pin, p)
  h.eq(a:check(req("ABCD2345"), "10.11.3.1"), false)
  h.eq(a:check(req(p), "10.11.3.1"), true)
end)
