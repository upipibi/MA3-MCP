-- The console guard wired into the tools, the dispatcher and plugin start, with the fake
-- console reporting HostType "Console". See test/guard_test.lua for the guard itself.
local console = require("console")
local generic = require("tools.generic")
local deep = require("tools.deep")
local guard = require("guard")
local mcp = require("mcp")
local log = require("log")
local json = require("json")
local fake_console = require("fake_console")
local fake_fs = require("fake_fs")
local h = require("helpers")

-- The default fake tree plus the branches the census found outside the show: the screen and
-- input devices (GraphicsRoot), a display reachable by a plain address, and user-profile
-- window settings inside ShowData.
local function tree()
  local t = fake_console.default_tree()
  table.insert(t.children, { class = "GraphicsRoot", addr = "Root 19", name = "GraphicsRoot", children = {
    { class = "PultCollect", addr = "Root 19.1", name = "PultCollect", children = {
      { class = "Pult", addr = "Root 19.1.1", name = "Pult 1", children = {
        { class = "Devices", addr = "Root 19.1.1.1", name = "Devices", children = {
          { class = "Keyboard", addr = "Root 19.1.1.1.1", name = "Keyboard" } } },
        { class = "DisplayCollect", addr = "Root 19.1.1.2", name = "DisplayCollect", children = {
          { class = "Display", addr = "Display 1", name = "Display 1", no = 1 } } } } } } } } })
  local showdata = t.children[1]
  table.insert(showdata.children, { class = "UserProfiles", addr = "Root 14.19", name = "UserProfiles", children = {
    { class = "UserProfile", addr = "UserProfile 1", name = "Default", no = 1, children = {
      { class = "TemporaryWindowSettings", addr = "UserProfile 1.5", name = "TemporaryWindowSettings", children = {
        { class = "SequenceSheetSettings", addr = "UserProfile 1.5.1", name = "SequenceSheetSettings" } } } } } } })
  return t
end

local function rig(host)
  local fake = fake_console.new(tree())
  fake.api.HostType = function() return host end
  local c = console.new(fake.api)
  local fs = fake_fs.new()
  local clock = { t = 1000 }
  local g = guard.new({ console = host ~= "onPC", fs = fs, journal_path = "/lib/ma3_mcp_inflight.json", quarantine = {},
    now = function() return clock.t end, log = function() end })
  c.guard = g
  local tools = {}
  local ctx = { budget_ms = 10000, lua_enabled = function() return false end, plugin_version = "t", started_at = 0,
    request_count = 0, log = log.new(50), address = "x", guard = g }
  generic.register(tools, c, ctx)
  deep.register(tools, c, ctx, {})
  return { fake = fake, c = c, fs = fs, clock = clock, g = g, tools = tools, ctx = ctx }
end

h.describe("console: show data reads work as before", function()
  local r = rig("Console")
  local o = r.tools.ma3_object.handler({ address = "Sequence 12" }, r.ctx)
  h.eq(o.class, "Sequence"); h.eq(o.name, "Song A")
  local ch = r.tools.ma3_children.handler({ address = "Sequence 12" }, r.ctx)
  h.eq(ch.total, 6); h.eq(ch.children[3].name, "Cue 1")
  h.truthy(r.tools.ma3_object.handler({ address = "Root 14.5" }, r.ctx), "MAnetSocket for the show name")
  h.truthy(r.tools.ma3_history.handler({}, r.ctx), "history (Temp > Cmdlines > Cmdline > Undos)")
end)

