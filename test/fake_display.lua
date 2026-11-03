-- Fake grandMA3 UI objects: Append() records a tree of widgets; properties are plain fields;
-- obj[r][c] cells exist for layout settings; IsObjectValid/Obj.Delete are provided as globals.
local M = {}

local Widget = {}
Widget.__index = function(t, k)
  if type(k) == "number" then
    local cells = rawget(t, "_cells")
    if not cells[k] then
      cells[k] = setmetatable({}, { __index = function(row, c) local v = rawget(row, c) if v == nil then v = {} rawset(row, c, v) end return v end })
    end
    return cells[k]
  end
  return Widget[k]
end

function Widget:Append(class)
  local w = setmetatable({ _class = class, _children = {}, _cells = {}, _valid = true, _parent = self }, Widget)
  table.insert(self._children, w)
  return w
end
function Widget:GetClass() return self._class end
function Widget:WaitInit() return true end
function Widget:ClearUIChildren() self._cleared = true end
function Widget:UIChildren() return self._children end

-- test helpers
function Widget:find_all(class, out)
  out = out or {}
  for _, c in ipairs(self._children) do
    if c._class == class then out[#out + 1] = c end
    c:find_all(class, out)
  end
  return out
end
function Widget:find_text(text)
  for _, c in ipairs(self._children) do
    if c.Text == text then return c end
    local f = c:find_text(text)
    if f then return f end
  end
end

function M.new()
  local display = setmetatable({ _class = "Display", _children = {}, _cells = {}, _valid = true, W = 1920, H = 1080 }, Widget)
  display.ScreenOverlay = display:Append("ScreenOverlay")
  local G = {}
  G.GetDisplayByIndex = function(i) if i == 1 then return display end return nil end
  G.GetFocusDisplay = function() return display end
  G.IsObjectValid = function(o) return o ~= nil and o._valid == true end
  G.Obj = {
    Index = function(o) for i, c in ipairs(o._parent._children) do if c == o then return i end end end,
    Delete = function(parent, i) local o = table.remove(parent._children, i) if o then o._valid = false end end,
  }
  G.Root = function() return { ColorTheme = { ColorGroups = { Global = { Transparent = "Global.Transparent", Text = "Global.Text" }, Button = { Background = "Button.Background", BackgroundPlease = "Button.BackgroundPlease" } } } } end
  return display, G
end

return M
