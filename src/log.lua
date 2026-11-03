-- Fixed-size ring buffer of formatted log lines (newest last).
local M = {}
M.__index = M

function M.new(cap, sink)
  return setmetatable({ cap = cap or 200, items = {}, sink = sink }, M)
end

function M:add(fmt, ...)
  local line = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
  self.items[#self.items + 1] = line
  while #self.items > self.cap do table.remove(self.items, 1) end
  if self.sink then pcall(self.sink, line) end
  return line
end

function M:lines()
  local out = {}
  for i, l in ipairs(self.items) do out[i] = l end
  return out
end

return M
