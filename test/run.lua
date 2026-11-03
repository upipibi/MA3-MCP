-- Runs every test/*_test.lua and exits 1 on any failure.
local h = require("helpers")
local files = {}
local p = io.popen("ls test/*_test.lua")
for line in p:lines() do table.insert(files, line) end
p:close()
table.sort(files)
for _, f in ipairs(files) do
  local ok, err = pcall(dofile, f)
  if not ok then
    h.failed = h.failed + 1
    table.insert(h.failures, f .. ": load error: " .. tostring(err))
  end
end
for _, m in ipairs(h.failures) do io.stderr:write("FAIL " .. m .. "\n") end
print(string.format("PASS %d / FAIL %d (%d files)", h.passed, h.failed, #files))
os.exit(h.failed == 0 and 0 or 1)
