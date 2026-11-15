-- MCP JSON-RPC dispatcher over plain HTTP responses. Tools only.
-- Speaks the 2026-07-28 stateless flow (server/discover + per-request _meta and
-- Mcp-Method/Mcp-Name headers) and the older initialize flow (2025-11-25 and earlier).
local json = require("json")
local http = require("http")

local M = {}
M.__index = M

M.SUPPORTED = { "2026-07-28", "2025-11-25", "2025-06-18", "2025-03-26" }
local SUPPORTED_SET = {}
for _, v in ipairs(M.SUPPORTED) do SUPPORTED_SET[v] = true end

local META_VERSION = "io.modelcontextprotocol/protocolVersion"
local META_CLIENT = "io.modelcontextprotocol/clientInfo"
local META_CAPS = "io.modelcontextprotocol/clientCapabilities"
local META_SERVER = "io.modelcontextprotocol/serverInfo"

function M.new(opts)
  local self = setmetatable({}, M)
  self.server_name = opts.server_name or "MA3 MCP"
  self.server_version = opts.server_version or "0.0.0"
  self.tools = opts.tools or {}
  self.instructions = opts.instructions
  return self
end

function M:server_info()
  return { name = self.server_name, version = self.server_version }
end

local JSON_HEADERS = { ["Content-Type"] = "application/json" }

local function reply(status, obj)
  return status, JSON_HEADERS, json.encode(obj)
end

local function rpc_error(status, id, code, message, data)
  local e = { code = code, message = message }
  if data ~= nil then e.data = data end
  return reply(status, { jsonrpc = "2.0", id = id, error = e })
end

