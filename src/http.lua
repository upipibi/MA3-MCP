-- Minimal HTTP/1.1 request parser and response builder.
-- Pure Lua, no sockets: the server module feeds it a byte buffer.
local M = {}

M.MAX_HEADER = 16 * 1024
M.MAX_BODY = 1024 * 1024

M.STATUS_TEXT = {
  [200] = "OK", [202] = "Accepted", [204] = "No Content",
  [400] = "Bad Request", [401] = "Unauthorized", [403] = "Forbidden", [404] = "Not Found",
  [405] = "Method Not Allowed", [413] = "Payload Too Large", [429] = "Too Many Requests",
  [500] = "Internal Server Error",
}

-- Parses one request from the front of buf.
-- Returns req, "ok", consumed  |  nil, "need_more", 0  |  nil, "bad"|"too_large", 0
function M.parse(buf)
  local head_end = buf:find("\r\n\r\n", 1, true)
  if not head_end then
    if #buf > M.MAX_HEADER then return nil, "too_large", 0 end
    return nil, "need_more", 0
  end
  if head_end > M.MAX_HEADER then return nil, "too_large", 0 end
  local head = buf:sub(1, head_end - 1)
  local body_start = head_end + 4

  local first_end = head:find("\r\n", 1, true) or (#head + 1)
  local line = head:sub(1, first_end - 1)
  local method, target, version = line:match("^(%u+) (%S+) HTTP/(%d%.%d)$")
  if not method then return nil, "bad", 0 end

  local req = { method = method, version = version, headers = {} }
  local q = target:find("?", 1, true)
  if q then
    req.path, req.query = target:sub(1, q - 1), target:sub(q + 1)
  else
    req.path, req.query = target, nil
  end

  local rest = head:sub(first_end + 2)
  for hl in rest:gmatch("[^\r\n]+") do
    local name, value = hl:match("^([^:%s]+)%s*:%s*(.-)%s*$")
    if not name then return nil, "bad", 0 end
    req.headers[name:lower()] = value
  end

  if req.headers["transfer-encoding"] then return nil, "bad", 0 end
  local len = 0
  if req.headers["content-length"] then
    len = tonumber(req.headers["content-length"])
    if not len or len < 0 or len ~= math.floor(len) then return nil, "bad", 0 end
  end
  if len > M.MAX_BODY then return nil, "too_large", 0 end
  if #buf - body_start + 1 < len then return nil, "need_more", 0 end
  req.body = buf:sub(body_start, body_start + len - 1)
  return req, "ok", body_start + len - 1
end

function M.header(req, name)
  return req.headers[name:lower()]
end

function M.response(status, headers, body)
  body = body or ""
  local lines = { string.format("HTTP/1.1 %d %s", status, M.STATUS_TEXT[status] or "Unknown") }
  lines[#lines + 1] = "Date: " .. os.date("!%a, %d %b %Y %H:%M:%S GMT")
  lines[#lines + 1] = "Connection: close"
  lines[#lines + 1] = "Content-Length: " .. #body
  for k, v in pairs(headers or {}) do lines[#lines + 1] = k .. ": " .. tostring(v) end
  return table.concat(lines, "\r\n") .. "\r\n\r\n" .. body
end

return M
