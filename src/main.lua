-- Plugin entry: wires settings, auth, the dispatcher and tools to the socket server, runs
-- the server loop as a console Timer task, and handles the pool-button / command arguments.
--
-- In the console the bundle calls main.entry(pluginName, componentName, signalTable, my_handle)
-- and returns its Main, cleanup. Tests pass a deps table to replace sockets, console API,
-- file system, Timer and clock.
local http = require("http")
local mcp = require("mcp")
local server = require("server")
local auth = require("auth")
local settings = require("settings")
local console = require("console")
local log = require("log")
local generic = require("tools.generic")
local bulk = require("tools.bulk")
local show = require("tools.show")
local lua_exec = require("tools.lua_exec")

local M = {}
M.VERSION = "0.1.0"
M.PORT = 9800
M.PROD_PREFIX = "^10%.11%.(%d+)%."   -- 10.11.0.0/20 = 10.11.0.x .. 10.11.15.x
M.SETTINGS_FILE = "ma3_mcp_settings.json"

M.INSTRUCTIONS = [[MA3 MCP: this server runs inside a grandMA3 console. Read first, then act.
Start a job with ma3_status, then the bulk reads (ma3_fixtures, ma3_sequences, ma3_pages, ma3_groups, ma3_presets, ma3_macros).
Before deleting or rewriting anything: show the plan, wait for a go, then ma3_backup.
Writes are ma3_command (MA command-line text) and ma3_set. A timeout proves nothing: re-read state before resending.
Never pass Thru, +, or * on Page/Executor addresses (the console hangs); the tools refuse them.
Group commands into ma3_command {undo_group} and close with ma3_undo_close so one Oops reverts the job.]]

local S = { running = false }
function M.state() return S end

local json = require("json")

local function io_fs()
  return {
    read = function(path) local f = io.open(path, "r") if not f then return nil end local d = f:read("a") f:close() return d end,
    write = function(path, data) local f, err = io.open(path, "w") if not f then return nil, err end f:write(data) f:close() return true end,
    append = function(path, data) local f, err = io.open(path, "a") if not f then return nil, err end f:write(data) f:close() return true end,
  }
end

-- A log that also appends to a file (rolled when it passes ~256 KB) so a stalled or
-- crashed start can be read back from the console's temp folder.
local function make_log(deps)
  local path = deps.log_path
  local sink
  if path and deps.fs.append then
    sink = function(line)
      local stamp = os.date("%Y-%m-%d %H:%M:%S")
      deps.fs.append(path, stamp .. " " .. line .. "\n")
    end
  end
  return log.new(200, sink)
end

