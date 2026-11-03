local ui = require("ui")
local fake_display = require("fake_display")
local h = require("helpers")

local function model(over)
  local m = { running = true, address = "10.11.3.10:9800", pin = "ABCD2345", lua_enabled = false, stalled = false,
    clients = { { ip = "10.11.4.7", name = "claude-code", last_seen = 1000, calls = 3, bad_pin = 0 }, { ip = "10.11.4.8", name = nil, last_seen = 990, calls = 0, bad_pin = 2 } },
    backups = { "Christmas 2026_mcp_1103_1420" }, display_index = 1 }
  for k, v in pairs(over or {}) do m[k] = v end
  return m
end

local function setup()
  local display, G = fake_display.new()
  local signalTable, my_handle = {}, { id = "plugin" }
  local calls = {}
  local actions = {
    toggle = function() calls[#calls + 1] = "toggle" end,
    regenerate = function() calls[#calls + 1] = "regenerate" end,
    lua = function(on) calls[#calls + 1] = "lua:" .. tostring(on) end,
    next_display = function() calls[#calls + 1] = "display" end,
  }
  local win = ui.open(G, 1, model(), actions, { signalTable = signalTable, my_handle = my_handle })
  return display, G, signalTable, win, calls, my_handle
end

h.describe("ui.open builds one BaseInput with a title bar and close button", function()
  local display, G, _, win = setup()
  local bases = display.ScreenOverlay:find_all("BaseInput")
  h.eq(#bases, 1)
  h.eq(bases[1].Name, "MA3MCPWindow"); h.eq(bases[1].AutoClose, "No")
  h.eq(#bases[1]:find_all("TitleBar"), 1); h.eq(#bases[1]:find_all("CloseButton"), 1)
  h.truthy(bases[1]:find_text("MA3 MCP"), "title text")
  h.eq(display.ScreenOverlay._cleared, nil, "never clears the console's own overlays")
  h.eq(win:is_open(), true)
end)

h.describe("ui shows state, address, pin, lua, clients, backups", function()
  local display, _, _, win = setup()
  local base = display.ScreenOverlay:find_all("BaseInput")[1]
  h.truthy(base:find_text("Listening on 10.11.3.10:9800"), "address row")
  h.truthy(base:find_text("ABCD2345"), "pin shown")
  h.truthy(base:find_text("Off"), "On/Off button reads Off while running")
  local lua = base:find_all("CheckBox")[1]
  h.eq(lua.State, 0); h.eq(lua.Text, "Allow Lua execution")
  h.truthy(base:find_text("10.11.4.7  claude-code  calls 3"), "client row")
  h.truthy(base:find_text("10.11.4.8  bad PIN x2"), "bad pin row")
  h.truthy(base:find_text("Christmas 2026_mcp_1103_1420"), "backup row")
  h.truthy(base:find_text("Display 1"), "display picker")
end)

h.describe("ui buttons are wired through signalTable and the plugin handle", function()
  local display, _, signalTable, win, calls, my_handle = setup()
  local base = display.ScreenOverlay:find_all("BaseInput")[1]
  local buttons = base:find_all("Button")
  h.truthy(#buttons >= 3)
  for _, b in ipairs(buttons) do h.eq(b.PluginComponent, my_handle, "PluginComponent set on " .. tostring(b.Text)) h.truthy(b.Clicked, "Clicked set") end
  signalTable[base:find_text("Off").Clicked]()
  signalTable[base:find_text("Regenerate").Clicked]()
  local lua = base:find_all("CheckBox")[1]
  signalTable[lua.Clicked](lua)
  signalTable[base:find_text("Display 1").Clicked]()
  h.eq(table.concat(calls, ","), "toggle,regenerate,lua:true,display")
end)

h.describe("ui.refresh updates texts without rebuilding", function()
  local display, _, _, win = setup()
  local base = display.ScreenOverlay:find_all("BaseInput")[1]
  win:refresh(model({ running = false, pin = "ZZZZ9999", lua_enabled = true, clients = {}, backups = {}, stalled = false }))
  h.eq(#display.ScreenOverlay:find_all("BaseInput"), 1, "same window")
  h.truthy(base:find_text("ZZZZ9999")); h.truthy(base:find_text("Off: tap On to start")); h.truthy(base:find_text("On"))
  h.eq(base:find_all("CheckBox")[1].State, 1)
  win:refresh(model({ stalled = true }))
  h.truthy(base:find_text("STALLED: a dialog is open on the console; dismiss it"), "stalled row")
end)

h.describe("ui.close and reopen", function()
  local display, G, signalTable, win = setup()
  win:close()
  h.eq(win:is_open(), false); h.eq(#display.ScreenOverlay:find_all("BaseInput"), 0)
  local win2 = ui.open(G, 1, model(), {}, { signalTable = signalTable, my_handle = {} })
  h.eq(#display.ScreenOverlay:find_all("BaseInput"), 1); h.eq(win2:is_open(), true)
end)

h.describe("ui falls back to the focus display when the index is absent", function()
  local display, G = fake_display.new()
  local win = ui.open(G, 3, model(), {}, { signalTable = {}, my_handle = {} })
  h.eq(#display.ScreenOverlay:find_all("BaseInput"), 1); h.eq(win.display_index, 1)
end)

h.describe("ui.appearance", function()
  h.eq(ui.appearance("off").name, "MCP OFF"); h.eq(ui.appearance("off").color, "#6B6B6B")
  h.eq(ui.appearance("running").name, "MCP ON"); h.eq(ui.appearance("running").color, "#2E7D32")
  h.eq(ui.appearance("stalled").name, "MCP STALLED"); h.eq(ui.appearance("stalled").color, "#F1BE48")
end)

h.describe("ui.adapter drives the window from the plugin state", function()
  local display, G = fake_display.new()
  local now = 1000
  local S = { running = true, auth = { pin = "ABCD2345", clients = {} }, ctx = { address = "127.0.0.1:9800", backups = {}, budget_ms = 10000 },
    lua_on = false, settings = { display = 1 }, server = { last_step = 1000 }, signal_table = {}, my_handle = {}, deps = { now = function() return now end },
    toggle = function() end }
  local a = ui.adapter(G)
  a.open_or_focus(S)
  h.eq(#display.ScreenOverlay:find_all("BaseInput"), 1)
  a.open_or_focus(S)
  h.eq(#display.ScreenOverlay:find_all("BaseInput"), 1, "second call focuses, does not duplicate")
  now = 1012  -- server loop silent for 12 s
  a.tick(S)
  h.truthy(display.ScreenOverlay:find_all("BaseInput")[1]:find_text("STALLED: a dialog is open on the console; dismiss it"))
end)

h.describe("ui.adapter.refresh redraws at once, ignoring the tick throttle", function()
  local display, G = fake_display.new()
  local S = { running = true, auth = { pin = "ABCD2345", clients = {} }, ctx = { address = "127.0.0.1:9800", backups = {}, budget_ms = 10000 },
    lua_on = false, settings = { display = 1 }, server = { last_step = 1000 }, signal_table = {}, my_handle = {}, deps = { now = function() return 1000 end } }
  local a = ui.adapter(G)
  a.open_or_focus(S)
  local base = display.ScreenOverlay:find_all("BaseInput")[1]
  h.truthy(base:find_text("Off"), "shows Off while running")
  S.running = false
  a.refresh(S)
  h.truthy(base:find_text("Off: tap On to start")); h.truthy(base:find_text("On"), "button reads On after a stop")
end)
