-- Object address validation for the generic tools.
-- The one hard rule (spec §9): never hand a Page/Executor range or wildcard to ObjectList.
local M = {}

M.UNSAFE = "[unsafe-range]"

-- Removes quoted names so keywords inside them do not count.
local function strip_quotes(s)
  return (s:gsub('"[^"]*"', '""'))
end

M.UNSAFE_ADDRESS = "[unsafe-address]"

-- Keywords an address must never contain outside a quoted name: resolving them does not return.
-- geometry: the geometry collection of a fixture type reports "Geometry " as its address;
-- ObjectList on it froze the console's screen on 2026-11-08 (mid-service) and onPC on 2026-11-21,
-- both at call 706 of the same census. Reach those objects by path ("FixtureType 1.5").
M.HANG_KEYWORDS = { geometry = true }

-- Keywords an address may start with on a console: each was resolved as a bare pool address by
-- the onPC census of 2026-11-21 (58 of them) or is used by the tools every day (the last line).
M.PROVEN_KEYWORDS = {}
for w in ([[activationgroup addon agenda appearance attribute batterystatus camera certificate color
  colordefinition configuration dmxuniverse datapool display encoderbar featuregroup filter
  fixtureclass fixturelayer fixturetype gel group image keyboard layout matricks macro master
  material menu mesh ndi osc page plugin preset quickey rdm remote renderquality root
  screenconfiguration scribble sequence shape sound stage tag timecode timecodeslot timer user
  userprofile video view world _execkeystatus _hardwarestatus
  fixture cue part executor exec channel universe patch showdata]]):gmatch("%S+") do M.PROVEN_KEYWORDS[w] = true end

-- The first word of an address, lower case; nil when it starts with a quoted name or a number.
function M.first_keyword(text)
  if type(text) ~= "string" then return nil end
  local w = text:match("^%s*([%a_][%w_]*)")
  return w and w:lower() or nil
end

function M.proven(text)
  local w = M.first_keyword(text)
  return w ~= nil and M.PROVEN_KEYWORDS[w] == true
end

function M.check(text)
  if type(text) ~= "string" then return false, "address must be a string" end
  if text:match("^%s*$") then return false, "address is empty" end
  if text:find("[%c]") then return false, "address contains control characters" end
  local bare = strip_quotes(text):lower()
  -- anywhere in the address, and in any shortened form the console might accept (three letters up)
  for word in bare:gmatch("%f[%a_]([%a_][%w_]*)") do
    for kw in pairs(M.HANG_KEYWORDS) do
      if #word >= 3 and kw:sub(1, #word) == word then
        return false, M.UNSAFE_ADDRESS .. " an address naming '" .. kw .. "' never resolves (it froze the console on 2026-11-08); use the object's path below its parent"
      end
    end
  end
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
