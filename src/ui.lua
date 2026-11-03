-- The plugin window: a floating overlay built from the console's own UI classes
-- (BaseInput > TitleBar + DialogFrame > UILayoutGrid rows). Buttons are wired through the
-- plugin's signalTable (PluginComponent + Clicked), as MA's examples do.
local M = {}

M.WINDOW_NAME = "MA3MCPWindow"
M.MAX_CLIENT_ROWS = 10
M.MAX_BACKUP_ROWS = 5

local APPEARANCE = {
  off = { name = "MCP OFF", color = "#6B6B6B" },
  running = { name = "MCP ON", color = "#2E7D32" },
  stalled = { name = "MCP STALLED", color = "#F1BE48" },
}
function M.appearance(state) return APPEARANCE[state] or APPEARANCE.off end

local function anchors(l, t, r, b) return { left = l, right = r or l, top = t, bottom = b or t } end

local function label(parent, text, font, col, row)
  local o = parent:Append("UIObject")
  o.Text = text
  o.Font = font or "Regular18"
  o.TextalignmentH = "Left"
  o.HasHover = "No"
  o.Padding = { left = 10, right = 10, top = 4, bottom = 4 }
  o.Anchors = anchors(col or 0, row or 0)
  return o
end

local function button(parent, text, signal, wiring, col, row)
  local b = parent:Append("Button")
  b.Text = text
  b.Font = "Medium20"
  b.TextalignmentH = "Centre"
  b.Textshadow = 1
  b.HasHover = "Yes"
  b.Anchors = anchors(col or 0, row or 0)
  b.PluginComponent = wiring.my_handle
  b.Clicked = signal
  return b
end

local Window = {}
Window.__index = Window

local function client_row(c)
  if not c then return "" end
  if (c.bad_pin or 0) > 0 and (c.calls or 0) == 0 then
    return string.format("%s  bad PIN x%d", c.ip, c.bad_pin)
  end
  local s = string.format("%s  %s  calls %d", c.ip, c.name or "?", c.calls or 0)
  if (c.bad_pin or 0) > 0 then s = s .. string.format("  bad PIN x%d", c.bad_pin) end
  return s
end

function Window:refresh(m)
  local w = self.widgets
  if not self:is_open() then return end
  if m.stalled then
    w.state.Text = "STALLED: a dialog is open on the console; dismiss it"
  elseif m.running then
    w.state.Text = "Listening on " .. tostring(m.address)
  else
    w.state.Text = "Off: tap On to start"
  end
  w.toggle.Text = m.running and "Off" or "On"
  w.pin.Text = tostring(m.pin or "")
  w.lua.State = m.lua_enabled and 1 or 0
  for i = 1, M.MAX_CLIENT_ROWS do w.clients[i].Text = client_row(m.clients and m.clients[i]) end
  for i = 1, M.MAX_BACKUP_ROWS do w.backups[i].Text = (m.backups and m.backups[i]) or "" end
  w.display.Text = "Display " .. tostring(m.display_index or self.display_index)
end

function Window:is_open()
  return self.base ~= nil and self.G.IsObjectValid(self.base) == true
end

function Window:close()
  if self:is_open() then
    pcall(function() self.G.Obj.Delete(self.overlay, self.G.Obj.Index(self.base)) end)
  end
  self.base = nil
end

