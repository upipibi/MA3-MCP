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
  -- Load it the way the console does: a chunk receiving the plugin args, with console globals.
  local fc = fake_console.new()
  local env = setmetatable({}, { __index = _G })
  for k, v in pairs(fc.api) do env[k] = v end
  env.Timer = function() end
  env.package = { preload = {}, loaded = {} }
  env.require = function(name)
    if name == "socket" then return fake_socket.new() end
    if name == "json" then return require("json") end
    if env.package.loaded[name] then return env.package.loaded[name] end
    local loader = env.package.preload[name]
    if not loader then error("bundle is missing module " .. name) end
    local m = loader(name)
    env.package.loaded[name] = m
    return m
  end
  local chunk, err = load(code, "=bundle", "t", env)
  h.truthy(chunk, tostring(err))
  local my_handle = { Parent = function() return { Set = function() end, Get = function() end } end }
  local Main, cleanup = chunk("MA3 MCP", "ma3_mcp", {}, my_handle)
  h.eq(type(Main), "function"); h.eq(type(cleanup), "function")
end)