-- rxi json (the console's encoder) writes an empty table as [], so every object MCP
-- requires is kept non-empty or encoded by hand.
local CAPABILITIES = { tools = { listChanged = false } }

local function encode_result(res)
  if type(res) == "table" and next(res) == nil then return "{}" end
  return json.encode(res)
end

function M:tool_list()
  local names = {}
  for name in pairs(self.tools) do names[#names + 1] = name end
  table.sort(names)
  local out = {}
  for _, name in ipairs(names) do
    local t = self.tools[name]
    local schema = t.inputSchema or { type = "object" }
    if type(schema.properties) == "table" and next(schema.properties) == nil then
      local copy = {}
      for k, v in pairs(schema) do if k ~= "properties" then copy[k] = v end end
      schema = copy
    end
    out[#out + 1] = { name = name, description = t.description or "", inputSchema = schema }
  end
  return out
end

M.HANDLER_LIMIT_S = 15
M.HOOK_GAP_S = 0.05
M.SLOW_S = 0.1

function M:call_tool(params, ctx)
  local name = params and params.name
  local tool = name and self.tools[name]
  if not tool then return nil, "unknown tool: " .. tostring(name) end
  local args = params.arguments or {}
  local g = ctx and ctx.guard
  local ok, res, err
  if g then
    -- Console guard: rate cap and quarantine answer before the console is touched; the journal
    -- records the call before it runs; a handler stuck in Lua code is stopped after
    -- HANDLER_LIMIT_S (a hung console call cannot be stopped, see src/guard.lua).
    local admitted, why = g:admit()
    if admitted then admitted, why = g:admit_call(name, args) end
    if not admitted then
      ok, res, err = true, nil, why
    else
      g:begin(name, args)
      -- Counts only time spent running Lua without a pause: the hook fires every 10,000 Lua
      -- instructions, so gaps longer than HOOK_GAP_S are yields or console calls (a save, an
      -- export) and are not counted. A Lua loop that never yields adds up and is stopped.
      local last, spent = g.now(), 0
      debug.sethook(function()
        local now = g.now()
        local gap = now - last
        last = now
        if gap < M.HOOK_GAP_S then spent = spent + gap end
        if spent > M.HANDLER_LIMIT_S then
          debug.sethook()
          error(string.format("[console-guard] %s stopped: more than %d s running Lua without a pause", name, M.HANDLER_LIMIT_S), 0)
        end
      end, "", 10000)
      ok, res, err = pcall(tool.handler, args, ctx)
      debug.sethook()
      local dt = g:finish()
      if dt > M.SLOW_S and ctx.log then
        ctx.log:add("slow: %s %s %d ms", name, type(args.address) == "string" and args.address or "", math.floor(dt * 1000 + 0.5))
      end
    end
  else
    ok, res, err = pcall(tool.handler, args, ctx)
  end
  local text, is_error
  if not ok then
    text, is_error = "tool error: " .. tostring(res), true
  elseif res == nil then
    text, is_error = tostring(err or "tool returned nothing"), true
  else
    text, is_error = encode_result(res), false
  end
  return {
    resultType = "complete",
    content = { { type = "text", text = text } },
    isError = is_error,
    _meta = { [META_SERVER] = self:server_info() },
  }
end

-- Returns status, headers, body.
function M:handle(req, ctx)
  if req.method ~= "POST" then
    return 405, { Allow = "POST", ["Content-Type"] = "text/plain" }, ""
  end
  local ok, msg = pcall(json.decode, req.body or "")
  if not ok or type(msg) ~= "table" then
    return rpc_error(400, nil, -32700, "parse error")
  end
  local id, method, params = msg.id, msg.method, msg.params
  local version = http.header(req, "mcp-protocol-version")
  if version and not SUPPORTED_SET[version] then
    return rpc_error(400, id, -32022, "unsupported protocol version", { supported = M.SUPPORTED, requested = version })
  end

  -- Notifications: no id, no response body.
  if id == nil then
    if type(method) == "string" and method:find("^notifications/") then
      return 202, {}, ""
    end
    return rpc_error(400, nil, -32600, "request without id")
  end

  local modern = version == "2026-07-28"
  if modern then
    local meta = params and params._meta
    if type(meta) ~= "table" or meta[META_VERSION] ~= "2026-07-28" or type(meta[META_CAPS]) ~= "table" then
      return rpc_error(400, id, -32602, "missing or invalid _meta (protocolVersion, clientCapabilities)")
    end
    local hm = http.header(req, "mcp-method")
    if hm ~= nil and hm ~= method then
      return rpc_error(400, id, -32020, "Mcp-Method header does not match body method")
    end
    if hm == nil then
      return rpc_error(400, id, -32020, "Mcp-Method header required")
    end
    if method == "tools/call" then
      local hn = http.header(req, "mcp-name")
      if hn ~= nil and hn ~= (params and params.name) then
        return rpc_error(400, id, -32020, "Mcp-Name header does not match params.name")
      end
    end
  end

  local result
  if method == "server/discover" then
    result = {
      resultType = "complete",
      supportedVersions = { "2026-07-28" },
      capabilities = CAPABILITIES,
      instructions = self.instructions,
      ttlMs = 60000,
      cacheScope = "private",
      _meta = { [META_SERVER] = self:server_info() },
    }
  elseif method == "initialize" then
    local requested = params and params.protocolVersion
    result = {
      protocolVersion = SUPPORTED_SET[requested] and requested or "2025-11-25",
      capabilities = CAPABILITIES,
      serverInfo = self:server_info(),
      instructions = self.instructions,
    }
  elseif method == "ping" then
    result = { pong = true }
  elseif method == "tools/list" then
    result = { tools = self:tool_list(), ttlMs = 60000, cacheScope = "private" }
    if modern then result.resultType = "complete"; result._meta = { [META_SERVER] = self:server_info() } end
  elseif method == "tools/call" then
    local r, err = self:call_tool(params, ctx)
    if not r then return rpc_error(200, id, -32602, err) end
    result = r
  else
    return rpc_error(404, id, -32601, "method not found: " .. tostring(method))
  end
  return reply(200, { jsonrpc = "2.0", id = id, result = result })
end

-- Client name from the request body, for the client registry.
function M.client_name(req)
  local ok, msg = pcall(json.decode, req.body or "")
  if not ok or type(msg) ~= "table" then return nil end
  local p = msg.params or {}
  local ci = p.clientInfo or (p._meta and p._meta[META_CLIENT])
  return ci and ci.name or nil
end

return M
