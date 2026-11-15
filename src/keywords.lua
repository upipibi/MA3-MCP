-- Matching command words against grandMA3 keywords the way the console reads them.
-- The console accepts shortcuts (Lu = Lua, S = Store, R = Reboot), so a word matches a keyword
-- rule when it is the keyword, one of its documented aliases, or a prefix of the keyword at least
-- as long as `min` (MA's documented shortcut, or the shortest prefix no other keyword shares).
-- Rules are { keyword, min, aliases | nil, reason }. Keywords from the MA 2.5 help.
local M = {}

-- Returns the matched keyword and its reason, else nil. `word` is compared in lower case;
-- `allowed` lists full keywords that are prefixes of a rule's keyword but mean something else.
function M.match(word, rules, allowed)
  word = tostring(word or ""):lower()
  if word == "" or (allowed and allowed[word]) then return nil end
  for _, r in ipairs(rules) do
    local kw, min, aliases = r[1], r[2], r[3]
    if word == kw then return kw, r[4] end
    if #word >= #min and kw:sub(1, #word) == word then return kw, r[4] end
    if aliases then for _, a in ipairs(aliases) do if word == a then return kw, r[4] end end end
  end
  return nil
end

-- The command with every single- or double-quoted part replaced by an empty pair of quotes.
function M.unquote(cmd)
  local out, quote = {}, nil
  for ch in tostring(cmd):gmatch(".") do
    if quote then
      if ch == quote then quote = nil; out[#out + 1] = ch end
    elseif ch == '"' or ch == "'" then
      quote = ch; out[#out + 1] = ch
    else
      out[#out + 1] = ch
    end
  end
  return table.concat(out)
end

-- The words of a command outside quotes (a letter, then letters or digits).
function M.words(cmd)
  local list = {}
  for w in M.unquote(cmd):gmatch("%f[%w]([%a][%w]*)") do list[#list + 1] = w end
  return list
end

return M
