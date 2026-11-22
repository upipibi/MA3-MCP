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

-- Programmer and selection per user profile (read on onPC 2026-11-21, in the console's session:
-- UserProfile > Environments > UserEnvironment; slots 1-2 Selection, 3 Programmer > ProgPart,
-- 4 AtFilter, 5 not an object). An empty programmer part reports MEMORYFOOTPRINT 297.
local function environment(addr, name, o)
  o = o or {}
  local function selection(i, n)
    return { class = "Selection", addr = addr .. "." .. i, name = "Selection", no = i,
      props = { { "COUNTTOTALSELECTED", "UInt32", n or 0 }, { "COUNTFULLYSELECTED", "UInt32", n or 0 }, { "ACTIVE", "Bool", (n or 0) > 0 } } }
  end
  local parts = {}
  for i, bytes in ipairs(o.parts or { 297 }) do
    parts[i] = { class = "ProgPart", addr = addr .. ".3 Part " .. (i - 1), name = i == 1 and "Part Zero" or ("Part " .. (i - 1)), no = i - 1,
      props = { { "MEMORYFOOTPRINT", "UInt32", bytes }, { "PART", "UInt32", i - 1 } } }
  end
  return { class = "UserEnvironment", addr = addr, name = name, props = { { "ACTIVESELINDEX", "UInt32", 1 } }, children = {
    selection(1, o.selected), selection(2, 0),
    { class = "Programmer", addr = addr .. ".3", name = "Programmer", no = 3, children = parts },
    { class = "AtFilter", addr = addr .. ".4", name = "AtFilter", no = 4 },
    { class = "NotAnObject", addr = addr .. ".5", name = "trap", no = 5 } } }
end

local function profile(no, name, normal, preview)
  local a = "UserProfile " .. no
  return { class = "UserProfile", addr = a, name = name, no = no, slot = no, children = {
    { class = "Environments", addr = a .. ".1", name = "Environments", props = { { "ACTIVEENVIRONMENT", "String", "Normal" } }, children = {
      environment(a .. ".1.1", "Normal", normal), environment(a .. ".1.2", "Preview", preview) } },
    { class = "TemporaryWindowSettings", addr = a .. ".5", name = "TemporaryWindowSettings" } } }
end

local function prog_tree(master)
  local t = fake_console.default_tree()
  table.insert(t.children[1].children, { class = "UserProfiles", addr = "Root 14.19", name = "UserProfiles", children = {
    profile(1, "Default"), profile(5, "Master", master) } })
  return t
end

local function prog_rig(master, host)
  local fake = fake_console.new(prog_tree(master))
  if host then fake.api.HostType = function() return host end end
  local c = console.new(fake.api)
  if host then c.guard = guard.new({ console = host ~= "onPC", quarantine = {} }) end
  local tools, files = {}, {}
  local ctx = { budget_ms = 10000 }
  live.register(tools, c, ctx, { fs = { read = function(p) return files[p] end } })
  return fake, tools, ctx, files
end

