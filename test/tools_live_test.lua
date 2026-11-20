-- Live state: what the console is doing right now (src/tools/live.lua).
local console = require("console")
local live = require("tools.live")
local fake_console = require("fake_console")
local h = require("helpers")

local function rig()
  local fake = fake_console.new()
  local c = console.new(fake.api)
  local tools = {}
  local ctx = { budget_ms = 10000 }
  live.register(tools, c, ctx)
  return fake, tools, ctx
end

h.describe("ma3_playbacks: nothing running gives no rows", function()
  local _, tools, ctx = rig()
  local r = tools.ma3_playbacks.handler({}, ctx)
  h.eq(r.running, 0); h.eq(#r.rows, 0); h.eq(r.partial, false)
end)

h.describe("ma3_playbacks lists each running sequence with its current cue, timing and executors", function()
  local fake, tools, ctx = rig()
  local s12 = fake.by_addr["Sequence 12"]
  s12.playing = true; s12.current = 4          -- kids: CueZero, OffCue, Cue 1, Cue 2
  local s20 = fake.by_addr["Sequence 20"]
  s20.playing = true                           -- running, no current cue readable
  local r = tools.ma3_playbacks.handler({}, ctx)
  h.eq(r.running, 2); h.eq(#r.rows, 2)
  local a = r.rows[1]
  h.eq(a.no, 12); h.eq(a.name, "Song A"); h.eq(a.address, "Sequence 12")
  h.eq(a.cue, 2); h.eq(a.cue_name, "Cue 2"); h.eq(a.cue_address, "Sequence 12 Cue 2")
  h.eq(a.trigger, "Follow"); h.eq(a.in_fade, 2)
  h.eq(#a.executors, 2)
  h.eq(a.executors[1].page, 1); h.eq(a.executors[1].executor, 201); h.eq(a.executors[1].page_name, "Weekend")
  h.eq(a.executors[2].page, 3); h.eq(a.executors[2].executor, 101)
  local b = r.rows[2]
  h.eq(b.no, 20); h.eq(b.name, "House"); h.eq(b.cue, nil); h.eq(#b.executors, 1)
end)

h.describe("ma3_playbacks {executors:false} skips the page walk", function()
  local fake, tools, ctx = rig()
  fake.by_addr["Sequence 14"].playing = true; fake.by_addr["Sequence 14"].current = 2
  local r = tools.ma3_playbacks.handler({ executors = false }, ctx)
  h.eq(r.running, 1); h.eq(r.rows[1].no, 14); h.eq(r.rows[1].cue, 0.001); h.eq(r.rows[1].cue_name, "Verse")
  h.eq(r.rows[1].executors, nil)
end)

h.describe("ma3_playbacks does not walk the pages when nothing runs", function()
  local fake, tools, ctx = rig()
  local page = fake.by_addr["Page 1"]
  local walked = false
  local real_ptr = page.Ptr
  page.Ptr = function(self, i) walked = true return real_ptr(self, i) end
  tools.ma3_playbacks.handler({}, ctx)
  h.eq(walked, false)
end)

h.describe("ma3_playbacks skips a sequence whose playback call fails and reports it", function()
  local fake, tools, ctx = rig()
  fake.by_addr["Sequence 13"].playback_error = true
  fake.by_addr["Sequence 21"].playing = true
  local r = tools.ma3_playbacks.handler({ executors = false }, ctx)
  h.eq(r.running, 1); h.eq(r.rows[1].no, 21)
  h.eq(#r.unreadable, 1); h.eq(r.unreadable[1], "Sequence 13")
end)

h.describe("ma3_playbacks uses IsRunningPlayback where HasActivePlayback is gone", function()
  local fake, tools, ctx = rig()
  local s = fake.by_addr["Sequence 300"]
  s.HasActivePlayback = false                  -- shadows the method: not callable
  s.IsRunningPlayback = function() return true end
  local r = tools.ma3_playbacks.handler({ executors = false }, ctx)
  h.eq(r.running, 1); h.eq(r.rows[1].no, 300)
end)

h.describe("ma3_playbacks spends no console frames on empty pool slots", function()
  local fake, tools, ctx = rig()
  tools.ma3_playbacks.handler({}, ctx)
  h.eq(fake.yields, 0)
end)

-- DMX universes and station ports: the reads that explained ladders 7 and 8 on 2026-11-19
-- (the console's XLR G was a DMX input on the universe they were patched on).
local guard = require("guard")

local function universe(no, props)
  local list = { { "USED", "UInt32", 0 }, { "COARSEPARAMS", "UInt32", 0 }, { "PORTOUT", "Bool", false }, { "PORTIN", "Bool", false },
    { "PORTRDM", "Bool", false }, { "PARKEDCOUNT", "UInt32", 0 }, { "TESTERCOUNT", "UInt32", 0 }, { "GRANTED", "String", "Yes" }, { "MERGEMODE", "UInt32", 1 } }
  for _, pr in ipairs(list) do if props[pr[1]] ~= nil then pr[3] = props[pr[1]] end end
  return { class = "DmxUniverse", addr = "DMXUniverse " .. no, name = "DmxUniverse " .. no, no = no, slot = no, props = list }
end

local function dmx_tree()
  local t = fake_console.default_tree()
  local patch = t.children[1].children[2]
  table.insert(patch.children, { class = "DmxUniverses", addr = "Patch DmxUniverses", name = "DmxUniverses", count = 1024, children = {
    universe(1, { USED = 504, COARSEPARAMS = 504, PORTOUT = true, PARKEDCOUNT = 71 }),
    universe(3, { USED = 6, COARSEPARAMS = 258, PORTIN = true }),
    universe(7, { USED = 100, COARSEPARAMS = 300, PORTIN = true }),
    universe(12, {}),
    universe(51, { USED = 8, COARSEPARAMS = 8, PORTOUT = true, TESTERCOUNT = 2 }) } })
  local function config(addr, ports)
    local props = { { "XLRPORTCOUNT", "UInt32", #ports } }
    for _, p in ipairs(ports) do
      props[#props + 1] = { "MODE" .. p[1], "String", p[2] }
      props[#props + 1] = { "XLR" .. p[1], "UInt32", p[3] }
      props[#props + 1] = { "FAILUREMODE" .. p[1], "String", "Timeout 10s" }
      if p[2] == "In" then props[#props + 1] = { "MERGE" .. p[1], "UInt32", 1 }; props[#props + 1] = { "PRIO" .. p[1], "String", "LTP" } end
    end
    return { class = "OutputConfiguration", addr = addr, name = "OutputConfiguration 1", no = 1, props = props }
  end
  table.insert(t.children, { class = "DeviceConfigurations", addr = "Root 22", name = "DeviceConfigurations", children = {
    { class = "OutputStations", addr = "Root 22.1", name = "OutputStations", children = {
      { class = "OutputStationCollect", addr = "Root 22.1.1", name = "Console", children = {
        { class = "OutputStation", addr = "Root 22.1.1.1", name = "main-desk", no = 1,
          props = { { "IP", "String", "10.0.0.5" }, { "TYPE", "String", "Light" }, { "INMYSESSION", "String", "Yes" } },
          children = { config("Root 22.1.1.1.1", { { "A", "Out", 51 }, { "B", "Out", 52 }, { "G", "In", 7 } }) } } } },
      { class = "OutputStationCollect", addr = "Root 22.1.2", name = "onPC", children = {
        { class = "OutputStation", addr = "Root 22.1.2.1", name = "bench.local", no = 1,
          props = { { "IP", "String", "10.0.0.9" }, { "INMYSESSION", "String", "Yes" } },
          children = { config("Root 22.1.2.1.1", { { "A", "Out", 1 }, { "C", "In", 3 } }) } } } },
      { class = "OutputStationCollect", addr = "Root 22.1.3", name = "PU" } } },
    { class = "DMXProtocols", addr = "Root 22.2", name = "DMXProtocols" } } })
  return t
end

local function dmx_rig(host)
  local fake = fake_console.new(dmx_tree())
  if host then fake.api.HostType = function() return host end end
  local c = console.new(fake.api)
  if host then c.guard = guard.new({ console = host ~= "onPC", quarantine = {} }) end
  local tools = {}
  local ctx = { budget_ms = 10000 }
  live.register(tools, c, ctx)
  return fake, tools, ctx
end

h.describe("ma3_universes lists the universes that matter and what is special about each", function()
  local _, tools, ctx = dmx_rig()
  local r = tools.ma3_universes.handler({}, ctx)
  h.eq(#r.rows, 4, "universe 12 (nothing on it) is left out")
  h.eq(r.rows[1].universe, 1); h.eq(r.rows[1].used, 504); h.eq(r.rows[1].port_out, true); h.eq(r.rows[1].parked, 71)
  h.eq(r.rows[3].universe, 7); h.eq(r.rows[3].port_in, true); h.eq(r.rows[3].used, 100); h.eq(r.rows[3].params, 300)
  h.eq(r.rows[4].universe, 51); h.eq(r.rows[4].tester, 2)
  h.eq(r.partial, false)
end)

h.describe("ma3_universes warns about input ports, parked and tester values on patched universes", function()
  local _, tools, ctx = dmx_rig()
  local r = tools.ma3_universes.handler({}, ctx)
  local text = table.concat(r.warnings, " | ")
  h.truthy(text:find("universe 7: a DMX input port is mapped here and 100 fixtures are patched on it", 1, true))
  h.truthy(text:find("universe 3: a DMX input port", 1, true))
  h.truthy(text:find("universe 1: 71 parked", 1, true))
  h.truthy(text:find("universe 51: 2 channels held by the DMX tester", 1, true))
end)

h.describe("ma3_universes {universe} reads one, {all} reads every slot", function()
  local _, tools, ctx = dmx_rig()
  local one = tools.ma3_universes.handler({ universe = 12 }, ctx)
  h.eq(#one.rows, 1); h.eq(one.rows[1].universe, 12); h.eq(one.rows[1].used, 0)
  local all = tools.ma3_universes.handler({ all = true }, ctx)
  h.eq(#all.rows, 5)
  local _, err = tools.ma3_universes.handler({ universe = 900 }, ctx); h.truthy(err:find("not found"))
end)

h.describe("ma3_ports lists every station's DMX ports and flags inputs on patched universes", function()
  local _, tools, ctx = dmx_rig()
  local r = tools.ma3_ports.handler({}, ctx)
  h.eq(#r.stations, 2)
  local s = r.stations[1]
  h.eq(s.name, "main-desk"); h.eq(s.kind, "Console"); h.eq(s.ip, "10.0.0.5"); h.eq(s.in_my_session, "Yes"); h.eq(#s.ports, 3)
  h.eq(s.ports[1].port, "A"); h.eq(s.ports[1].mode, "Out"); h.eq(s.ports[1].universe, 51)
  h.eq(s.ports[3].port, "G"); h.eq(s.ports[3].mode, "In"); h.eq(s.ports[3].universe, 7); h.eq(s.ports[3].priority, "LTP")
  h.eq(s.ports[3].fixtures_on_universe, 100)
  h.eq(r.stations[2].name, "bench.local"); h.eq(r.stations[2].kind, "onPC")
  local text = table.concat(r.warnings, " | ")
  h.truthy(text:find("main-desk port G is a DMX input on universe 7 (LTP), where 100 fixtures are patched", 1, true))
  h.truthy(text:find("bench.local port C is a DMX input on universe 3", 1, true))
end)

h.describe("ma3_ports is allowed by the console guard (branch read on onPC 2026-11-19), its neighbours are not", function()
  local _, tools, ctx = dmx_rig("Console")
  local r, err = tools.ma3_ports.handler({}, ctx)
  h.eq(err, nil); h.eq(#r.stations, 2)
  local g = guard.new({ console = true, quarantine = {} })
  local ports = { "DeviceConfigurations", "OutputStations", "OutputStationCollect", "OutputStation", "OutputConfiguration" }
  h.eq((g:allow_path(ports, true)), true)
  h.eq((g:allow_path({ "DeviceConfigurations" }, true)), true, "the object itself, to find OutputStations")
  h.eq((g:allow_path({ "DeviceConfigurations", "DMXProtocols" }, true)), false)
  h.eq((g:allow_path({ "DeviceConfigurations", "DMXProtocols", "sACN" }, true)), false)
end)

h.describe("the port configuration is readable by ma3_ports only: tools that take an address (ma3_set, ma3_object) stay refused", function()
  local g = guard.new({ console = true, quarantine = {} })
  h.eq((g:allow_path({ "DeviceConfigurations", "OutputStations", "OutputStationCollect", "OutputStation", "OutputConfiguration" })), false)
  h.eq((g:allow_path({ "DeviceConfigurations" })), false)
  h.eq((g:allow_path({ "DeviceConfigurations", "OutputStations" })), false)
end)

h.describe("ma3_ports says so when the console has no device configuration to read", function()
  local _, tools, ctx = rig()
  local _, err = tools.ma3_ports.handler({}, ctx)
  h.truthy(err:find("DeviceConfigurations"))
end)
