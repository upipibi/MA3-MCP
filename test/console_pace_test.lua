-- console.pace: yields are spent by elapsed time, never by count (see src/console.lua).
local console = require("console")
local h = require("helpers")

local function setup()
  local t = { clock = 100, yields = 0, yield_cost = 0 }
  local c = console.new({
    yield = function() t.yields = t.yields + 1; t.clock = t.clock + t.yield_cost end,
    now = function() return t.clock end,
  })
  return c, t
end

h.describe("pace does not yield while no time passes", function()
  local c, t = setup()
  c:start_slice()
  for _ = 1, 100000 do c:pace() end
  h.eq(t.yields, 0)
end)

h.describe("pace yields once the slice is used up, then starts a new slice", function()
  local c, t = setup()
  c:start_slice()
  t.clock = t.clock + console.SLICE_SECONDS * 0.9
  h.eq(c:pace(), false, "inside the slice")
  t.clock = t.clock + console.SLICE_SECONDS * 0.2
  h.eq(c:pace(), true, "past the slice"); h.eq(t.yields, 1)
  h.eq(c:pace(), false, "a fresh slice"); h.eq(t.yields, 1)
end)

h.describe("the time a yield takes is not charged to the next slice", function()
  local c, t = setup()
  t.yield_cost = 0.031            -- a console frame
  c:start_slice()
  t.clock = t.clock + console.SLICE_SECONDS * 1.5
  h.eq(c:pace(), true)
  h.eq(c:pace(), false, "the 31 ms spent yielding did not count as work"); h.eq(t.yields, 1)
end)

h.describe("pace without start_slice starts one instead of yielding", function()
  local c, t = setup()
  h.eq(c:pace(), false); h.eq(t.yields, 0)
  t.clock = t.clock + console.SLICE_SECONDS * 1.5
  h.eq(c:pace(), true)
end)

h.describe("start_slice forgets work done before it", function()
  local c, t = setup()
  c:start_slice()
  t.clock = t.clock + 5           -- a previous request, long ago
  c:start_slice()
  h.eq(c:pace(), false); h.eq(t.yields, 0)
end)

h.describe("a clock that steps backwards restarts the slice", function()
  local c, t = setup()
  c:start_slice()
  t.clock = t.clock - 50
  h.eq(c:pace(), false)
  t.clock = t.clock + console.SLICE_SECONDS * 1.5
  h.eq(c:pace(), true)
end)
