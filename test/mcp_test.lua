local mcp = require("mcp")
local json = require("json")
local F = require("fixtures.claude_code_flows")
local h = require("helpers")

local echo = { description = "echo", inputSchema = { type = "object", properties = { text = { type = "string" } } },
  handler = function(a) return { echoed = a.text } end }
local zeta = { description = "z", inputSchema = { type = "object", properties = {} }, handler = function() return {} end }
local d = mcp.new({ server_name = "MA3 MCP", server_version = "0.1.0", tools = { zeta_tool = zeta, ma3_echo = echo }, instructions = "hi" })

local function body_of(st, hd, bd) return st, hd, json.decode(bd) end

h.describe("mcp_legacy_flow_end_to_end", function()
  local st, hd, r = body_of(d:handle(F.initialize))
  h.eq(st, 200); h.eq(hd["Content-Type"], "application/json")
  h.eq(r.id, 0); h.eq(r.result.protocolVersion, "2025-11-25"); h.truthy(r.result.capabilities.tools)
  h.eq(r.result.serverInfo.name, "MA3 MCP"); h.eq(r.result.instructions, "hi")
  local st2, _, bd2 = d:handle(F.initialized); h.eq(st2, 202); h.eq(bd2, "")
  local st3, hd3 = d:handle(F.get_stream); h.eq(st3, 405); h.eq(hd3.Allow, "POST")
  local st4, _, r4 = body_of(d:handle(F.tools_list)); h.eq(st4, 200)
  h.eq(#r4.result.tools, 2); h.eq(r4.result.tools[1].name, "ma3_echo", "alphabetical"); h.eq(r4.result.tools[1].inputSchema.type, "object")
  local st5, _, r5 = body_of(d:handle(F.tools_call("ma3_echo", { text = "hi" })))
  h.eq(st5, 200); h.eq(r5.id, 2); h.eq(r5.result.isError, false); h.eq(r5.result.content[1].type, "text")
  h.eq(json.decode(r5.result.content[1].text).echoed, "hi")
  local st6, _, r6 = body_of(d:handle(F.ping())); h.eq(st6, 200); h.truthy(r6.result)
end)

h.describe("mcp_discover_flow_end_to_end", function()
  local st, _, r = body_of(d:handle(F.discover))
  h.eq(st, 200); h.eq(r.id, "server-discover-probe-1")
  h.eq(r.result.resultType, "complete"); h.eq(r.result.supportedVersions[1], "2026-07-28"); h.truthy(r.result.capabilities.tools)
  h.eq(r.result._meta["io.modelcontextprotocol/serverInfo"].name, "MA3 MCP"); h.eq(r.result.instructions, "hi")
  local st2, _, r2 = body_of(d:handle(F.call_2026("ma3_echo", { text = "yo" })))
  h.eq(st2, 200); h.eq(r2.result.resultType, "complete"); h.eq(json.decode(r2.result.content[1].text).echoed, "yo")
  h.eq(r2.result._meta["io.modelcontextprotocol/serverInfo"].version, "0.1.0")
end)

h.describe("mcp errors", function()
  local st, _, r = body_of(d:handle(F.call_2026_mismatched_name())); h.eq(st, 400); h.eq(r.error.code, -32020)
  st, _, r = body_of(d:handle(F.call_2026_missing_meta("ma3_echo"))); h.eq(st, 400); h.eq(r.error.code, -32602)
  st, _, r = body_of(d:handle(F.unknown_method())); h.eq(st, 404); h.eq(r.error.code, -32601)
  st, _, r = body_of(d:handle(F.tools_call("nope", {}))); h.eq(st, 200); h.eq(r.error.code, -32602)
  st, _, r = body_of(d:handle(F.bad_version("2024-01-01"))); h.eq(st, 400); h.eq(r.error.code, -32022); h.eq(r.error.data.supported[1], "2026-07-28")
  st, _, r = body_of(d:handle(F.not_json())); h.eq(st, 400); h.eq(r.error.code, -32700)
  local hr = echo.handler
  echo.handler = function() return nil, "boom" end
  st, _, r = body_of(d:handle(F.tools_call("ma3_echo", {}))); h.eq(st, 200); h.eq(r.result.isError, true); h.eq(r.result.content[1].text, "boom")
  echo.handler = function() error("crash") end
  st, _, r = body_of(d:handle(F.tools_call("ma3_echo", {}))); h.eq(r.result.isError, true); h.truthy(r.result.content[1].text:find("crash"))
  echo.handler = hr
end)
