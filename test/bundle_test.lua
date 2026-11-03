local h = require("helpers")
local fake_socket = require("fake_socket")
local fake_console = require("fake_console")

h.describe("bundle builds and returns Main and cleanup", function()
  os.execute("mkdir -p test/out")
  local ok = os.execute(string.format("%s tools/bundle.lua test/out/bundle.lua >/dev/null", arg and arg[-1] or "lua"))
  h.truthy(ok, "bundle script ran")
  local f = io.open("test/out/bundle.lua"); local code = f:read("a"); f:close()
  h.truthy(#code > 20000, "bundle has content")
  h.truthy(not code:find("string%.split"), "no MA string extensions")
  h.truthy(not code:find("package%.preload"), "bundle never touches the shared package table")
  -- Load it the way the console does: a chunk receiving the plugin args, with console globals.
  local fc = fake_console.new()
  local env = setmetatable({}, { __index = _G })
  for k, v in pairs(fc.api) do env[k] = v end
  env.Timer = function() end
  env.require = function(name)
    if name == "socket" then return fake_socket.new() end
    if name == "json" then return require("json") end
    error("bundle asked the host for module " .. name)
  end
  local chunk, err = load(code, "=bundle", "t", env)
  h.truthy(chunk, tostring(err))
  local my_handle = { Parent = function() return { Set = function() end, Get = function() end } end }
  local Main, cleanup = chunk("MA3 MCP", "ma3_mcp", {}, my_handle)
  h.eq(type(Main), "function"); h.eq(type(cleanup), "function")
end)

h.describe("bundle load guard reports a broken module instead of failing silently", function()
  local f = io.open("test/out/bundle.lua"); local code = f:read("a"); f:close()
  local written, errs = {}, {}
  local env = setmetatable({}, { __index = _G })
  env.require = function(name) return require(name) end
  code = code:gsub('(__sources%["main"%] = %[=*%[\n)', '%1error("boom in main")\n', 1)
  env.GetPath = function() return "/tmp/x" end
  env.Enums = { PathType = { Temp = 1 } }
  env.ErrPrintf = function(s) errs[#errs + 1] = s end
  env.io = { open = function(path) written[#written + 1] = path return { write = function(_, ...) written[#written + 1] = table.concat({ ... }) end, close = function() end } end }
  local chunk = load(code, "=bundle", "t", env)
  local Main = chunk("MA3 MCP", "ma3_mcp", {}, {})
  h.eq(type(Main), "function")
  h.truthy(errs[1] and errs[1]:find("boom in main"), tostring(errs[1]))
  h.truthy(table.concat(written, "|"):find("/tmp/x/ma3_mcp_load_error.txt", 1, true), "error file written")
  h.truthy(table.concat(written, "|"):find("FAILED: ", 1, true), "load marker records the failure")
  Main()
  h.eq(#errs, 2, "the stand-in Main repeats the error")
end)
