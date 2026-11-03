-- In-memory stand-in for the grandMA3 Lua API, shaped after onpc-2.5.1.1 facts:
-- handles expose GetClass, ToAddr, Children, Ptr, Count, PropertyCount, PropertyName,
-- PropertyType, Get, Set, Parent, .name, .index. Get() returns NO value for empty props.
local M = {}

local Handle = {}
Handle.__index = function(t, k)
  if k == "name" then return rawget(t, "props").NAME and rawget(t, "props").NAME.v end
  if k == "index" then return rawget(t, "idx") end
  return Handle[k]
end
function Handle:GetClass() return self.class end
function Handle:ToAddr() return self.addr end
function Handle:Children() local out = {} for i, c in ipairs(self.kids) do out[i] = c end return out end
function Handle:Ptr(i) return self.kids[i] end
function Handle:Count() return #self.kids end
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
function Handle:Set(name, value)
  local p = self.props[name:upper()]
  if not p then return false end
  if name:upper() == "TAGS" and value == "" then return true end -- silently ignored on console
  p.v = value
  return true
end

local function node(fake, spec, parent, idx)
  local h = setmetatable({ class = spec.class, addr = spec.addr, kids = {}, props = {}, order = {}, parent = parent, idx = idx }, Handle)
  local function prop(n, t, v) h.props[n] = { t = t, v = v }; h.order[#h.order + 1] = n end
  prop("NAME", "String", spec.name or "")
  prop("NO", "UInt32", spec.no)
  prop("NOTE", "String", spec.note or "")
  prop("TAGS", "Custom", spec.tags or "")
  prop("APPEARANCE", "Handle", nil)
  for _, extra in ipairs(spec.props or {}) do prop(extra[1], extra[2], extra[3]) end
  fake.by_addr[spec.addr] = h
  for i, k in ipairs(spec.children or {}) do h.kids[i] = node(fake, k, h, i) end
  return h
end

function M.new(tree)
  local fake = { by_addr = {}, cmds = {}, indirect = {}, cmd_result = "OK", objectlist_calls = {}, echo = {}, yields = 0, clock = 0, slow = false }
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
    yield = function() fake.yields = fake.yields + 1; if fake.slow then fake.clock = fake.clock + 0.001 end end,
    now = function() if fake.slow then fake.clock = fake.clock + 0.001 end return fake.clock end,
    Enums = { PathType = { Temp = "temp", Library = "library", Showfiles = "shows" } },
  }
  return fake
end

function M.default_tree()
  local cues = {}
  for i = 1, 4 do cues[i] = { class = "Cue", addr = "Sequence 12 Cue " .. i, name = "Cue " .. i, no = i } end
  return { class = "Root", addr = "Root", name = "Root", children = {
    { class = "ShowData", addr = "ShowData", name = "ShowData", children = {
      { class = "DataPool", addr = "DataPool 1", name = "Default", no = 1, children = {
        { class = "Sequences", addr = "DataPool 1 Sequences", name = "Sequences", children = {
          { class = "Sequence", addr = "Sequence 12", name = "Song A", no = 12, note = "walk-in", tags = "Song:0", children = cues },
          { class = "Sequence", addr = "Sequence 13", name = "Lyrics", no = 13 },
        } },
      } },
    } },
    { class = "MAnetSocket", addr = "Root 14.5", name = "MAnetSocket", props = { { "SHOWFILE", "String", "TestShow" }, { "HOSTNAME", "String", "test-host" } } },
  } }
end

return M
