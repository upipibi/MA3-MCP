-- In-memory stand-in for the grandMA3 Lua API, shaped after onpc-2.5.1.1 facts:
-- handles expose GetClass, ToAddr, Children, Ptr, Count, PropertyCount, PropertyName,
-- PropertyType, Get, Set, Parent, .name, .index. Get() returns NO value for empty props.
local M = {}

local Handle = {}
Handle.__index = function(t, k)
  if k == "name" then return rawget(t, "props").NAME and rawget(t, "props").NAME.v end
  if k == "index" then return rawget(t, "idx") end
  if Handle[k] then return Handle[k] end
  for _, kid in ipairs(rawget(t, "kids")) do
    if kid.props.NAME and kid.props.NAME.v == k then return kid end
  end
  return nil
end
function Handle:GetClass() return self.class end
function Handle:ToAddr() return self.addr end
function Handle:Children() local out = {} for i = 1, self.count do if self.kids[i] then out[#out + 1] = self.kids[i] end end return out end
function Handle:Ptr(i) return self.kids[i] end
function Handle:Count() return self.count end
function Handle:Parent() return self.parent end
function Handle:PropertyCount() return #self.order end
function Handle:PropertyName(i) return self.order[i] end
function Handle:PropertyType(i) return self.props[self.order[i]].t end
function Handle:Get(name)
  local p = self.props[name:upper()]
  if not p or p.v == nil or p.v == "" then return end   -- no value, like the console
  if type(p.v) == "table" and p.v.addr then return p.v end -- handle-valued
  return p.v
end
function Handle:Export(path, filename)
  local fake = rawget(self, "fake_ref")
  if fake then fake.exported = { addr = self.addr, path = path, filename = filename } end
  return true
end
function Handle:Set(name, value)
  local p = self.props[name:upper()]
  if not p then return false end
  if name:upper() == "TAGS" and value == "" then return true end -- silently ignored on console
  p.v = value
  return true
end

local function node(fake, spec, parent, idx)
  local h = setmetatable({ class = spec.class, addr = spec.addr, kids = {}, props = {}, order = {}, parent = parent, idx = idx, fake_ref = fake }, Handle)
  local function prop(n, t, v) h.props[n] = { t = t, v = v }; h.order[#h.order + 1] = n end
  prop("NAME", "String", spec.name or "")
  prop("NO", "UInt32", spec.no)
  prop("NOTE", "String", spec.note or "")
  prop("TAGS", "Custom", spec.tags or "")
  prop("APPEARANCE", "Handle", nil)
  for _, extra in ipairs(spec.props or {}) do prop(extra[1], extra[2], extra[3]) end
  fake.by_addr[spec.addr] = h
  h.count = 0
  for i, k in ipairs(spec.children or {}) do
    local slot = k.slot or i
    h.kids[slot] = node(fake, k, h, slot)
    if slot > h.count then h.count = slot end
  end
  if spec.count and spec.count > h.count then h.count = spec.count end
  if spec.sf_index ~= nil then fake.subfixtures[spec.sf_index] = h end
  return h
end

function M.new(tree)
  local fake = { by_addr = {}, cmds = {}, indirect = {}, cmd_result = "OK", objectlist_calls = {}, echo = {}, yields = 0, clock = 0, slow = false, subfixtures = {} }
  fake.root = node(fake, tree or M.default_tree(), nil, 1)
  fake.api = {
    ObjectList = function(addr)
      table.insert(fake.objectlist_calls, addr)
      local h = fake.by_addr[addr]
      return h and { h } or {}
    end,
    Cmd = function(text, undo) table.insert(fake.cmds, text); fake.last_cmd = text; fake.last_undo = undo; return fake.cmd_result end,
    CmdIndirect = function(text) table.insert(fake.indirect, text) end,
    CreateUndo = function(name) local u = { name = name } fake.last_created_undo = u return u end,
    CloseUndo = function(u) fake.closed_undo = u return 1 end,
    Root = function() return fake.root end,
    DataPool = function() return fake.by_addr["DataPool 1"] end,
    ShowData = function() return fake.by_addr["ShowData"] end,
    Patch = function() return fake.by_addr["Patch"] end,
    Version = function() return "2.5.1.1" end,
    HostType = function() return "onPC" end,
    GetPath = function(kind) return "/fake/" .. tostring(kind) end,
    Echo = function(s) table.insert(fake.echo, s) end,
    Printf = function(s) table.insert(fake.echo, s) end,
    DirList = function() return fake.dirlist or {} end,
    GetSubfixture = function(i) return fake.subfixtures[i] end,
    GetSubfixtureCount = function() local n = 0 for _ in pairs(fake.subfixtures) do n = n + 1 end return n end,
    yield = function() fake.yields = fake.yields + 1; if fake.slow then fake.clock = fake.clock + 0.001 end end,
    now = function() if fake.slow then fake.clock = fake.clock + 0.001 end return fake.clock end,
    Enums = { PathType = { Temp = "temp", Library = "library", Showfiles = "shows" } },
  }
  return fake
end

local function fixture(spec)
  -- spec: { fid, cid, name, addr, sf_index, patch, ftype, children }
  local props = {
    { "FID", "UInt32", spec.fid or "None" }, { "CID", "UInt32", spec.cid or "None" },
    { "IDTYPE", "UInt32", spec.idtype or "Fixture" }, { "PATCH", "Custom", spec.patch or "" },
    { "FIXTURETYPE", "Handle", spec.ftype and { addr = spec.ftype, ToAddr = function(self) return self.addr end } or nil },
    { "MODE", "Handle", spec.mode and { addr = spec.mode, ToAddr = function(self) return self.addr end } or nil },
    { "SUBFIXTUREINDEX", "UInt32", spec.sf_index },
  }
  return { class = "Fixture", addr = spec.addr, name = spec.name, no = spec.no or spec.fid, props = props, sf_index = spec.sf_index, children = spec.children }
end
M.fixture = fixture

local function handle_ref(addr) return { addr = addr, ToAddr = function(self) return self.addr end } end

local function executor(no, label, assigned, extra)
  return { class = "Executor", addr = "Page 1." .. no, name = label, no = no, slot = extra and extra.slot or (no - 100),
    props = { { "OBJECT", "Handle", handle_ref(assigned) }, { "KEYPRESS", "String", "Go+" }, { "FADER", "String", "Master" },
      { "WIDTH", "UInt32", 1 }, { "HEIGHT", "UInt32", 2 } } }
end

function M.default_tree()
  local cues = { { class = "Cue", addr = "Sequence 12 Cue 0", name = "CueZero", no = 0 },
    { class = "Cue", addr = "Sequence 12 OffCue", name = "OffCue", no = nil } }
  for i = 1, 4 do cues[#cues + 1] = { class = "Cue", addr = "Sequence 12 Cue " .. i, name = "Cue " .. i, no = i * 1000,
    props = { { "TRIGTYPE", "String", i == 2 and "Follow" or "Go" }, { "TRIGTIME", "Double", 0 } },
    children = { { class = "Part", addr = "Sequence 12 Cue " .. i .. " Part 0", name = "Part 0", props = { { "CUEINFADE", "Double", i == 2 and 2 or 4 }, { "CUEINDELAY", "Double", 0 }, { "CUEOUTFADE", "String", "CueTiming" }, { "CUEOUTDELAY", "String", "CueTiming" }, { "SNAPDELAY", "Double", 0 }, { "COMMANDDELAY", "Double", 0 }, { "MIBMODE", "String", "" } } } } } end
  -- Fixture 201: a multi-instance fixture with 8 instances (CID 1..8); fixtures 1-3 plain dimmers.
  local inst = {}
  for i = 1, 8 do inst[i] = fixture({ cid = i, no = i, name = "Cell " .. i, addr = "Fixture 201." .. i, sf_index = 100 + i, idtype = "Fixture" }) end
  local seqs = {
    { class = "Sequence", addr = "Sequence 12", name = "Song A", no = 12, note = "walk-in", tags = "Song:0", children = cues, slot = 12 },
    { class = "Sequence", addr = "Sequence 13", name = "Lyrics", no = 13, slot = 13, children = { { class = "Cue", addr = "Sequence 13 Cue 0", name = "CueZero", no = 0 } } },
    { class = "Sequence", addr = "Sequence 14", name = "Song B", no = 14, slot = 14, tags = "Song:0", children = { { class = "Cue", addr = "Sequence 14 Cue 0", name = "CueZero", no = 0 }, { class = "Cue", addr = "Sequence 14 Cue 1", name = "Verse", no = 1 } } },
    { class = "Sequence", addr = "Sequence 20", name = "House", no = 20, slot = 20 },
    { class = "Sequence", addr = "Sequence 21", name = "Walk In", no = 21, slot = 21 },
    { class = "Sequence", addr = "Sequence 300", name = "Old Song", no = 300, slot = 300 },
  }
  return { class = "Root", addr = "Root", name = "Root", children = {
    { class = "ShowData", addr = "ShowData", name = "ShowData", children = {
      { class = "DataPool", addr = "DataPool 1", name = "Default", no = 1, children = {
        { class = "Sequences", addr = "DataPool 1 Sequences", name = "Sequences", count = 2000, children = seqs },
        { class = "Pages", addr = "DataPool 1 Pages", name = "Pages", count = 9999, children = {
          { class = "Page", addr = "Page 1", name = "Weekend", no = 1, count = 390, slot = 1, children = {
            executor(201, "Song A", "Sequence 12"), executor(202, "Song B", "Sequence 14"), executor(101, "House", "Sequence 20") } },
          { class = "Page", addr = "Page 3", name = "Busking", no = 3, count = 390, slot = 3, children = {
            { class = "Executor", addr = "Page 3.101", name = "Song A again", no = 101, slot = 1, props = { { "OBJECT", "Handle", handle_ref("Sequence 12") }, { "KEYPRESS", "String", "Toggle" }, { "FADER", "String", "Master" }, { "WIDTH", "UInt32", 1 }, { "HEIGHT", "UInt32", 1 } } } } },
        } },
        { class = "Groups", addr = "DataPool 1 Groups", name = "Groups", count = 3000, children = {
          { class = "Group", addr = "Group 1", name = "Cells L", no = 1, slot = 1, tags = "LED:0", props = { { "SELECTIONDATA", "Custom", { { sf_index = 101, grid = { x = 0, y = 0, z = 0 } }, { sf_index = 102, grid = { x = 1, y = 0, z = 0 } } } } } },
          { class = "Group", addr = "Group 2", name = "Dimmers", no = 2, slot = 2, props = { { "SELECTIONDATA", "Custom", { { sf_index = 11, grid = { x = 0, y = 0, z = 0 } } } } } },
        } },
        { class = "PresetPools", addr = "DataPool 1 PresetPools", name = "PresetPools", children = {
          { class = "PresetPool", addr = "Preset 1", name = "Dimmer", no = 1, count = 1000, children = { { class = "Preset", addr = "Preset 1.1", name = "Full", no = 1, slot = 1, count = 3 } } },
          { class = "PresetPool", addr = "Preset 4", name = "Color", no = 4, count = 1000, children = { { class = "Preset", addr = "Preset 4.1", name = "Red", no = 1, slot = 1, tags = "Song:0" }, { class = "Preset", addr = "Preset 4.7", name = "Blue", no = 7, slot = 7 } } },
        } },
        { class = "Timecodes", addr = "DataPool 1 Timecodes", name = "Timecodes", count = 1000, children = {
          { class = "Timecode", addr = "Timecode 1", name = "Carol", no = 1, slot = 1, props = { { "DURATION", "String", "3m27:00" }, { "TCSLOT", "UInt32", 1 }, { "FRAMEREADOUT", "String", "S1<30 fps>" } }, children = {
            { class = "TrackGroup", addr = "Timecode 1.1", name = "TrackGroup 1", no = 1, children = {
              { class = "MarkerTrack", addr = "Timecode 1.1.0", name = "Marker", no = 0, children = { { class = "Marker", addr = "Timecode 1.1.0.1", name = "Verse", no = 1, props = { { "TIME", "Double", 12.5 } } } } },
              { class = "Track", addr = "Timecode 1.1.1", name = "<Carol>", no = 1, props = { { "TARGET", "String", "Sequence 12" } }, children = {
                { class = "TimeRange", addr = "Timecode 1.1.1.1", name = "TimeRange 1", no = 1, props = { { "START", "Double", 0 }, { "DURATION", "String", "3m27.00>" }, { "SPEEDFACTOR", "Double", 1 } }, children = {
                  { class = "CmdSubTrack", addr = "Timecode 1.1.1.1.1", name = "CmdSubTrack 1", no = 1, children = {
                    { class = "CmdEvent", addr = "Timecode 1.1.1.1.1.1", name = "Go+", no = 1, props = { { "TIME", "Double", 9.1 }, { "CUEDESTINATION", "String", "Sequence 12.2000" }, { "EXECUTECOMMAND", "String", "---" } } },
                    { class = "CmdEvent", addr = "Timecode 1.1.1.1.1.2", name = "Go+", no = 2, props = { { "TIME", "Double", 0.7 }, { "CUEDESTINATION", "String", "Sequence 12.1000" }, { "EXECUTECOMMAND", "String", "---" } } } } } } } } } } } } } } },
        { class = "Macros", addr = "DataPool 1 Macros", name = "Macros", count = 1000, children = {
          { class = "Macro", addr = "Macro 1", name = "Relays On", no = 1, slot = 1, children = {
            { class = "MacroLine", addr = "Macro 1.1", name = "MacroLine 1", no = 1, props = { { "COMMAND", "String", "Park Group 1100 At 100" }, { "WAIT", "String", "Follow" }, { "ENABLED", "Bool", true } } },
            { class = "MacroLine", addr = "Macro 1.2", name = "MacroLine 2", no = 2, props = { { "COMMAND", "String", "Echo done" }, { "WAIT", "String", "Go" }, { "ENABLED", "Bool", false } } },
            { class = "MacroLine", addr = "Macro 1.3", name = "MacroLine 3", no = 3, props = { { "COMMAND", "String", "Off Page 1" }, { "WAIT", "String", "Follow" }, { "ENABLED", "Bool", true } } } } },
        } },
      } },
      { class = "Patch", addr = "Patch", name = "Patch", children = {
        { class = "Stages", addr = "Patch Stages", name = "Stages", children = {
          { class = "Stage", addr = "Stage 1", name = "Stage 1", no = 1, children = {
            { class = "Spaces", addr = "Stage 1.1", name = "Spaces" },
            { class = "Fixtures", addr = "Stage 1.2", name = "Fixtures", children = {
              fixture({ fid = 8, name = "Dimmer Rack", addr = "Fixture 8", sf_index = 10, ftype = "FixtureType 3", mode = "FixtureType 3.6.1", children = {
                fixture({ fid = 1, name = "Dimmer 1", addr = "Fixture 1", sf_index = 11, patch = "1.001", ftype = "FixtureType 3", mode = "FixtureType 3.6.1" }),
                fixture({ fid = 2, name = "Dimmer 2", addr = "Fixture 2", sf_index = 12, patch = "1.002", ftype = "FixtureType 3" }),
                fixture({ fid = 3, name = "Dimmer 3", addr = "Fixture 3", sf_index = 13, patch = "1.003", ftype = "FixtureType 3" }) } }),
              fixture({ fid = 201, name = "Multi 8 Bar", addr = "Fixture 201", sf_index = 100, patch = "2.001", ftype = "FixtureType 7", mode = "FixtureType 7.1.1", children = inst }),
              fixture({ fid = 300, name = "Spot", addr = "Fixture 300", sf_index = 200, patch = "3.001", ftype = "FixtureType 9" }),
            } },
          } },
        } },
        { class = "FixtureTypes", addr = "Patch FixtureTypes", name = "FixtureTypes", children = {
          { class = "FixtureType", addr = "FixtureType 3", name = "Generic Dimmer", no = 3 },
          { class = "FixtureType", addr = "FixtureType 7", name = "Multi 8", no = 7 },
          { class = "FixtureType", addr = "FixtureType 9", name = "Spot 250", no = 9 } } },
      } },
    } },
    { class = "MAnetSocket", addr = "Root 14.5", name = "MAnetSocket", props = { { "SHOWFILE", "String", "TestShow" }, { "HOSTNAME", "String", "test-host" } } },
    { class = "Temp", addr = "Root 20", name = "Temp", children = {
      { class = "Cmdlines", addr = "Root 20.1", name = "Cmdlines", children = {
        { class = "Cmdline", addr = "Root 20.1.1", name = "Cmdline 1", no = 1, props = { { "USER", "String", "User 5" }, { "PROFILE", "String", "UserProfile 5" }, { "LASTCOMMAND", "String", 'OK: Label Sequence 68 "Joyful"' }, { "LASTCOMMANDEXECUTIONTIME", "UInt64", 3 } }, children = {
          { class = "Undos", addr = "Root 20.1.1.1", name = "Undos", children = {
            { class = "Undo", addr = "Root 20.1.1.1.1", name = "\27[92mClear\27[97m", no = 1, props = { { "SESSIONTIME", "String", "14:00:00" }, { "ELAPSEDTIME", "Int64", 100 } } },
            { class = "Undo", addr = "Root 20.1.1.1.2", name = "\27[92mStore Sequence \27[96m1\27[97m", no = 2, props = { { "SESSIONTIME", "String", "14:00:05" }, { "ELAPSEDTIME", "Int64", 5100 } } },
            { class = "Undo", addr = "Root 20.1.1.1.3", name = "Full", no = 3, props = { { "SESSIONTIME", "String", "14:00:09" }, { "ELAPSEDTIME", "Int64", 9000 } } } } } } } } } } },
  } }
end

return M
