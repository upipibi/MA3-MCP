local settings = require("settings")
local fake_fs = require("fake_fs")
local json = require("json")
local h = require("helpers")

h.describe("settings load defaults on missing file", function()
  local fs = fake_fs.new()
  local s = settings.load(fs, "/x/ma3_mcp_settings.json")
  h.eq(#s.pin, 8); h.eq(s.port, 9800); h.eq(s.bind, nil); h.eq(s.display, 1); h.eq(s.lua_default, false)
  h.eq(#s.backups, 0); h.eq(#s.clients, 0); h.eq(s.generated, true)
end)

h.describe("settings save and reload round trip", function()
  local fs = fake_fs.new()
  local s = settings.load(fs, "/x/s.json")
  s.pin = "ABCD2345"; s.port = 9801; s.bind = "10.11.3.10"; s.display = 2
  s.backups = { "Show_mcp_1103_1420" }
  s.clients = { { ip = "10.11.4.1", name = "claude-code", last_seen = 5, calls = 2, bad_pin = 0 } }
  h.truthy(settings.save(fs, "/x/s.json", s))
  local s2 = settings.load(fs, "/x/s.json")
  h.eq(s2.generated, nil)
  h.eq(s2.pin, "ABCD2345"); h.eq(s2.port, 9801); h.eq(s2.bind, "10.11.3.10"); h.eq(s2.display, 2)
  h.eq(s2.backups[1], "Show_mcp_1103_1420"); h.eq(s2.clients[1].name, "claude-code")
  local again = fs.files["/x/s.json"]
  settings.save(fs, "/x/s.json", s2)
  h.eq(fs.files["/x/s.json"], again, "byte-for-byte stable")
  h.truthy(json.decode(again).pin == "ABCD2345", "file is JSON")
end)

h.describe("settings corrupt file yields defaults", function()
  local fs = fake_fs.new()
  fs.files["/x/s.json"] = "{not json"
  local s = settings.load(fs, "/x/s.json")
  h.eq(s.generated, true); h.eq(s.port, 9800)
  fs.files["/x/s.json"] = '{"port":"nope","pin":"short"}'
  s = settings.load(fs, "/x/s.json")
  h.eq(s.port, 9800, "bad port falls back"); h.eq(#s.pin, 8, "bad pin regenerated")
end)

h.describe("settings save failure", function()
  local fs = fake_fs.new(); fs.files.readonly = true
  local ok, err = settings.save(fs, "/x/s.json", settings.load(fs, "/x/s.json"))
  h.eq(ok, nil); h.eq(err, "read-only")
end)
