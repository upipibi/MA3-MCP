-- The console guard (src/guard.lua): what the plugin may touch on a console, the black-box
-- journal, quarantine after a stall, and the request rate cap. Background: on 2026-11-08 one
-- read froze the console's screen during a service (docs/superpowers/specs/2026-11-08-console-guard-design.md).
local guard = require("guard")
local fake_fs = require("fake_fs")
local json = require("json")
local h = require("helpers")

-- A small object tree with real class names from the console census.
local function node(class, parent, addr)
  local n = { class = class, parent = parent, addr = addr or class }
  function n:GetClass() return self.class end
  function n:Parent() return self.parent end
  function n:ToAddr() return self.addr end
  return n
end
local root = node("Root", nil, "Root")
local showdata = node("ShowData", root, "Root 14")
local pools = node("DataPools", showdata); local pool = node("Pool", pools); local seqs = node("Sequences", pool)
local seq = node("Sequence", seqs, "Sequence 12")
local profiles = node("UserProfiles", showdata); local profile = node("UserProfile", profiles)
local tws = node("TemporaryWindowSettings", profile); local seqsheet = node("SequenceSheetSettings", tws)
local temp = node("Temp", root, "Root 20"); local cmdlines = node("Cmdlines", temp); local cmdline = node("Cmdline", cmdlines)
local undos = node("Undos", cmdline); local undo = node("Undo", undos)
local library = node("Library", cmdline); local file = node("File", library)
local drives = node("DriveCollect", temp); local drive = node("Drive", drives)
local gfx = node("GraphicsRoot", root, "Root 19"); local pults = node("PultCollect", gfx); local pult = node("Pult", pults)
local devices = node("Devices", pult); local keyboard = node("Keyboard", devices)
local tcslots = node("TimecodeSlots", root); local tcslot = node("TCSlot", tcslots)
local sock = node("MAnetSocket", root); local sessions = node("Sessions", sock)

local function new(console, opts)
  opts = opts or {}
  local clock = { t = 0 }
  local fs = opts.fs or fake_fs.new()
  local g = guard.new({ console = console, fs = fs, journal_path = "/lib/ma3_mcp_inflight.json",
    quarantine = opts.quarantine or {}, now = function() return clock.t end, log = function() end })
  return g, clock, fs
end