h.describe("ma3_programmer: every profile's programmer and selection, empty when each part is at the empty size", function()
  local _, tools, ctx = prog_rig()
  local r = tools.ma3_programmer.handler({}, ctx)
  h.eq(#r.profiles, 2)
  local p = r.profiles[2]
  h.eq(p.profile, "UserProfile 5"); h.eq(p.name, "Master"); h.eq(#p.environments, 2)
  local e = p.environments[1]
  h.eq(e.name, "Normal"); h.eq(e.active, true)
  h.eq(e.programmer.empty, true); h.eq(e.programmer.bytes, 297); h.eq(#e.programmer.parts, 1)
  h.eq(e.programmer.parts[1].part, 0); h.eq(e.programmer.parts[1].name, "Part Zero")
  h.eq(e.selection.selected, 0); h.eq(e.selection.active, false)
  h.eq(p.environments[2].name, "Preview"); h.eq(p.environments[2].active, false)
  h.eq(#r.holding_values, 0)
end)

h.describe("ma3_programmer: a programmer with values and a selection is reported, by profile and environment", function()
  local _, tools, ctx = prog_rig({ parts = { 5210, 297 }, selected = 12 })
  local r = tools.ma3_programmer.handler({}, ctx)
  local e = r.profiles[2].environments[1]
  h.eq(e.programmer.empty, false); h.eq(e.programmer.bytes, 5507); h.eq(#e.programmer.parts, 2)
  h.eq(e.selection.selected, 12); h.eq(e.selection.fully_selected, 12); h.eq(e.selection.active, true)
  h.eq(#r.holding_values, 1); h.eq(r.holding_values[1], "UserProfile 5 Normal")
  h.eq(r.profiles[1].environments[1].programmer.empty, true)
end)

h.describe("ma3_programmer names the command lines on each profile and says whether a Store from the plugin would take values", function()
  local _, tools, ctx = prog_rig({ parts = { 5210 } })
  local r = tools.ma3_programmer.handler({}, ctx)
  h.eq(r.profiles[2].command_lines[1], "Cmdline 1")
  h.eq(r.plugin.command_line, "Cmdline 1"); h.eq(r.plugin.profile, "UserProfile 5"); h.eq(r.plugin.programmer_empty, false)
  local _, t2, c2 = prog_rig()
  h.eq(t2.ma3_programmer.handler({}, c2).plugin.programmer_empty, true)
end)

h.describe("ma3_programmer {profile} reads one profile; an unknown one is an error", function()
  local _, tools, ctx = prog_rig()
  local r = tools.ma3_programmer.handler({ profile = 5 }, ctx)
  h.eq(#r.profiles, 1); h.eq(r.profiles[1].profile, "UserProfile 5")
  local _, err = tools.ma3_programmer.handler({ profile = 9 }, ctx)
  h.truthy(err:find("not found"))
end)

h.describe("ma3_programmer {values:true} adds the export of each part that holds values, and of no empty part", function()
  local fake, tools, ctx, files = prog_rig({ parts = { 5210, 297 } })
  files["/fake/temp/ma3_mcp_programmer.xml"] = "<GMA3><ProgPart><Fixture/></ProgPart></GMA3>"
  local r = tools.ma3_programmer.handler({ values = true }, ctx)
  local parts = r.profiles[2].environments[1].programmer.parts
  h.eq(parts[1].xml, "<GMA3><ProgPart><Fixture/></ProgPart></GMA3>"); h.eq(parts[2].xml, nil)
  h.eq(fake.exported.addr, "UserProfile 5.1.1.3 Part 0"); h.eq(fake.exported.filename, "ma3_mcp_programmer.xml")
  h.eq(r.profiles[1].environments[1].programmer.parts[1].xml, nil)
end)

h.describe("ma3_programmer never touches the fifth child of an environment (not an object on 2.5.1.1)", function()
  local fake, tools, ctx = prog_rig()
  local touched = false
  for _, addr in ipairs({ "UserProfile 1.1.1.5", "UserProfile 5.1.1.5", "UserProfile 5.1.2.5" }) do
    local trap = fake.by_addr[addr]
    trap.GetClass = function() touched = true error("not an object") end
    trap.Get = function() touched = true error("not an object") end
  end
  local r, err = tools.ma3_programmer.handler({}, ctx)
  h.eq(err, nil); h.eq(#r.profiles, 2); h.eq(touched, false)
end)

h.describe("ma3_programmer runs under the console guard; its branch stays closed to tools that take an address", function()
  local _, tools, ctx = prog_rig({ parts = { 5210 } }, "Console")
  local r, err = tools.ma3_programmer.handler({}, ctx)
  h.eq(err, nil); h.eq(r.profiles[2].environments[1].programmer.empty, false)
  local g = guard.new({ console = true, quarantine = {} })
  local env = { "ShowData", "UserProfiles", "UserProfile", "Environments", "UserEnvironment" }
  local function path(...) local l = {} for _, v in ipairs(env) do l[#l + 1] = v end for _, v in ipairs({ ... }) do l[#l + 1] = v end return l end
  h.eq((g:allow_path(path("Programmer", "ProgPart"), true)), true)
  h.eq((g:allow_path(path("Selection"), true)), true)
  h.eq((g:allow_path(path("Programmer", "ProgPart"))), false, "no address reaches the programmer")
  h.eq((g:allow_path(path("Selection"))), false)
  h.eq((g:allow_path(path("AtFilter"), true)), false, "neighbours stay refused")
  h.eq((g:allow_path({ "ShowData", "UserProfiles", "UserProfile", "TemporaryWindowSettings" }, true)), false)
end)

h.describe("ma3_programmer says so when the show has no user profiles to read", function()
  local _, tools, ctx = rig()
  local _, err = tools.ma3_programmer.handler({}, ctx)
  h.truthy(err:find("UserProfiles"))
end)

-- Masters (ShowData > Masters, five pools; NORMEDVALUE is the level in percent; read on onPC 2026-11-21).
local function masters_rig()
  local t = fake_console.default_tree()
  local function m(class, pool, no, name, level, enable)
    return { class = class, addr = "Master " .. pool .. "." .. no, name = name, no = no,
      props = { { "NORMEDVALUE", "UInt32", level }, { "FADERENABLE", "UInt32", enable or 0 } } }
  end
  table.insert(t.children[1].children, { class = "Masters", addr = "Master", name = "Masters", children = {
    { class = "MasterPoolSelected", addr = "Master 1", name = "Selected", no = 1, children = { m("MasterSelected", 1, 1, "Rate", 50) } },
    { class = "MasterPoolGrand", addr = "Master 2", name = "Grand", no = 2, children = {
      m("MasterGrand", 2, 1, "Master", 80), m("MasterGrand", 2, 2, "World", 100), m("MasterGrand", 2, 3, "Blind", 100) } },
    { class = "MasterPoolSpeed", addr = "Master 3", name = "Speed", no = 3, children = { m("MasterSpeed", 3, 1, "S1 Era Dim", 0, 1), m("MasterSpeed", 3, 2, "BPM", 67, 1) } },
    { class = "MasterPoolPlayback", addr = "Master 4", name = "Playback", no = 4, children = {
      m("MasterPlayback", 4, 1, "Playback1", 100, 1), m("MasterPlayback", 4, 2, "Playback2", 40, 1) } },
    { class = "MasterPoolTiming", addr = "Master 5", name = "Timing", no = 5, children = {
      m("MasterTiming", 5, 1, "Timing1", 0, 1), m("MasterTiming", 5, 2, "Timing2", 25, 1) } } } })
  local fake = fake_console.new(t)
  local c = console.new(fake.api)
  local tools, ctx = {}, { budget_ms = 10000 }
  live.register(tools, c, ctx)
  return fake, tools, ctx
end

h.describe("ma3_masters lists every master with its level; unused playback and timing masters are left out", function()
  local _, tools, ctx = masters_rig()
  local r = tools.ma3_masters.handler({}, ctx)
  h.eq(#r.pools, 5)
  local grand = r.pools[2]
  h.eq(grand.pool, "Grand"); h.eq(#grand.masters, 3)
  h.eq(grand.masters[1].name, "Master"); h.eq(grand.masters[1].level, 80); h.eq(grand.masters[1].address, "Master 2.1")
  h.eq(r.pools[3].masters[2].name, "BPM"); h.eq(r.pools[3].masters[2].level, 67); h.eq(r.pools[3].masters[2].fader_enabled, true)
  h.eq(#r.pools[4].masters, 1); h.eq(r.pools[4].masters[1].name, "Playback2"); h.eq(r.pools[4].masters[1].level, 40)
  h.eq(#r.pools[5].masters, 1); h.eq(r.pools[5].masters[1].name, "Timing2")
  h.eq(r.grand_master, 80)
end)

h.describe("ma3_masters {all:true} lists every slot, {pool} reads one pool", function()
  local _, tools, ctx = masters_rig()
  local all = tools.ma3_masters.handler({ all = true }, ctx)
  h.eq(#all.pools[4].masters, 2); h.eq(#all.pools[5].masters, 2)
  local one = tools.ma3_masters.handler({ pool = "speed" }, ctx)
  h.eq(#one.pools, 1); h.eq(one.pools[1].pool, "Speed")
  local _, err = tools.ma3_masters.handler({ pool = "nope" }, ctx); h.truthy(err:find("no master pool"))
end)

h.describe("ma3_masters says so when the show has no Masters", function()
  local _, tools, ctx = rig()
  local _, err = tools.ma3_masters.handler({}, ctx)
  h.truthy(err:find("Masters"))
end)

-- API reads benched on onPC 2026-11-21 (Lua on, as the MCP user): selection walk, DMX output,
-- a fixture's channels, who the plugin is. Unproven on a console: refused there unless the caller
-- says the supervised first call is on (console_ok).
local function api_rig(host)
  local fake = fake_console.new()
  if host then fake.api.HostType = function() return host end end
  local a = fake.api
  local selected = { 5, 6, 9 }
  a.SelectionCount = function() return #selected end
  a.SelectionFirst = function() return selected[1] end
  a.SelectionNext = function(prev) for i, v in ipairs(selected) do if v == prev then return selected[i + 1] end end end
  local function fx(i, fid, name) return { ToAddr = function() return "Fixture " .. fid end, GetClass = function() return "Fixture" end,
    Get = function(_, n) return ({ FID = fid, NAME = name })[n] end, name = name } end
  local sub = { [5] = fx(5, 101, "Spot 1"), [6] = fx(6, 102, "Spot 2"), [9] = fx(9, 201, "Wash 1") }
  a.GetSubfixture = function(i) return sub[i] end
  a.GetDMXUniverse = function(n, pct)
    if n ~= 11 then return nil end
    local t = {} for i = 1, 512 do t[i] = 0 end
    t[1] = pct and 100 or 255; t[40] = pct and 50 or 128
    return t
  end
  local named = function(n) return { name = n } end
  a.GetRTChannels = function() return { 4609, 4610 } end
  a.GetRTChannel = function(i)
    if i == 4609 then return { ui_index_first = 4609, dmx_default = 0, patch = { coarse = -1, fine = -1 },
      info = { value_before_master = 0, value_after_master = 0, flags = { solo = 0, highlight = 0, lowlight = 0, group_master = 0, additive_master = 0 } } } end
    return { ui_index_first = 4610, dmx_default = 16777215, patch = { coarse = 5120, fine = -1 },
      info = { value_before_master = 16777215, value_after_master = 8388608, flags = { solo = 0, highlight = 1, lowlight = 0, group_master = 0, additive_master = 0 } } }
  end
  a.GetAttributeByUIChannel = function(i) return named(i == 4609 and "Dimmer" or "ColorRGB_R") end
  local obj = function(addr, name) return { ToAddr = function() return addr end, name = name } end
  a.CurrentUser = function() return obj("User 9", "MCP") end
  a.CurrentProfile = function() return obj("UserProfile 7", "MCP") end
  a.CurrentEnvironment = function() return obj("UserProfile 7.1.1", "Normal") end
  a.CurrentExecPage = function() return obj("Page 4", "Nov 22") end
  a.SelectedSequence = function() return obj("Sequence 14", "Be Glad") end
  a.SelectedLayout = function() return obj("Layout 1", "Portmans") end
  a.SelectedTimecode = function() return nil end
  a.NeedShowSave = function() return true end
  local c = console.new(a)
  if host then c.guard = guard.new({ console = host ~= "onPC", quarantine = {} }) end
  local tools, ctx = {}, { budget_ms = 10000 }
  live.register(tools, c, ctx)
  return fake, tools, ctx
end

h.describe("ma3_selection lists the selected fixtures in selection order", function()
  local _, tools, ctx = api_rig()
  local r = tools.ma3_selection.handler({}, ctx)
  h.eq(r.selected, 3); h.eq(#r.fixtures, 3); h.eq(r.truncated, false)
  h.eq(r.fixtures[1].fid, 101); h.eq(r.fixtures[1].name, "Spot 1"); h.eq(r.fixtures[1].address, "Fixture 101"); h.eq(r.fixtures[1].sf_index, 5)
  h.eq(r.fixtures[3].fid, 201)
  h.eq(r.user, "User 9"); h.eq(r.profile, "UserProfile 7")
end)

h.describe("ma3_selection {limit} stops the walk and says so", function()
  local _, tools, ctx = api_rig()
  local r = tools.ma3_selection.handler({ limit = 2 }, ctx)
  h.eq(#r.fixtures, 2); h.eq(r.selected, 3); h.eq(r.truncated, true)
end)

h.describe("ma3_dmx {universe} lists the addresses that are not zero; {all} gives all 512", function()
  local _, tools, ctx = api_rig()
  local r = tools.ma3_dmx.handler({ universe = 11 }, ctx)
  h.eq(r.universe, 11); h.eq(r.nonzero, 2); h.eq(#r.values, 2)
  h.eq(r.values[1].address, 1); h.eq(r.values[1].value, 255); h.eq(r.values[2].address, 40); h.eq(r.values[2].value, 128)
  local p = tools.ma3_dmx.handler({ universe = 11, percent = true, all = true }, ctx)
  h.eq(#p.values, 512); h.eq(p.values[1], 100); h.eq(p.values[40], 50); h.eq(p.unit, "percent")
  local _, err = tools.ma3_dmx.handler({ universe = 12 }, ctx); h.truthy(err:find("not granted"))
  local _, err2 = tools.ma3_dmx.handler({}, ctx); h.truthy(err2:find("universe"))
end)

h.describe("ma3_values {fixture} gives each channel's attribute, DMX address and value before and after the masters", function()
  local _, tools, ctx = api_rig()
  local r = tools.ma3_values.handler({ fixture = 1 }, ctx)
  h.eq(r.fixture, "Fixture 1"); h.eq(r.name, "Dimmer 1"); h.eq(#r.channels, 2)
  local d, red = r.channels[1], r.channels[2]
  h.eq(d.attribute, "Dimmer"); h.eq(d.universe, nil); h.eq(d.virtual, true); h.eq(d.value, 0)
  h.eq(red.attribute, "ColorRGB_R"); h.eq(red.universe, 11); h.eq(red.address, 1)
  h.eq(red.programmed, 100); h.eq(red.value, 50); h.eq(red.default, 100); h.eq(red.flags[1], "highlight")
  local _, err = tools.ma3_values.handler({ fixture = 99999 }, ctx); h.truthy(err:find("not found"))
end)

h.describe("ma3_user says who the plugin is and what that user has selected", function()
  local _, tools, ctx = api_rig()
  local r = tools.ma3_user.handler({}, ctx)
  h.eq(r.user, "User 9"); h.eq(r.user_name, "MCP"); h.eq(r.profile, "UserProfile 7"); h.eq(r.environment, "Normal")
  h.eq(r.page, "Page 4"); h.eq(r.page_name, "Nov 22"); h.eq(r.selected_sequence, "Sequence 14"); h.eq(r.selected_layout, "Layout 1")
  h.eq(r.selected_timecode, nil); h.eq(r.selection_count, 3); h.eq(r.show_needs_save, true)
end)

h.describe("the API reads are refused on a console until proven there; console_ok opens the supervised first call", function()
  local _, tools, ctx = api_rig("Console")
  for _, name in ipairs({ "ma3_selection", "ma3_dmx", "ma3_values", "ma3_user" }) do
    local _, err = tools[name].handler({ universe = 11, fixture = 1 }, ctx)
    h.truthy(err and err:find("[console-guard]", 1, true), name .. " refused on a console")
    h.truthy(err:find("onPC", 1, true))
  end
  local r = tools.ma3_selection.handler({ console_ok = true }, ctx)
  h.eq(r.selected, 3)
  local _, tools2, ctx2 = api_rig("onPC")
  h.eq(tools2.ma3_selection.handler({}, ctx2).selected, 3)
end)

h.describe("the API reads say so when this console build does not offer the function", function()
  local _, tools, ctx = rig()
  local _, err = tools.ma3_selection.handler({}, ctx)
  h.truthy(err:find("SelectionFirst"))
end)
