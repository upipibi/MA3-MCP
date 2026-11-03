-- Minimal assertion helpers for the plain-Lua test runner.
local M = { passed = 0, failed = 0, failures = {} }
local current = "?"

local function fail(msg)
  M.failed = M.failed + 1
  local info = debug.getinfo(3, "Sl")
  table.insert(M.failures, string.format("%s (%s:%d): %s", current, info.short_src, info.currentline, msg))
end

local function show(v)
  if type(v) == "string" then return string.format("%q", v) end
  return tostring(v)
end

function M.describe(name, fn)
  current = name
  local ok, err = pcall(fn)
  if not ok then
    M.failed = M.failed + 1
    table.insert(M.failures, string.format("%s: error: %s", name, tostring(err)))
  end
  current = "?"
end

function M.eq(a, b, msg)
  if a == b then M.passed = M.passed + 1 else fail((msg or "eq") .. ": expected " .. show(b) .. ", got " .. show(a)) end
end

function M.truthy(v, msg)
  if v then M.passed = M.passed + 1 else fail((msg or "truthy") .. ": got " .. show(v)) end
end

function M.errors(fn, pattern, msg)
  local ok, err = pcall(fn)
  if ok then fail((msg or "errors") .. ": no error raised") return end
  if pattern and not tostring(err):find(pattern) then fail((msg or "errors") .. ": " .. show(err) .. " does not match " .. show(pattern)) return end
  M.passed = M.passed + 1
end

return M
