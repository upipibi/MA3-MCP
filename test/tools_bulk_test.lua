local console = require("console")
local bulk = require("tools.bulk")
local fake_console = require("fake_console")
local h = require("helpers")

local function setup()
  local fake = fake_console.new()
  local c = console.new(fake.api)
  local tools = {}
  local ctx = { budget_ms = 10000, lua_enabled = function() return false end }
  bulk.register(tools, c, ctx)
  return fake, tools, ctx
end

local function find(rows, key, value)
  for _, r in ipairs(rows) do if r[key] == value then return r end end
end

h.describe("ma3_fixtures lists instances", function()
  local fake, tools, ctx = setup()
  local r = tools.ma3_fixtures.handler({}, ctx)
  h.eq(#r.rows, 3, "top-level fixtures"); h.eq(r.partial, false); h.eq(r.next_offset, nil)
  local f = find(r.rows, "id", "201")
  h.eq(f.name, "Multi 8 Bar"); h.eq(f.fixture_type, "Multi 8"); h.eq(f.mode, "FixtureType 7.1.1"); h.eq(f.patch, "2.001"); h.eq(f.fid, 201)
  h.eq(#f.children, 8); h.eq(f.children[3].id, "201.3"); h.eq(f.children[3].cid, 3); h.eq(f.children[3].name, "Cell 3"); h.eq(f.children[3].sf_index, 103)
  local rack = find(r.rows, "id", "8")
  h.eq(#rack.children, 3); h.eq(rack.children[1].id, "1"); h.eq(rack.children[1].patch, "1.001"); h.eq(rack.children[1].address, "Fixture 1")
  h.eq(r.fixture_types[1].name, "Generic Dimmer"); h.eq(r.fixture_types[1].no, 3)
end)

h.describe("ma3_fixtures filters", function()
  local _, tools, ctx = setup()
  local r = tools.ma3_fixtures.handler({ type = "Multi" }, ctx)
  h.eq(#r.rows, 1); h.eq(r.rows[1].id, "201")
  local r2 = tools.ma3_fixtures.handler({ id_from = 1, id_to = 100 }, ctx)
  h.eq(#r2.rows, 1); h.eq(r2.rows[1].id, "8")
end)

h.describe("fixtures_returns_partial_with_next_offset_on_budget", function()
  local fake, tools, ctx = setup()
  ctx.budget_ms = 1; fake.slow = true
  local r = tools.ma3_fixtures.handler({}, ctx)
  h.eq(r.partial, true); h.truthy(r.next_offset); h.truthy(#r.rows >= 1)
  local r2 = tools.ma3_fixtures.handler({ offset = r.next_offset }, ctx)
  h.truthy(r2.rows[1].id ~= r.rows[1].id, "resumes after the first page")
end)

h.describe("ma3_sequences shows executors and never ranges pages", function()
  local fake, tools, ctx = setup()
  local r = tools.ma3_sequences.handler({}, ctx)
  h.eq(#r.rows, 6)
  local s = find(r.rows, "no", 12)
  h.eq(s.name, "Song A"); h.eq(s.cue_count, 4, "CueZero and OffCue are not cues"); h.eq(s.first_cue, "Cue 1"); h.eq(s.last_cue, "Cue 4"); h.eq(s.tags, "Song:0"); h.eq(s.note, "walk-in")
  h.eq(#s.executors, 2)
  h.eq(s.executors[1].page, 1); h.eq(s.executors[1].executor, 201); h.eq(s.executors[1].page_name, "Weekend"); h.eq(s.executors[1].label, "Song A")
  h.eq(s.executors[2].page, 3); h.eq(s.executors[2].executor, 101)
  local l = find(r.rows, "no", 13); h.eq(l.cue_count, 0); h.eq(#l.executors, 0)
  local old = find(r.rows, "no", 300); h.eq(old.cue_count, 0)
  h.eq(s.cues, nil)
  for _, call in ipairs(fake.objectlist_calls) do h.truthy(not call:lower():find("thru"), call) end
end)

h.describe("ma3_sequences include_cues and paging", function()
  local _, tools, ctx = setup()
  local r = tools.ma3_sequences.handler({ include_cues = true, limit = 2 }, ctx)
  h.eq(#r.rows, 2); h.eq(r.next_offset, 13)
  h.eq(r.rows[1].cues[2].no, 2000); h.eq(r.rows[1].cues[2].name, "Cue 2"); h.eq(r.rows[1].cues[2].trigger, "Follow")
  local r2 = tools.ma3_sequences.handler({ offset = r.next_offset }, ctx)
  h.eq(r2.rows[1].no, 14); h.eq(#r2.rows, 4); h.eq(r2.next_offset, nil)
end)

h.describe("ma3_pages", function()
  local _, tools, ctx = setup()
  local r = tools.ma3_pages.handler({}, ctx)
  h.eq(#r.rows, 2); h.eq(r.rows[1].no, 1); h.eq(r.rows[1].name, "Weekend"); h.eq(#r.rows[1].executors, 3)
  local e = r.rows[1].executors[1]
  h.eq(e.executor, 101); h.eq(e.label, "House"); h.eq(e.assigned, "Sequence 20"); h.eq(e.assigned_name, "House"); h.eq(e.key, "Go+"); h.eq(e.fader, "Master"); h.eq(e.width, 1); h.eq(e.height, 2)
  h.eq(r.rows[1].executors[2].executor, 201, "sorted by executor number")
  h.eq(r.rows[2].executors[1].assigned, "Sequence 12")
end)

h.describe("ma3_groups members", function()
  local _, tools, ctx = setup()
  local r = tools.ma3_groups.handler({}, ctx)
  h.eq(#r.rows, 2)
  h.eq(r.rows[1].no, 1); h.eq(r.rows[1].name, "Cells L"); h.eq(r.rows[1].tags, "LED:0")
  h.eq(r.rows[1].members[1], "201.1"); h.eq(r.rows[1].members[2], "201.2"); h.eq(r.rows[1].member_count, 2)
  h.eq(r.rows[1].member_details[1].name, "Cell 1"); h.eq(r.rows[1].member_details[1].sf_index, 101); h.eq(r.rows[1].member_details[1].x, 0)
  h.eq(r.rows[2].members[1], "1")
end)

h.describe("ma3_presets", function()
  local _, tools, ctx = setup()
  local r = tools.ma3_presets.handler({}, ctx)
  h.eq(#r.rows, 3)
  h.eq(r.rows[1].pool, 1); h.eq(r.rows[1].pool_name, "Dimmer"); h.eq(r.rows[1].no, 1); h.eq(r.rows[1].name, "Full"); h.eq(r.rows[1].address, "Preset 1.1"); h.eq(r.rows[1].child_count, 3)
  h.eq(r.rows[3].name, "Blue"); h.eq(r.rows[3].no, 7)
  local r2 = tools.ma3_presets.handler({ pool = 4 }, ctx)
  h.eq(#r2.rows, 2); h.eq(r2.rows[1].tags, "Song:0")
end)

h.describe("ma3_macros", function()
  local _, tools, ctx = setup()
  local r = tools.ma3_macros.handler({}, ctx)
  h.eq(#r.rows, 1); h.eq(r.rows[1].no, 1); h.eq(r.rows[1].name, "Relays On"); h.eq(#r.rows[1].lines, 3)
  h.eq(r.rows[1].lines[1].command, "Park Group 1100 At 100"); h.eq(r.rows[1].lines[1].wait, "Follow"); h.eq(r.rows[1].lines[2].enabled, false)
end)

h.describe("bulk tools give the console time when the work takes time", function()
  local fake, tools, ctx = setup()
  fake.work_cost = 0.0001          -- 2,000 sequence slots x 0.1 ms = 0.2 s of work
  tools.ma3_sequences.handler({ executors = false }, ctx)
  h.truthy(fake.yields >= 10, "a 0.2 s walk is broken up: " .. fake.yields)
  h.truthy(fake.yields <= 40, "about one yield per 10 ms of work, not one per slot: " .. fake.yields)
end)

-- ---------------------------------------------------------------------------------------------
-- Regression, 2026-11-05: on Aaron's console ma3_sequences returned no rows, partial = true and
-- next_offset = 0. The tools yielded once per 50 pool slots visited, empty slots included, and
-- one yield costs a console frame (about 31 ms). The Page pool has 9,999 slots and every page 390,
-- so the executor index alone used the whole 10 s budget once the show had 17 pages.
-- ---------------------------------------------------------------------------------------------

-- The default tree plus pages 4..(pages), each a copy of a small weekend page, like his show.
local function big_show(pages)
  local tree = fake_console.default_tree()
  local function find_class(node, class)
    for _, k in ipairs(node.children or {}) do
      if k.class == class then return k end
      local hit = find_class(k, class)
      if hit then return hit end
    end
  end
  local pool = find_class(tree, "Pages")
  for p = 4, pages do
    pool.children[#pool.children + 1] = { class = "Page", addr = "Page " .. p, name = "Nov " .. p, no = p, count = 390, slot = p, children = {
      { class = "Executor", addr = "Page " .. p .. ".106", name = "Song", no = 106, slot = 6,
        props = { { "OBJECT", "Handle", { addr = "Sequence 14", ToAddr = function(self) return self.addr end } }, { "KEYPRESS", "String", "Go+" },
          { "FADER", "String", "Master" }, { "WIDTH", "UInt32", 1 }, { "HEIGHT", "UInt32", 2 } } } } }
  end
  local fake = fake_console.new(tree)
  local c = console.new(fake.api)
  local tools = {}
  local ctx = { budget_ms = 10000, lua_enabled = function() return false end }
  bulk.register(tools, c, ctx)
  return fake, tools, ctx
end

-- Pages through a tool the way a client does and returns every row; fails if paging stalls.
local function page_through(tool, ctx, args)
  local rows, offset, calls = {}, 0, 0
  while offset do
    calls = calls + 1
    if calls > 500 then error("paging did not terminate") end
    local a = {}
    for k, v in pairs(args or {}) do a[k] = v end
    a.offset = offset
    local r = tool.handler(a, ctx)
    for _, row in ipairs(r.rows) do rows[#rows + 1] = row end
    if r.next_offset ~= nil and r.next_offset <= offset then error("next_offset did not advance: " .. tostring(r.next_offset)) end
    offset = r.next_offset
  end
  return rows, calls
end

h.describe("ma3_sequences answers on a 17-page show where a yield costs a console frame", function()
  local fake, tools, ctx = big_show(19)   -- 17 pages: 1, 3 and 4..19
  fake.yield_cost = 0.031; fake.work_cost = 0.000002
  local r = tools.ma3_sequences.handler({}, ctx)
  h.eq(#r.rows, 6, "every sequence"); h.eq(r.partial, false); h.eq(r.next_offset, nil)
  h.eq(#find(r.rows, "no", 14).executors, 17, "Song B sits on page 1 and on pages 4..19")
  h.truthy(fake.yields <= 20, "yields by elapsed time, not once per 50 slots: " .. fake.yields)
  h.truthy(fake.clock < 1, "well inside the budget: " .. fake.clock .. " s")
end)

h.describe("empty pool slots cost no yields", function()
  local fake, tools, ctx = setup()
  fake.yield_cost = 0.031
  local r = tools.ma3_pages.handler({}, ctx)
  h.eq(#r.rows, 2); h.eq(fake.yields, 0, "9,999 page slots and 780 executor slots, no time passed")
end)

h.describe("a paged read always advances, even with no budget at all", function()
  local fake, tools, ctx = big_show(19)
  fake.yield_cost = 0.031; fake.work_cost = 0.000002
  ctx.budget_ms = 0
  local seqs = page_through(tools.ma3_sequences, ctx)
  h.eq(#seqs, 6, "sequences")
  local pages = page_through(tools.ma3_pages, ctx)
  h.eq(#pages, 18, "pages"); h.eq(pages[18].no, 19)
  local groups = page_through(tools.ma3_groups, ctx); h.eq(#groups, 2, "groups")
  local macros = page_through(tools.ma3_macros, ctx); h.eq(#macros, 1, "macros")
  local presets = page_through(tools.ma3_presets, ctx); h.truthy(#presets >= 2, "presets")
  local fixtures = page_through(tools.ma3_fixtures, ctx); h.eq(#fixtures, 3, "fixtures")
end)

h.describe("a partial answer always carries at least one row", function()
  local fake, tools, ctx = big_show(19)
  fake.work_cost = 0.000002; ctx.budget_ms = 0
  local r = tools.ma3_sequences.handler({}, ctx)
  h.eq(r.partial, true); h.eq(#r.rows, 1); h.eq(r.next_offset, 12, "resume after slot 12")
  local filtered = tools.ma3_sequences.handler({ from = 300 }, ctx)
  h.eq(#filtered.rows, 1, "a filter that skips rows still reaches its first match"); h.eq(filtered.rows[1].no, 300)
end)

h.describe("the executor index does not eat the row budget", function()
  local fake, tools, ctx = big_show(19)
  fake.work_cost = 0.00002     -- the page walk alone is ~17,000 slots x 20 us = 0.34 s
  ctx.budget_ms = 100          -- the sequence walk (2,000 slots, ~0.05 s) fits; the index does not
  local r = tools.ma3_sequences.handler({}, ctx)
  h.eq(#r.rows, 6); h.eq(r.partial, false)
end)

h.describe("ma3_sequences executors:false skips the page walk", function()
  local fake, tools, ctx = setup()
  local r = tools.ma3_sequences.handler({ executors = false }, ctx)
  h.eq(#r.rows, 6); h.eq(find(r.rows, "no", 12).executors, nil)
  h.eq(#fake.objectlist_calls, 0, "no assigned object was looked up")
  local with = tools.ma3_sequences.handler({}, ctx)
  h.eq(#find(with.rows, "no", 12).executors, 2, "the default still lists executors")
end)

h.describe("ma3_pages reads only the page asked for", function()
  local fake, tools, ctx = setup()
  local r = tools.ma3_pages.handler({ page = 3 }, ctx)
  h.eq(#r.rows, 1); h.eq(r.rows[1].no, 3); h.eq(r.rows[1].name, "Busking"); h.eq(r.rows[1].executors[1].assigned, "Sequence 12")
  h.eq(r.next_offset, nil); h.eq(r.partial, false)
  for _, call in ipairs(fake.objectlist_calls) do h.truthy(call ~= "Sequence 14" and call ~= "Sequence 20", "page 1 was not read: " .. call) end
  h.eq(#tools.ma3_pages.handler({ page = 2 }, ctx).rows, 0, "a page that does not exist")
end)

h.describe("ma3_pages pages by page, not by slot", function()
  local _, tools, ctx = big_show(8)   -- pages 1, 3, 4..8
  local a = tools.ma3_pages.handler({ limit = 3 }, ctx)
  h.eq(#a.rows, 3); h.eq(a.rows[3].no, 4); h.eq(a.next_offset, 3); h.eq(a.partial, false)
  local b = tools.ma3_pages.handler({ offset = 3, limit = 3 }, ctx)
  h.eq(#b.rows, 3); h.eq(b.rows[1].no, 5); h.eq(b.next_offset, 6)
  local c2 = tools.ma3_pages.handler({ offset = 6, limit = 3 }, ctx)
  h.eq(#c2.rows, 1); h.eq(c2.rows[1].no, 8); h.eq(c2.next_offset, nil)
  local exact = tools.ma3_pages.handler({ limit = 7 }, ctx)
  h.eq(#exact.rows, 7); h.eq(exact.next_offset, nil, "nothing left after the last page")
end)