local function real_dns_ips()
  local socket = require("socket")
  local out = {}
  local ok, host = pcall(socket.dns.gethostname)
  if not ok or not host then return out end
  local ok2, info = pcall(socket.dns.getaddrinfo, host)
  if ok2 and type(info) == "table" then
    for _, a in ipairs(info) do if a.family == "inet" and a.addr then out[#out + 1] = a.addr end end
  end
  return out
end

local function pick_bind(deps, c, cfg)
  if cfg.bind then return cfg.bind, "settings" end
  if c:host_type() == "onPC" then return "127.0.0.1", "onPC" end
  for _, ip in ipairs(deps.dns_ips()) do
    local third = ip:match(M.PROD_PREFIX)
    if third and tonumber(third) <= 15 then return ip, "production network" end
  end
  return "127.0.0.1", "no production-network address found; set \"bind\" in " .. M.SETTINGS_FILE
end

local function error_body(status, reason)
  local msgs = { missing = "missing Authorization: Bearer <PIN>", wrong = "wrong PIN", locked = "too many wrong PINs; try again in a few minutes", origin = "origin not allowed" }
  return status, { ["Content-Type"] = "application/json" },
    json.encode({ jsonrpc = "2.0", error = { code = -32001, message = msgs[reason] or reason } })
end

local function persist()
  if not S.settings then return end
  S.settings.clients = S.auth and S.auth.clients or S.settings.clients
  S.settings.backups = S.ctx and S.ctx.backups or S.settings.backups
  S.settings.pin = S.auth and S.auth.pin or S.settings.pin
  local ok, err = settings.save(S.deps.fs, S.deps.settings_path, S.settings)
  if not ok then S.log:add("could not save settings: %s", tostring(err)) end
end

local function stop(why)
  if S.server then S.server:stop() end
  S.running = false
  persist()
  if S.log then S.log:add("stopped (%s)", why or "off") end
  if S.c then S.c:echo("MA3 MCP: stopped (%s)", why or "off") end
end

local function start()
  local deps, c = S.deps, S.c
  S.log = S.log or make_log(deps)
  S.log:add("starting v%s", M.VERSION)
  S.settings = settings.load(deps.fs, deps.settings_path)
  if S.settings.generated then settings.save(deps.fs, deps.settings_path, S.settings) end
  local bind, how = pick_bind(deps, c, S.settings)
  local port = S.settings.port or M.PORT
  local address = bind .. ":" .. port

  S.auth = auth.new({ pin = S.settings.pin, now = deps.now, origin_allowed = "http://" .. address })
  S.auth.clients = S.settings.clients or {}
  S.lua_on = false
  S.ctx = {
    budget_ms = 10000, lua_enabled = function() return S.lua_on end, plugin_version = M.VERSION,
    started_at = deps.now(), request_count = 0, last_backup = nil, log = S.log, address = address,
    backups = S.settings.backups or {}, on_backup = function() persist() end,
  }
  local tools = {}
  generic.register(tools, c, S.ctx)
  bulk.register(tools, c, S.ctx)
  show.register(tools, c, S.ctx)
  lua_exec.register(tools, c, S.ctx, deps.globals)
  S.tools = tools
  S.dispatcher = mcp.new({ server_name = "MA3 MCP", server_version = M.VERSION, tools = tools, instructions = M.INSTRUCTIONS })

  local handler = function(req, ip)
    local ok, status, reason = S.auth:check(req, ip)
    if not ok then
      S.log:add("refused %s from %s (%s)", req.method .. " " .. tostring(req.path), ip, reason)
      local _, hdrs, body = error_body(status, reason)
      return status, hdrs, body
    end
    if req.path ~= "/mcp" then return 404, { ["Content-Type"] = "text/plain" }, "not found" end
    S.ctx.request_count = S.ctx.request_count + 1
    S.auth:record_client(ip, mcp.client_name(req) or http.header(req, "user-agent"))
    return S.dispatcher:handle(req, S.ctx)
  end

  S.server = server.new({ bind = bind, port = port, socket = deps.socket, now = deps.now, handler = handler,
    log = function(fmt, ...) S.log:add(fmt, ...) end })
  local ok, err = S.server:start()
  if not ok then
    S.running = false
    c:echo("MA3 MCP: could not listen on %s: %s", address, tostring(err))
    S.log:add("bind failed on %s: %s", address, tostring(err))
    return false
  end
  S.running = true
  S.log:add("listening on %s (%s)", address, how)
  c:echo("MA3 MCP v%s: listening on %s (%s). PIN: %s", M.VERSION, address, how, S.auth.pin)
  deps.Timer(function()
    while S.running do
      local okS, e = pcall(S.server.step, S.server)
      if not okS then S.log:add("server step error: %s", tostring(e)) end
      coroutine.yield()
    end
  end, 0, 1)
  return true
end

local function status_text()
  local lines = {}
  lines[#lines + 1] = string.format("MA3 MCP v%s: %s", M.VERSION, S.running and ("running on " .. S.ctx.address) or "off")
  if S.auth then lines[#lines + 1] = "PIN: " .. S.auth.pin end
  if S.ctx then lines[#lines + 1] = string.format("requests: %d, Lua: %s, clients: %d", S.ctx.request_count, S.lua_on and "on" or "off", #S.auth.clients) end
  return lines
end

function M.entry(pluginName, componentName, signalTable, my_handle, deps)
  deps = deps or {}
  deps.socket = deps.socket or require("socket")
  deps.fs = deps.fs or io_fs()
  deps.Timer = deps.Timer or Timer
  deps.dns_ips = deps.dns_ips or real_dns_ips
  deps.now = deps.now or deps.socket.gettime
  deps.idle = deps.idle or function() coroutine.yield(0.2) end
  S.deps = deps
  S.plugin_name = pluginName
  S.my_handle = my_handle
  S.c = deps.console_api and console.new(deps.console_api) or console.real()
  if deps.now and not deps.console_api then S.c.now_fn = deps.now end
  if not deps.settings_path then
    local ok, lib = pcall(function() return S.c:path("Library") end)
    deps.settings_path = ((ok and lib) or ".") .. "/" .. M.SETTINGS_FILE
  end
  if not deps.log_path then
    local ok, tmp = pcall(function() return S.c:path("Temp") end)
    deps.log_path = ((ok and tmp) or ".") .. "/ma3_mcp.log"
  end
  S.log = make_log(deps)
  S.log:add("loaded v%s as plugin %q component %q", M.VERSION, tostring(pluginName), tostring(componentName))

  local function Main(display_handle, argument)
    local arg = tostring(argument or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local lower = arg:lower()
    if lower == "" then
      if S.running then
        -- a second tap while running: just bring the window back
        if deps.ui then pcall(deps.ui.open_or_focus, S, display_handle) end
        return
      end
      if not start() then return end
      if deps.ui then pcall(deps.ui.open_or_focus, S, display_handle) end
      -- The console runs cleanup as soon as Main returns, so Main stays alive for as long
      -- as the server runs. This loop is also where the window gets refreshed.
      S.generation = (S.generation or 0) + 1
      local mine = S.generation
      while S.running and S.generation == mine do
        if deps.ui then pcall(deps.ui.tick, S) end
        deps.idle()
      end
      return
    end
    if lower == "off" or lower == "stop" then stop("off") return end
    if lower == "status" then for _, l in ipairs(status_text()) do S.c:echo(l) end return end
    if lower == "pin" then
      local pin = S.auth and S.auth.pin or settings.load(deps.fs, deps.settings_path).pin
      S.c:echo("MA3 MCP PIN: %s", pin) return
    end
    if lower == "lua on" then S.lua_on = true S.c:echo("MA3 MCP: Lua execution ON") return end
    if lower == "lua off" then S.lua_on = false S.c:echo("MA3 MCP: Lua execution off") return end
    if lower == "regen" then
      if not S.auth then S.settings = settings.load(deps.fs, deps.settings_path); S.auth = auth.new({ pin = S.settings.pin, now = deps.now }) end
      local pin = S.auth:regenerate()
      persist()
      S.c:echo("MA3 MCP: new PIN %s", pin) return
    end
    local port = tonumber(arg)
    if port and port == math.floor(port) and port > 0 and port < 65536 then
      S.settings = S.settings or settings.load(deps.fs, deps.settings_path)
      S.settings.port = math.floor(port)
      persist()
      S.c:echo("MA3 MCP: port set to %d (takes effect at the next start)", port) return
    end
    S.c:echo('MA3 MCP: unknown argument "%s" (use: off, status, pin, lua on, lua off, regen, <port>)', arg)
  end

  local function cleanup()
    if S.running then stop("cleanup") end
  end

  local function guarded(fn, label)
    return function(...)
      local ok, err = xpcall(fn, debug.traceback, ...)
      if not ok then
        S.log:add("%s failed: %s", label, tostring(err))
        pcall(function() S.c:echo("MA3 MCP: %s failed: %s", label, tostring(err):match("^[^\n]*")) end)
      end
    end
  end

  return guarded(Main, "Main"), guarded(cleanup, "cleanup")
end

return M
