-- Gated arbitrary Lua: off unless the window toggle is on. Runs on the calling thread
-- (a child coroutine would have no console context) with a sandboxed environment and a
-- wall-clock deadline enforced by a count hook.
local console = require("console")

local M = {}

M.BLOCKED_OS = { "exit", "execute", "remove", "rename", "tmpname" }

-- Names a chunk must never reach: the file system, module loading, and the debug library
-- (which could remove the deadline hook).
M.BLOCKED_GLOBALS = { io = true, require = true, package = true, loadfile = true, dofile = true, debug = true, lfs = true, loadstring = true }

local function build_env(globals, output)
  local env = {}
  env.os = {}
  for k, v in pairs(globals.os or os) do env.os[k] = v end
  for _, k in ipairs(M.BLOCKED_OS) do env.os[k] = nil end
  env.Echo = function(s) output[#output + 1] = tostring(s) end
  env.Printf = function(fmt, ...)
    local ok, s = pcall(string.format, tostring(fmt), ...)
    output[#output + 1] = ok and s or tostring(fmt)
  end
  env.print = env.Echo
  env._G = env
  -- load() inside the chunk compiles into the same sandbox, never the real globals.
  env.load = function(chunk, name, _, custom_env) return load(chunk, name or "=mcp-inner", "t", custom_env or env) end
  -- Lookups: the injected globals first (the console API), then the standard library; never a blocked name.
  return setmetatable(env, { __index = function(_, k)
    if M.BLOCKED_GLOBALS[k] then return nil end
    local v = globals[k]
    if v == nil then v = _G[k] end
    return v
  end })
end

-- Renders a returned value for JSON: handles become addresses, tables recurse (depth-limited).
local function render(v, depth)
  depth = depth or 0
  local t = type(v)
  if t == "table" then
    if type(v.ToAddr) == "function" then return console.render(v) end  -- a handle (the test fake uses tables)
    if depth > 6 then return "..." end
    local out = {}
    for k, x in pairs(v) do out[tostring(k) == tostring(tonumber(k)) and tonumber(k) or tostring(k)] = render(x, depth + 1) end
    return out
  end
  if t == "userdata" then return console.render(v) end
  if t == "function" or t == "thread" then return tostring(v) end
  return v
end

function M.register(tools, c, ctx, globals)
  globals = globals or _G
  tools.ma3_lua = {
    description = "Run a Lua chunk inside the console with the full grandMA3 API (ObjectList, Cmd, DataPool, ...). Refused unless 'Allow Lua execution' is on in the MA3 MCP window. Returns {returned, output}; Echo/Printf output is captured. The chunk cannot use io, require, package, loadfile, dofile, debug, lfs, or os.exit/execute/remove/rename. timeout_ms (default 5000) is a wall-clock deadline; a timeout proves nothing about side effects already done. Changes the live show if the code does.",
    inputSchema = { type = "object", required = { "code" }, properties = { code = { type = "string" }, timeout_ms = { type = "integer" } } },
    handler = function(args)
      if not ctx.lua_enabled() then return nil, "Lua execution is off; turn it on in the MA3 MCP window (or Plugin \"MA3 MCP\" \"lua on\")" end
      local code = args and args.code
      if type(code) ~= "string" or code == "" then return nil, "code is required" end
      local output = {}
      local env = build_env(globals, output)
      local fn, err = load(code, "=mcp", "t", env)
      if not fn then return nil, "syntax error: " .. tostring(err) end
      local deadline = c:now() + (tonumber(args.timeout_ms) or 5000) / 1000
      local hook = function()
        if c:now() > deadline then error("deadline: the chunk exceeded its time budget", 2) end
      end
      debug.sethook(hook, "", 10000)
      local results = table.pack(pcall(fn))
      debug.sethook()
      if not results[1] then return nil, "runtime error: " .. tostring(results[2]) end
      local returned
      if results.n > 2 then
        returned = {}
        for i = 2, results.n do returned[i - 1] = render(results[i]) end
        returned = returned[1]
      elseif results.n == 2 then
        returned = render(results[2])
      end
      return { returned = returned, output = output }
    end,
  }
end

return M
