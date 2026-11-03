-- Requests captured from Claude Code 2.1.295 on 2026-11-03 against a stub HTTP MCP server.
-- Authorization headers omitted. Builders return http request tables (as http.parse produces).
local json = require("json")
local F = {}

local function req(method, path, headers, body)
  local h = { host = "127.0.0.1:9800", ["user-agent"] = "claude-code/2.1.295 (claude-vscode, agent-sdk/0.3.296)",
    accept = "application/json, text/event-stream", ["accept-encoding"] = "identity", connection = "keep-alive" }
  for k, v in pairs(headers or {}) do h[k] = v end
  if body ~= nil then
    if type(body) == "table" then body = json.encode(body) end
    h["content-type"] = "application/json"
    h["content-length"] = tostring(#body)
  end
  return { method = method, path = path, version = "1.1", headers = h, body = body or "" }
end
F.req = req

local META_2026 = {
  ["io.modelcontextprotocol/protocolVersion"] = "2026-07-28",
  ["io.modelcontextprotocol/clientInfo"] = { name = "claude-code", title = "Claude Code", version = "2.1.295" },
  ["io.modelcontextprotocol/clientCapabilities"] = { roots = { listChanged = true }, elicitation = { form = {}, url = {} } },
}

F.discover = req("POST", "/mcp", { ["mcp-method"] = "server/discover", ["mcp-protocol-version"] = "2026-07-28" },
  { jsonrpc = "2.0", id = "server-discover-probe-1", method = "server/discover", params = { _meta = META_2026 } })

F.initialize = req("POST", "/mcp", {},
  { method = "initialize", params = { protocolVersion = "2025-11-25",
    capabilities = { roots = { listChanged = true }, elicitation = { form = {}, url = {} } },
    clientInfo = { name = "claude-code", title = "Claude Code", version = "2.1.295" } }, jsonrpc = "2.0", id = 0 })

F.initialized = req("POST", "/mcp", { ["mcp-protocol-version"] = "2025-11-25" },
  { jsonrpc = "2.0", method = "notifications/initialized" })

F.get_stream = req("GET", "/mcp", { accept = "text/event-stream", ["mcp-protocol-version"] = "2025-11-25" })

F.tools_list = req("POST", "/mcp", { ["mcp-protocol-version"] = "2025-11-25" },
  { method = "tools/list", jsonrpc = "2.0", id = 1 })

function F.tools_call(name, args)
  return req("POST", "/mcp", { ["mcp-protocol-version"] = "2025-11-25" },
    { method = "tools/call", params = { name = name, arguments = args,
      _meta = { ["claudecode/toolUseId"] = "toolu_01", progressToken = 2 } }, jsonrpc = "2.0", id = 2 })
end

function F.call_2026(name, args, override_header_name)
  return req("POST", "/mcp", { ["mcp-method"] = "tools/call", ["mcp-name"] = override_header_name or name,
    ["mcp-protocol-version"] = "2026-07-28" },
    { jsonrpc = "2.0", id = 7, method = "tools/call", params = { name = name, arguments = args, _meta = META_2026 } })
end

function F.call_2026_mismatched_name() return F.call_2026("ma3_echo", {}, "other_tool") end

function F.call_2026_missing_meta(name)
  return req("POST", "/mcp", { ["mcp-method"] = "tools/call", ["mcp-name"] = name, ["mcp-protocol-version"] = "2026-07-28" },
    { jsonrpc = "2.0", id = 8, method = "tools/call", params = { name = name, arguments = {} } })
end

function F.unknown_method()
  return req("POST", "/mcp", { ["mcp-protocol-version"] = "2025-11-25" }, { jsonrpc = "2.0", id = 9, method = "resources/list" })
end

function F.bad_version(v)
  return req("POST", "/mcp", { ["mcp-protocol-version"] = v }, { jsonrpc = "2.0", id = 10, method = "tools/list" })
end

function F.ping() return req("POST", "/mcp", { ["mcp-protocol-version"] = "2025-11-25" }, { jsonrpc = "2.0", id = 11, method = "ping" }) end

function F.not_json() return req("POST", "/mcp", { ["mcp-protocol-version"] = "2025-11-25" }, "{nope") end

return F
