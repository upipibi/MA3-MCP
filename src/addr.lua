-- Object address validation for the generic tools.
-- The one hard rule (spec §9): never hand a Page/Executor range or wildcard to ObjectList.
local M = {}

M.UNSAFE = "[unsafe-range]"

-- Removes quoted names so keywords inside them do not count.
local function strip_quotes(s)
  return (s:gsub('"[^"]*"', '""'))
end

function M.check(text)
  if type(text) ~= "string" then return false, "address must be a string" end
  if text:match("^%s*$") then return false, "address is empty" end
  if text:find("[%c]") then return false, "address contains control characters" end
  local bare = strip_quotes(text):lower()
  local on_page = bare:find("%f[%w]page%f[%W]") or bare:find("%f[%w]executor%f[%W]") or bare:find("%f[%w]exec%f[%W]")
  if on_page then
    if bare:find("%f[%w]thru%f[%W]") or bare:find("+", 1, true) or bare:find("*", 1, true) then
      return false, M.UNSAFE
    end
  end
  return true
end

function M.quote(name)
  return '"' .. tostring(name):gsub('"', "") .. '"'
end

return M
