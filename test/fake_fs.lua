-- In-memory file system for settings tests.
local M = {}
function M.new()
  local files = {}
  return {
    files = files,
    read = function(path) return files[path] end,
    write = function(path, data) if files.readonly then return nil, "read-only" end files[path] = data return true end,
  }
end
return M