h.describe("guard: class path walks parents up to Root", function()
  local g = new(true)
  local p = g:class_path(seq)
  h.eq(table.concat(p, " > "), "ShowData > DataPools > Pool > Sequences > Sequence")
  h.eq(#g:class_path(root), 0, "Root itself has an empty path")
end)

h.describe("guard on a console allows the proven branches", function()
  local g = new(true)
  for _, o in ipairs({ root, showdata, pools, pool, seqs, seq, profiles, profile, temp, cmdlines, cmdline, undos, undo,
                        drives, drive, tcslots, tcslot, sock }) do
    local ok, why = g:allow_handle(o)
    h.truthy(ok, o.class .. " allowed: " .. tostring(why))
  end
end)

h.describe("guard on a console refuses everything not proven", function()
  local g = new(true)
  for _, o in ipairs({ gfx, pults, pult, devices, keyboard, library, file, tws, seqsheet, sessions }) do
    local ok, why = g:allow_handle(o)
    h.eq(ok, false, o.class .. " refused")
    h.truthy(tostring(why):find("^%[console%-guard%]"), "message starts with the tag: " .. tostring(why))
    h.truthy(tostring(why):find(o.class, 1, true), "message names the class")
    h.truthy(tostring(why):find("onPC"), "message says where to explore")
  end
end)

h.describe("guard on onPC allows everything (the bench)", function()
  local g = new(false)
  for _, o in ipairs({ gfx, keyboard, file, tws, seq }) do h.truthy((g:allow_handle(o)), o.class) end
end)

h.describe("guard checks addresses and commands for Root branches on a console", function()
  local g = new(true)
  h.truthy((g:allow_address("Sequence 12")))
  h.truthy((g:allow_address("Root 14.9.9.5")))
  h.truthy((g:allow_address("Root 20.1.1")), "Temp is decided by class after resolve")
  local ok, why = g:allow_address("Root 19.1"); h.eq(ok, false); h.truthy(why:find("console%-guard"))
  h.truthy((g:allow_command('Set Root 14.10.9.179 Property "DMXCURVE" 1')))
  h.truthy((g:allow_command('Label Sequence 12 "Song"')))
  local okc, whyc = g:allow_command("Set Root 19.1.1 Property \"x\" 1"); h.eq(okc, false); h.truthy(whyc:find("Root 19"))
  local okq = g:allow_command('Label Sequence 12 "Root 19 is a name"'); h.truthy(okq, "quoted text does not count")
  local onpc = new(false)
  h.truthy((onpc:allow_address("Root 19.1"))); h.truthy((onpc:allow_command("Set Root 19.1 Property \"x\" 1")))
end)

h.describe("guard on a console refuses command keywords that reach outside show data", function()
  local g = new(true)
  for _, cmd in ipairs({
    'Set StationSettings "DesklightsCollect"."DeskLights" Property "Master" 25', "Store View 15 \"x\" /Screen \"1\"",
    "View 2", "V 2", "Assign View 9 At Page 3.291", "Delete ScreenContent *.*", "ViewButton 2.4",
    'Set CurrentUserProfile "SingleStep" "Yes"', "Set CUP \"SingleStep\" \"Yes\"", 'Set UserProfile "Default" "ScreenEncoder" "No"',
    "Call MessageCenter", 'Readout "Hex8"', "Select EncoderBar 2", "Camera 1", "List Console", "List NetworkNode", "List Node",
    'Set Color "Global"."Text" Property "RGBA" "00FF00FF"', "ScreenConfiguration 2", 'Keyboard "English"', "Display 2",
    "Echo 1; Store View 3",
  }) do
    local ok, why = g:allow_command(cmd)
    h.eq(ok, false, cmd); h.truthy(why and why:find("console%-guard") and why:find("show data"), cmd .. ": " .. tostring(why))
  end
  for _, cmd in ipairs({
    'Store Cue 5 "Great Look" /CueOnly', "Collect Preset 4.2", "Copy Cue 1 At 2", "At Measure 4", 'Label Sequence 12 "View"',
    "Label Sequence 12 'Display 2'", 'Set Sequence 1 Property "Autostomp" "Prio"', "Edit Video 1", "Assign Appearance 3 At Group 5",
    "Go+ Sequence 12", "Off Sequence 12", "Label Sequence 12 'Root 19'", "Delete Cue 2 Part 1", "Store Group 3",
  }) do
    local ok, why = g:allow_command(cmd)
    h.truthy(ok, cmd .. ": " .. tostring(why))
  end
  local onpc = new(false)
  h.truthy((onpc:allow_command("Store View 15")), "onPC is the bench")
end)

h.describe("guard journal: written before, done after", function()
  local g, clock, fs = new(true)
  g:begin("ma3_object", { address = "Sequence 12" })
  local j = json.decode(fs.files["/lib/ma3_mcp_inflight.json"])
  h.eq(j.tool, "ma3_object"); h.eq(j.address, "Sequence 12"); h.eq(j.done, nil)
  g:target(seq)
  j = json.decode(fs.files["/lib/ma3_mcp_inflight.json"])
  h.eq(j.path, "ShowData > DataPools > Pool > Sequences > Sequence")
  clock.t = 0.05
  g:finish()
  j = json.decode(fs.files["/lib/ma3_mcp_inflight.json"])
  h.eq(j.done, true)
end)

h.describe("guard recovery: an unfinished journal is quarantined and then refused", function()
  local fs = fake_fs.new()
  fs.files["/lib/ma3_mcp_inflight.json"] = json.encode({ tool = "ma3_object", address = "Root 19.1.1.1.2",
    path = "GraphicsRoot > PultCollect > Pult > Devices > Keyboard", started = 1793900000 })
  local q = {}
  local entry = guard.recover(fs, "/lib/ma3_mcp_inflight.json", q)
  h.truthy(entry, "entry returned"); h.eq(#q, 1); h.eq(q[1].address, "Root 19.1.1.1.2")
  h.eq(json.decode(fs.files["/lib/ma3_mcp_inflight.json"]).done, true, "journal closed after recovery")
  h.eq(guard.recover(fs, "/lib/ma3_mcp_inflight.json", q), nil, "nothing to recover twice"); h.eq(#q, 1)
  -- the same address and class path are refused even on onPC
  local g = new(false, { quarantine = q, fs = fs })
  local ok, why = g:allow_address("Root 19.1.1.1.2"); h.eq(ok, false); h.truthy(why:find("quarantine"))
  local ok2, why2 = g:allow_handle(keyboard); h.eq(ok2, false); h.truthy(why2:find("quarantine"))
  h.truthy((g:allow_handle(seq)), "other objects unaffected")
  -- a finished journal or no journal recovers nothing
  local fs2 = fake_fs.new(); h.eq(guard.recover(fs2, "/x", {}), nil)
  fs2.files["/x"] = '{"done":true}'; h.eq(guard.recover(fs2, "/x", {}), nil)
  fs2.files["/y"] = "not json"; h.eq(guard.recover(fs2, "/y", {}), nil, "a broken journal is ignored")
end)

h.describe("guard recovery quarantines a tool call without an address by tool and arguments", function()
  local fs = fake_fs.new()
  fs.files["/j"] = json.encode({ tool = "ma3_sequences", args = '{"include_cues":true}', started = 1 })
  local q = {}
  guard.recover(fs, "/j", q)
  local g = new(true, { quarantine = q })
  local ok, why = g:admit_call("ma3_sequences", { include_cues = true }); h.eq(ok, false); h.truthy(why:find("quarantine"))
  h.truthy((g:admit_call("ma3_sequences", { include_cues = false })), "different arguments are fine")
end)

h.describe("guard rate cap on a console: 16 at once, then 8 a second", function()
  local g, clock = new(true)
  for i = 1, 16 do h.truthy((g:admit()), "burst " .. i) end
  local ok, why = g:admit(); h.eq(ok, false, "17th refused"); h.truthy(why:find("slow down"))
  clock.t = 0.5
  for i = 1, 4 do h.truthy((g:admit()), "refilled " .. i) end
  h.eq((g:admit()), false, "only 4 refilled in half a second")
  local onpc, c2 = new(false)
  for _ = 1, 100 do h.truthy((onpc:admit())) end
end)
