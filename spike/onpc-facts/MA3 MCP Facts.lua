-- MA3 MCP Facts: throwaway discovery spike for onPC 2.5.1. Prints the facts the real
-- plugin's design depends on and writes them to the temp folder.
local pluginName, componentName, signalTable, my_handle = select(1, ...), select(2, ...), select(3, ...), select(4, ...)
local socket = require("socket")
local lines = {}
local function P(fmt, ...)
  local s = string.format(fmt, ...)
  table.insert(lines, s)
  Printf("Facts: " .. s)
end
local function try(label, fn)
  local ok, res = pcall(fn)
  P("%s: %s", label, ok and tostring(res) or ("ERROR " .. tostring(res)))
  return ok and res or nil
end
local function save()
  local path = GetPath(Enums.PathType.Temp) .. "/ma3_mcp_facts.txt"
  local f = io.open(path, "w")
  if f then f:write(table.concat(lines, "\n"), "\n") f:close() P("written to %s", path) else P("could not write %s", path) end
end

local function Main(display_handle, argument)
  P("--- (g) versions and paths ---")
  P("_VERSION=%s socket=%s", _VERSION, tostring(socket._VERSION))
  try("Version()", function() return Version() end)
  try("HostOS()", function() return HostOS() end)
  try("HostType()", function() return HostType() end)
  for _, k in ipairs({"Temp", "PluginFiles", "Library", "Showfiles", "UserPlugins", "Plugins"}) do
    try("GetPath(" .. k .. ")", function() return GetPath(Enums.PathType[k]) end)
  end
  try("my_handle.fullpath", function() return my_handle.fullpath end)
  try("my_handle:Parent():ToAddr()", function() return my_handle:Parent():ToAddr() end)
  try("string.split exists", function() return tostring(string.split ~= nil) end)
  try("json loads", function() return tostring(require("json") ~= nil) end)
  try("lfs loads", function() return tostring(require("lfs") ~= nil) end)

  P("--- (d) network objects ---")
  try("Root().maNetSocket.hostname", function() return Root().maNetSocket.hostname end)
  try("Root():Children() count", function() return Root():Count() end)
  try("maNetSocket:Dump()", function() Root().maNetSocket:Dump() return "dumped to history" end)
  try("socket.dns.gethostname", function() return socket.dns.gethostname() end)
  try("socket.dns.toip(hostname)", function()
    local ip, info = socket.dns.toip(socket.dns.gethostname())
    local all = {}
    if info and info.ip then for _, a in ipairs(info.ip) do table.insert(all, a) end end
    return tostring(ip) .. " [" .. table.concat(all, ",") .. "]"
  end)
  try("getaddrinfo(hostname)", function()
    local t = socket.dns.getaddrinfo(socket.dns.gethostname())
    local all = {}
    for _, a in ipairs(t or {}) do table.insert(all, a.family .. ":" .. a.addr) end
    return table.concat(all, " ")
  end)

  P("--- (h) Cmd() returns ---")
  try("Cmd('Echo facts')", function() return Cmd("Echo facts") end)
  try("Cmd('Sequence 999999 Cue 1')", function() return Cmd("Sequence 999999 Cue 1") end)
  try("Cmd('ThisIsNotAKeyword')", function() return Cmd("ThisIsNotAKeyword") end)
  try("Cmd('SelectFixtures 1') then ClearAll", function() local r = Cmd("ClearAll") return r end)

  P("--- (b) object API descriptor (first 60 lines) ---")
  try("GetObjApiDescriptor()", function()
    local d = GetObjApiDescriptor()
    if type(d) == "string" then
      local n = 0
      for line in d:gmatch("[^\n]+") do n = n + 1 if n <= 60 then P("  %s", line) end end
      return n .. " lines"
    end
    return type(d)
  end)
  try("GetApiDescriptor() type", function() return type(GetApiDescriptor()) end)
  try("ObjectList('Fixture 1')[1]:Addr()", function() return ObjectList("Fixture 1")[1]:Addr() end)
  try("handle property count", function() local h = ObjectList("Sequence 1")[1] or DataPool().Sequences return h:PropertyCount() end)
  try("DataPool().Sequences:Count()", function() return DataPool().Sequences:Count() end)
  try("GetSubfixtureCount()", function() return GetSubfixtureCount() end)

  P("--- (e) pool button appearance ---")
  try("plugin handle class", function() return my_handle:Parent():GetClass() end)
  try("Set Appearance via Cmd", function()
    return Cmd(string.format('Set Plugin "%s" Property "Appearance" "Appearance 1"', pluginName))
  end)
  try("plugin:Get('Appearance')", function() return tostring(my_handle:Parent():Get("Appearance")) end)
  try("plugin:Set('Name')", function()
    local p = my_handle:Parent()
    local old = p.name
    p:Set("Name", old)
    return "set name ok (" .. tostring(old) .. ")"
  end)

  P("--- (c) Timer task context ---")
  local timerSeen = {}
  Timer(function()
    local ok, h = pcall(function() return ObjectList("Fixture 1")[1] end)
    local ok2, dp = pcall(function() return DataPool() end)
    timerSeen.result = string.format("ObjectList ok=%s handle=%s; DataPool ok=%s %s", tostring(ok), tostring(ok and h), tostring(ok2), tostring(ok2 and dp))
    Printf("Facts (timer 1): %s", timerSeen.result)
  end, 0, 1)
  for i = 1, 30 do coroutine.yield(0.1) end
  P("timer-1 context: %s", tostring(timerSeen.result))

  P("--- (f) overlay survival: window open 45 s; change views and tap around ---")
  local dialog
  try("overlay create", function()
    local ov = GetFocusDisplay().ScreenOverlay
    dialog = ov:Append("BaseInput")
    dialog.W, dialog.H = 420, 220
    local tb = dialog:Append("TitleBar")
    local tbt = tb:Append("TitleButton")
    tbt.Text = "MA3 MCP Facts"
    tb:Append("CloseButton")
    local t = dialog:Append("UIObject")
    t.Text = "Change views, tap elsewhere. Does this survive?"
    return "ok"
  end)
  local alive = 0
  for i = 1, 90 do
    coroutine.yield(0.5)
    if dialog and IsObjectValid(dialog) then alive = i end
  end
  P("overlay alive for %.1f s of 45 (valid at last check: %s)", alive * 0.5, tostring(dialog and IsObjectValid(dialog)))
  if dialog and IsObjectValid(dialog) then pcall(function() Obj.Delete(GetFocusDisplay().ScreenOverlay, Obj.Index(dialog)) end) end

  -- (c) part 2: a Timer fired after Main would have returned is tested by the second plugin argument
  Timer(function()
    local ok, h = pcall(function() return ObjectList("Fixture 1")[1] end)
    Printf("Facts (timer 2, after Main): ObjectList ok=%s handle=%s", tostring(ok), tostring(ok and h))
    table.insert(lines, "timer-2 after Main: ObjectList ok=" .. tostring(ok) .. " handle=" .. tostring(ok and h))
    save()
  end, 3, 1)
  save()
  P("Main returning; timer 2 fires in 3 s and rewrites the file")
end

return Main