h.describe("console: a Root branch outside the allow-list is refused before the console resolves it", function()
  local r = rig("Console")
  local before = #r.fake.objectlist_calls
  local o, err = r.tools.ma3_object.handler({ address = "Root 19.1.1.1.1" }, r.ctx)
  h.eq(o, nil); h.truthy(err:find("^%[console%-guard%]"), err)
  h.eq(#r.fake.objectlist_calls, before, "ObjectList never called")
end)

h.describe("console: an object outside the allow-list reached by name is refused after resolve", function()
  local r = rig("Console")
  for _, tool in ipairs({ "ma3_object", "ma3_children", "ma3_dump", "ma3_export" }) do
    local o, err = r.tools[tool].handler({ address = "Display 1" }, r.ctx)
    h.eq(o, nil, tool); h.truthy(tostring(err):find("GraphicsRoot > PultCollect > Pult > DisplayCollect > Display", 1, true), tool .. ": " .. tostring(err))
  end
  local s, e2 = r.tools.ma3_set.handler({ address = "Display 1", property = "Name", value = "x" }, r.ctx)
  h.eq(s, nil); h.truthy(e2:find("console%-guard"))
  local u, e3 = r.tools.ma3_object.handler({ address = "UserProfile 1.5" }, r.ctx)
  h.eq(u, nil, "window settings refused"); h.truthy(e3:find("TemporaryWindowSettings"))
  h.truthy(r.tools.ma3_object.handler({ address = "UserProfile 1" }, r.ctx), "the profile itself is allowed")
end)

h.describe("console: children of Root list refused branches by class only", function()
  local r = rig("Console")
  local ch = r.tools.ma3_children.handler({ address = "Root", fields = { "NAME" } }, r.ctx)
  local by = {}
  for _, row in ipairs(ch.children) do by[row.class] = row end
  h.truthy(by.ShowData and by.ShowData.address and not by.ShowData.refused, "ShowData listed normally")
  h.truthy(by.GraphicsRoot and by.GraphicsRoot.refused, "GraphicsRoot marked refused")
  h.eq(by.GraphicsRoot.address, nil, "no address read on a refused child"); h.eq(by.GraphicsRoot.properties, nil, "no fields read")
end)

h.describe("console: dump skips refused children and stops at the node cap", function()
  local r = rig("Console")
  local d = r.tools.ma3_dump.handler({ address = "Root", depth = 2 }, r.ctx)
  h.truthy(d.text:find("refused GraphicsRoot", 1, true), d.text:sub(1, 300))
  h.truthy(not d.text:find("PultCollect", 1, true), "nothing below a refused node")
  local old = generic.DUMP_NODE_CAP
  generic.DUMP_NODE_CAP = 5
  local d2 = r.tools.ma3_dump.handler({ address = "Sequence 12", depth = 2 }, r.ctx)
  generic.DUMP_NODE_CAP = old
  h.eq(d2.truncated, true)
end)

h.describe("console: commands may name Root 14 only", function()
  local r = rig("Console")
  local n = #r.fake.cmds
  local x, err = r.tools.ma3_command.handler({ command = 'Set Root 19.1.1 Property "Name" "x"' }, r.ctx)
  h.eq(x, nil); h.truthy(err:find("console%-guard")); h.eq(#r.fake.cmds, n, "not sent")
  local y, e2 = r.tools.ma3_commands.handler({ commands = { 'Label Sequence 12 "A"', "Set Root 2.1 Property \"x\" 1" } }, r.ctx)
  h.eq(y, nil); h.truthy(e2:find("command 2 rejected")); h.eq(#r.fake.cmds, n, "batch refused before sending")
  h.truthy(r.tools.ma3_command.handler({ command = 'Set Root 14.10.9.179 Property "DMXCURVE" 1' }, r.ctx))
end)

h.describe("onPC: the bench reaches everything", function()
  local r = rig("onPC")
  h.truthy(r.tools.ma3_object.handler({ address = "Root 19.1.1.1.1" }, r.ctx))
  h.truthy(r.tools.ma3_object.handler({ address = "Display 1" }, r.ctx))
  h.truthy(r.tools.ma3_command.handler({ command = 'Set Root 19.1.1 Property "Name" "x"' }, r.ctx))
end)

-- Dispatcher: rate cap, journal around every call, runaway Lua stopped.
local function dispatcher(r, extra)
  local tools = {}
  for k, v in pairs(r.tools) do tools[k] = v end
  for k, v in pairs(extra or {}) do tools[k] = v end
  return mcp.new({ server_name = "t", server_version = "t", tools = tools })
end

h.describe("dispatcher on a console: journal before and after each call", function()
  local r = rig("Console")
  local d = dispatcher(r, { peek = { description = "", inputSchema = { type = "object" }, handler = function()
    return json.decode(r.fs.files["/lib/ma3_mcp_inflight.json"]) end } })
  local res = d:call_tool({ name = "peek", arguments = { address = "Sequence 12" } }, r.ctx)
  local during = json.decode(res.content[1].text)
  h.eq(during.tool, "peek"); h.eq(during.address, "Sequence 12"); h.eq(during.done, nil)
  h.eq(json.decode(r.fs.files["/lib/ma3_mcp_inflight.json"]).done, true, "done after")
  d:call_tool({ name = "ma3_object", arguments = { address = "Root 19.1" } }, r.ctx)
  h.eq(json.decode(r.fs.files["/lib/ma3_mcp_inflight.json"]).done, true, "done after a refused call too")
end)

h.describe("dispatcher on a console: rate cap answers without touching the console", function()
  local r = rig("Console")
  local d = dispatcher(r)
  for i = 1, 16 do h.eq(d:call_tool({ name = "ma3_status", arguments = {} }, r.ctx).isError, false, "call " .. i) end
  local before = #r.fake.objectlist_calls
  local res = d:call_tool({ name = "ma3_object", arguments = { address = "Sequence 12" } }, r.ctx)
  h.eq(res.isError, true); h.truthy(res.content[1].text:find("slow down")); h.eq(#r.fake.objectlist_calls, before)
end)

h.describe("dispatcher: a tool stuck in a Lua loop is stopped", function()
  local r = rig("Console")
  local tick = 0
  r.g.now = function() tick = tick + 1 return 1000 + tick * 0.01 end   -- each clock read: 10 ms later
  local d = dispatcher(r, { spin = { description = "", inputSchema = { type = "object" }, handler = function()
    local x = 0 while true do x = x + 1 end end } })
  local res = d:call_tool({ name = "spin", arguments = {} }, r.ctx)
  h.eq(res.isError, true); h.truthy(res.content[1].text:find("console%-guard"), res.content[1].text)
  h.eq(debug.gethook(), nil, "hook removed afterwards")
  h.eq(json.decode(r.fs.files["/lib/ma3_mcp_inflight.json"]).done, true)
end)

h.describe("dispatcher: a long console call (a save) is not counted as runaway Lua", function()
  local r = rig("Console")
  local d = dispatcher(r, { save = { description = "", inputSchema = { type = "object" }, handler = function()
    r.clock.t = r.clock.t + 40          -- one console call that takes 40 s
    local x = 0 for i = 1, 50000 do x = x + i end
    return { ok = x > 0 } end } })
  local res = d:call_tool({ name = "save", arguments = {} }, r.ctx)
  h.eq(res.isError, false, res.content[1].text)
end)

h.describe("dispatcher: slow calls are logged", function()
  local r = rig("Console")
  local d = dispatcher(r, { slow = { description = "", inputSchema = { type = "object" }, handler = function()
    r.clock.t = r.clock.t + 0.25 return { ok = true } end } })
  d:call_tool({ name = "slow", arguments = { address = "Sequence 12" } }, r.ctx)
  local lines = table.concat(r.ctx.log:lines(), "\n")
  h.truthy(lines:find("slow: slow Sequence 12 250 ms", 1, true), lines)
end)
