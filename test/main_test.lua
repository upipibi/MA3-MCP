local main = require("main")
local fake_socket = require("fake_socket")
local fake_console = require("fake_console")
local fake_fs = require("fake_fs")
local json = require("json")
local h = require("helpers")

local function setup(host_type)
  local fs = fake_socket.new()
  local fc = fake_console.new()
  fc.api.HostType = function() return host_type or "onPC" end
  local files = fake_fs.new()
  local timers = {}
  local plugin = { props = { NAME = "MA3 MCP" } }
  local my_handle = { Parent = function() return { Set = function(_, k, v) plugin.props[k:upper()] = v end, Get = function(_, k) return plugin.props[k:upper()] end, GetClass = function() return "UserPlugin" end, ToAddr = function() return "Plugin 90" end } end }
  local deps = {
    socket = fs, console_api = fc.api, fs = files, settings_path = "/lib/ma3_mcp_settings.json", log_path = "/tmp/ma3_mcp.log",
    Timer = function(fn, delay, count) timers[#timers + 1] = { fn = fn, delay = delay, count = count } end,
    now = fs.gettime, dns_ips = function() return { "127.0.0.1", "10.11.3.10", "192.168.1.5" } end,
    ui = nil,
  }
  local Main, cleanup = main.entry("MA3 MCP", "ma3_mcp", {}, my_handle, deps)
  local t = { fs = fs, fc = fc, files = files, timers = timers, plugin = plugin, cleanup = cleanup, state = main.state() }
  -- Main("") blocks (yields) while the server runs, like the console expects; drive it as a coroutine.
  t.mains = {}
  t.Main = function(display, argument)
    if argument == nil or argument == "" then
      local co = coroutine.create(function() Main(display, argument) end)
      local ok, err = coroutine.resume(co)
      if not ok then error(err) end
      t.mains[#t.mains + 1] = co
      return co
    end
    Main(display, argument)
    -- let blocked Mains notice a stop
    for _, co in ipairs(t.mains) do if coroutine.status(co) == "suspended" then coroutine.resume(co) end end
  end
  t.main_alive = function() for _, co in ipairs(t.mains) do if coroutine.status(co) == "suspended" then return true end end return false end
  return t
end

local function run_timer(t, passes)
  local co = coroutine.create(t.timers[#t.timers].fn)
  for _ = 1, passes do
    if coroutine.status(co) == "dead" then break end
    local ok, err = coroutine.resume(co)
    if not ok then error(err) end
  end
  return co
end

h.describe("main start on onPC binds loopback and launches the server loop", function()
  local t = setup("onPC")
  t.Main(nil, "")
  h.eq(t.state.running, true)
  h.eq(t.state.server.bind_host, "127.0.0.1"); h.eq(t.state.server.port, 9800)
  h.eq(#t.timers, 1, "server loop scheduled as a Timer task")
  h.truthy(t.files.files["/lib/ma3_mcp_settings.json"], "settings saved on first start")
  h.eq(#t.state.auth.pin, 8)
  local echoed = table.concat(t.fc.echo, "\n")
  h.truthy(echoed:find("listening on 127.0.0.1:9800"), echoed)
  h.truthy((t.files.files["/tmp/ma3_mcp.log"] or ""):find("listening on 127.0.0.1:9800"), "log file written")
  h.eq(t.main_alive(), true, "Main stays alive while running (console runs cleanup when it returns)")
  t.Main(nil, "off")
  h.eq(t.state.running, false)
  h.eq(t.main_alive(), false, "Main returns once stopped")
  h.truthy((t.files.files["/tmp/ma3_mcp.log"] or ""):find("stopped"), "stop logged")
end)

h.describe("main start on a console binds the production address", function()
  local t = setup("Console")
  t.Main(nil, "")
  h.eq(t.state.server.bind_host, "10.11.3.10")
  t.Main(nil, "off")
end)

h.describe("main serves a tools/list with the pin and refuses without", function()
  local t = setup("onPC")
  t.Main(nil, "")
  local pin = t.state.auth.pin
  local body = json.encode({ jsonrpc = "2.0", id = 1, method = "tools/list" })
  local good = fake_socket.client({ chunks = { "POST /mcp HTTP/1.1\r\nhost: x\r\nauthorization: Bearer " .. pin .. "\r\nmcp-protocol-version: 2025-11-25\r\ncontent-type: application/json\r\ncontent-length: " .. #body .. "\r\n\r\n" .. body }, ip = "10.11.4.7" })
  local bad = fake_socket.client({ chunks = { "POST /mcp HTTP/1.1\r\nhost: x\r\nauthorization: Bearer WRONGPIN\r\ncontent-length: " .. #body .. "\r\n\r\n" .. body }, ip = "10.11.4.8" })
  table.insert(t.fs.pending, good); table.insert(t.fs.pending, bad)
  run_timer(t, 4)
  h.truthy(good.sent:find("^HTTP/1.1 200"), good.sent)
  local r = json.decode(good.sent:match("\r\n\r\n(.*)$"))
  local names = {}
  for _, tool in ipairs(r.result.tools) do names[tool.name] = true end
  for _, n in ipairs({ "ma3_status", "ma3_object", "ma3_children", "ma3_dump", "ma3_set", "ma3_command", "ma3_undo_close", "ma3_fixtures", "ma3_groups", "ma3_sequences", "ma3_pages", "ma3_presets", "ma3_macros", "ma3_backup", "ma3_save", "ma3_lua" }) do
    h.truthy(names[n], "tool " .. n)
  end
  h.truthy(bad.sent:find("^HTTP/1.1 401"), bad.sent)
  h.eq(t.state.auth.clients[1].ip, "10.11.4.8"); h.eq(t.state.auth.clients[1].bad_pin, 1)
  h.eq(t.state.auth.clients[2].ip, "10.11.4.7"); h.eq(t.state.auth.clients[2].calls, 1)
  h.eq(t.state.ctx.request_count, 1)
  t.Main(nil, "off")
  local saved = json.decode(t.files.files["/lib/ma3_mcp_settings.json"])
  h.eq(saved.clients[1].ip, "10.11.4.8", "clients persisted at stop")
end)

h.describe("main arguments: pin, lua on/off, status, port, regen", function()
  local t = setup("onPC")
  t.Main(nil, "")
  local pin = t.state.auth.pin
  t.fc.echo = {}
  t.Main(nil, "pin")
  h.truthy(table.concat(t.fc.echo, "\n"):find(pin, 1, true))
  h.eq(t.state.ctx.lua_enabled(), false)
  t.Main(nil, "lua on"); h.eq(t.state.ctx.lua_enabled(), true)
  t.Main(nil, "lua off"); h.eq(t.state.ctx.lua_enabled(), false)
  t.fc.echo = {}
  t.Main(nil, "status")
  h.truthy(table.concat(t.fc.echo, "\n"):find("running"))
  t.Main(nil, "regen")
  h.truthy(t.state.auth.pin ~= pin); h.eq(json.decode(t.files.files["/lib/ma3_mcp_settings.json"]).pin, t.state.auth.pin)
  t.Main(nil, "9801")
  h.eq(t.state.settings.port, 9801)
  t.Main(nil, "off")
  t.Main(nil, "")
  h.eq(t.state.server.port, 9801, "new port used on the next start")
  h.eq(t.state.ctx.lua_enabled(), false, "lua resets to off at every start")
  t.Main(nil, "off")
end)

h.describe("main second tap while running does not restart", function()
  local t = setup("onPC")
  t.Main(nil, "")
  local srv = t.state.server
  t.Main(nil, "")
  h.eq(t.state.server, srv); h.eq(#t.timers, 1)
  t.cleanup()
  h.eq(t.state.running, false)
  for _, co in ipairs(t.mains) do if coroutine.status(co) == "suspended" then coroutine.resume(co) end end
  h.eq(t.main_alive(), false)
end)

h.describe("main bind failure reports and stays off", function()
  local t = setup("onPC")
  t.fs.fail_bind = "address already in use"
  t.Main(nil, "")
  h.eq(t.state.running, false)
  h.truthy(table.concat(t.fc.echo, "\n"):find("address already in use"))
end)

h.describe("main window toggle: Off stops in place, On relaunches the plugin through the command line", function()
  local t = setup("onPC")
  t.Main(nil, "")
  h.eq(t.state.running, true)
  t.state.toggle()
  h.eq(t.state.running, false, "Off stops the server directly")
  t.state.toggle()
  h.eq(t.state.running, false, "On does not start outside a Main session")
  h.eq(t.fc.indirect[#t.fc.indirect], 'Plugin "MA3 MCP"', "On asks the console to run the plugin, which starts a new Main")
end)

h.describe("main bind argument persists and is used on the next start", function()
  local t = setup("Console")
  t.Main(nil, "bind 10.11.3.10")
  h.eq(json.decode(t.files.files["/lib/ma3_mcp_settings.json"]).bind, "10.11.3.10")
  t.Main(nil, "")
  h.eq(t.state.server.bind_host, "10.11.3.10")
  t.Main(nil, "off")
  t.Main(nil, "bind auto")
  h.eq(json.decode(t.files.files["/lib/ma3_mcp_settings.json"]).bind, nil, "auto clears the override")
  t.Main(nil, "bind nonsense")
  h.truthy(table.concat(t.fc.echo, "\n"):find("bind"), "bad address reported")
end)

h.describe("main shows state on the pool button through an Appearance named MA3 MCP when one exists", function()
  local t = setup("onPC")
  t.fc.by_addr['Appearance "MA3 MCP"'] = t.fc.by_addr["Root 14.5"]  -- any object: the name exists
  t.Main(nil, "")
  local joined = table.concat(t.fc.cmds, "\n")
  h.truthy(joined:find('Set Plugin 90 Property "Appearance" "MA3 MCP"', 1, true), joined)
  t.Main(nil, "off")
  joined = table.concat(t.fc.cmds, "\n")
  h.truthy(joined:find('Set Plugin 90 Property "Appearance" ""', 1, true), "cleared on stop: " .. joined)
  local t2 = setup("onPC")
  t2.Main(nil, "")
  h.eq(#t2.fc.cmds, 0, "no Appearance named MA3 MCP: nothing is sent")
  t2.Main(nil, "off")
end)