-- G: the console globals (GetDisplayByIndex, GetFocusDisplay, IsObjectValid, Obj, Root)
-- display_index: preferred display; falls back to the focused display.
-- actions: { toggle, regenerate, lua(bool), next_display }
-- wiring: { signalTable, my_handle }
function M.open(G, display_index, model, actions, wiring)
  local display = G.GetDisplayByIndex and G.GetDisplayByIndex(display_index or 1) or nil
  local used_index = display_index or 1
  if not display or not display.ScreenOverlay then
    display = G.GetFocusDisplay()
    used_index = 1
  end
  local overlay = display.ScreenOverlay
  local self = setmetatable({ G = G, overlay = overlay, display_index = used_index, widgets = {}, actions = actions or {} }, Window)

  local base = overlay:Append("BaseInput")
  self.base = base
  base.Name = M.WINDOW_NAME
  base.W = 620
  base.H = 560
  base.Columns = 1
  base.Rows = 2
  base[1][1].SizePolicy = "Fixed"
  base[1][1].Size = "50"
  base[1][2].SizePolicy = "Stretch"
  base.AutoClose = "No"
  base.CloseOnEscape = "No"

  local titleBar = base:Append("TitleBar")
  titleBar.Columns = 2
  titleBar.Rows = 1
  titleBar.Anchors = "0,0"
  titleBar[2][2].SizePolicy = "Fixed"
  titleBar[2][2].Size = "50"
  titleBar.Texture = "corner2"
  local title = titleBar:Append("TitleButton")
  title.Text = "MA3 MCP"
  title.Texture = "corner1"
  title.Anchors = "0,0"
  title.Icon = "network"
  local close = titleBar:Append("CloseButton")
  close.Anchors = "1,0"
  close.Texture = "corner2"

  local frame = base:Append("DialogFrame")
  frame.H = "100%"
  frame.W = "100%"
  frame.Columns = 1
  frame.Rows = 6
  frame.Anchors = anchors(0, 1)
  local sizes = { "50", "60", "44", "230", "120", "44" }
  for i, s in ipairs(sizes) do frame[1][i].SizePolicy = "Fixed"; frame[1][i].Size = s end

  -- row 1: state + On/Off
  local r1 = frame:Append("UILayoutGrid"); r1.Columns = 2; r1.Rows = 1; r1.Anchors = anchors(0, 0)
  r1[2][1].SizePolicy = "Fixed"; r1[2][1].Size = "140"
  self.widgets.state = label(r1, "", "Regular18", 0, 0)
  self.widgets.toggle = button(r1, "Off", "MA3MCP_Toggle", wiring, 1, 0)

  -- row 2: PIN + Regenerate
  local r2 = frame:Append("UILayoutGrid"); r2.Columns = 3; r2.Rows = 1; r2.Anchors = anchors(0, 1)
  r2[2][1].SizePolicy = "Fixed"; r2[2][1].Size = "80"
  r2[2][3].SizePolicy = "Fixed"; r2[2][3].Size = "160"
  label(r2, "PIN", "Regular18", 0, 0)
  self.widgets.pin = label(r2, "", "Medium28", 1, 0)
  button(r2, "Regenerate", "MA3MCP_Regen", wiring, 2, 0)

  -- row 3: Lua toggle
  local r3 = frame:Append("UILayoutGrid"); r3.Columns = 1; r3.Rows = 1; r3.Anchors = anchors(0, 2)
  local lua = r3:Append("CheckBox")
  lua.Text = "Allow Lua execution"
  lua.TextalignmentH = "Left"
  lua.State = 0
  lua.Anchors = anchors(0, 0)
  lua.PluginComponent = wiring.my_handle
  lua.Clicked = "MA3MCP_Lua"
  self.widgets.lua = lua

  -- row 4: clients
  local r4 = frame:Append("UILayoutGrid"); r4.Columns = 1; r4.Rows = M.MAX_CLIENT_ROWS + 1; r4.Anchors = anchors(0, 3)
  label(r4, "Recent clients (newest first)", "Regular16", 0, 0)
  self.widgets.clients = {}
  for i = 1, M.MAX_CLIENT_ROWS do self.widgets.clients[i] = label(r4, "", "Regular16", 0, i) end

  -- row 5: backups
  local r5 = frame:Append("UILayoutGrid"); r5.Columns = 1; r5.Rows = M.MAX_BACKUP_ROWS + 1; r5.Anchors = anchors(0, 4)
  label(r5, "Backups made by MCP (newest first)", "Regular16", 0, 0)
  self.widgets.backups = {}
  for i = 1, M.MAX_BACKUP_ROWS do self.widgets.backups[i] = label(r5, "", "Regular16", 0, i) end

  -- row 6: display picker
  local r6 = frame:Append("UILayoutGrid"); r6.Columns = 2; r6.Rows = 1; r6.Anchors = anchors(0, 5)
  r6[2][1].SizePolicy = "Fixed"; r6[2][1].Size = "160"
  label(r6, "Show this window on", "Regular16", 0, 0)
  self.widgets.display = button(r6, "Display " .. used_index, "MA3MCP_Display", wiring, 1, 0)

  local st = wiring.signalTable
  st.MA3MCP_Toggle = function() if self.actions.toggle then self.actions.toggle() end end
  st.MA3MCP_Regen = function() if self.actions.regenerate then self.actions.regenerate() end end
  st.MA3MCP_Lua = function(caller)
    local on = not ((caller and caller.State or self.widgets.lua.State) == 1)
    self.widgets.lua.State = on and 1 or 0
    if self.actions.lua then self.actions.lua(on) end
  end
  st.MA3MCP_Display = function() if self.actions.next_display then self.actions.next_display() end end

  pcall(function() base:WaitInit() end)
  self:refresh(model or {})
  return self
end

-- Adapter used by main: builds the model from the plugin state S and owns one window.
function M.adapter(G)
  local A = { win = nil, last = 0 }
  local function model_of(S)
    local stalled = false
    if S.running and S.server and S.server.last_step and S.deps and S.deps.now then
      stalled = (S.deps.now() - S.server.last_step) > ((S.ctx and S.ctx.budget_ms or 10000) / 1000)
    end
    return {
      running = S.running, address = S.ctx and S.ctx.address, pin = S.auth and S.auth.pin,
      lua_enabled = S.lua_on, stalled = stalled, clients = S.auth and S.auth.clients or {},
      backups = S.ctx and S.ctx.backups or {}, display_index = S.settings and S.settings.display or 1,
    }
  end
  function A.open_or_focus(S)
    if A.win and A.win:is_open() then A.win:refresh(model_of(S)) return A.win end
    local actions = {
      toggle = function() if S.toggle then S.toggle() end end,
      regenerate = function() if S.regenerate then S.regenerate() end end,
      lua = function(on) S.lua_on = on and true or false end,
      next_display = function() if S.next_display then S.next_display() end end,
    }
    A.win = M.open(G, S.settings and S.settings.display or 1, model_of(S), actions, { signalTable = S.signal_table or {}, my_handle = S.my_handle })
    return A.win
  end
  function A.tick(S)
    if not (A.win and A.win:is_open()) then return end
    local now = S.deps and S.deps.now and S.deps.now() or os.time()
    if now - A.last < 0.5 then return end
    A.last = now
    A.win:refresh(model_of(S))
  end
  function A.close()
    if A.win then A.win:close() end
  end
  return A
end

return M
