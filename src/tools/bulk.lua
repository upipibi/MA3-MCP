-- Bulk reads: the fast path for housekeeping jobs. Every walk goes object by object
-- (never a Page/Executor range), gives the console time by elapsed time (console.pace, never
-- by slot count), and returns partial rows with next_offset when the request budget runs out.
-- A paged read always produces at least one row before it may report partial, so paging
-- always advances.
local console = require("console")

local M = {}

local MAX_ROWS = 500

local function num(v)
  if type(v) == "number" then return v end
  local n = tonumber(v)
  return n
end

local function limits(args)
  local offset = math.max(0, math.floor(num(args.offset) or 0))
  local limit = math.min(MAX_ROWS, math.max(1, math.floor(num(args.limit) or MAX_ROWS)))
  return offset, limit
end

-- A budget object: over() becomes true once the request has used its time; tick() gives the
-- console time when enough work has been done since the last yield. Create it where the
-- budgeted work starts: time spent before that (building an index) is not charged to it.
local function budget(c, ctx)
  c:start_slice()
  local t0 = c:now()
  local ms = num(ctx.budget_ms) or 10000
  return {
    tick = function() c:pace() end,
    over = function() return (c:now() - t0) * 1000 > ms end,
  }
end

local function prop(h, name) return console.get(h, name) end
local function name_of(h) local n = h.name; if n == nil or n == "" then n = prop(h, "NAME") end return n end

-- Walks a sparse pool with Ptr(i) from slot `offset+1`, calling fn(handle, slot) for each present
-- child, until `limit` rows are collected or the budget is spent. Returns next_offset, partial.
local function walk_pool(pool, offset, limit, b, fn)
  local total = pool:Count()
  local rows = 0
  local i = offset + 1
  while i <= total do
    if rows >= limit then return i - 1, false end
    -- Never stop on the budget before the first row: an answer with no rows and the same
    -- offset would make the client ask the same question forever.
    if rows > 0 and b.over() then return i - 1, true end
    local h = pool:Ptr(i)
    if h then
      if fn(h, i) ~= false then rows = rows + 1 end
    end
    b.tick()
    i = i + 1
  end
  return nil, false
end

----------------------------------------------------------------------------- fixtures

local function fixture_id(h, parent_id)
  local fid = num(prop(h, "FID"))
  if fid then return tostring(fid), fid end
  local cid = num(prop(h, "CID"))
  local no = cid or num(prop(h, "NO"))
  if parent_id and no then return parent_id .. "." .. tostring(no), nil end
  return no and tostring(no) or h:ToAddr(), nil
end

local function fixture_row(h, parent_id, type_names, b, depth)
  local id, fid = fixture_id(h, parent_id)
  local ft = prop(h, "FIXTURETYPE")
  local row = {
    id = id, fid = fid, cid = num(prop(h, "CID")), name = name_of(h), idtype = prop(h, "IDTYPE"),
    patch = prop(h, "PATCH"), fixture_type = ft and (type_names[ft] or ft) or nil, mode = prop(h, "MODE"),
    sf_index = num(prop(h, "SUBFIXTUREINDEX")), address = h:ToAddr(),
  }
  local n = h:Count()
  if n > 0 and depth < 6 then
    row.children = {}
    for i = 1, n do
      local ch = h:Ptr(i)
      if ch then row.children[#row.children + 1] = fixture_row(ch, id, type_names, b, depth + 1) end
      b.tick()
    end
  end
  return row
end

local function fixture_types(c)
  local out, names = {}, {}
  local ok = pcall(function()
    local p = c:patch()
    local pool = p.FixtureTypes
    if not pool then for _, ch in ipairs(p:Children()) do if ch:GetClass() == "FixtureTypes" then pool = ch end end end
    for _, ft in ipairs(pool:Children()) do
      local row = { no = num(prop(ft, "NO")), name = name_of(ft), address = ft:ToAddr() }
      out[#out + 1] = row
      names[ft:ToAddr()] = row.name
    end
  end)
  return out, names
end

local function stage_fixtures(c)
  local p = c:patch()
  local stages = p.Stages
  if not stages then for _, ch in ipairs(p:Children()) do if ch:GetClass() == "Stages" then stages = ch end end end
  local stage = stages and stages:Ptr(1)
  if not stage then return nil end
  local fx = stage.Fixtures
  if not fx then for _, ch in ipairs(stage:Children()) do if ch:GetClass() == "Fixtures" then fx = ch end end end
  return fx
end

local function matches_type(row, needle)
  if not needle then return true end
  local n = needle:lower()
  local function hit(r)
    if r.fixture_type and r.fixture_type:lower():find(n, 1, true) then return true end
    for _, ch in ipairs(r.children or {}) do if hit(ch) then return true end end
    return false
  end
  return hit(row)
end

local function matches_range(row, from, to)
  if not from and not to then return true end
  local function hit(r)
    if r.fid and (not from or r.fid >= from) and (not to or r.fid <= to) then return true end
    for _, ch in ipairs(r.children or {}) do if hit(ch) then return true end end
    return false
  end
  return hit(row)
end

----------------------------------------------------------------------------- executors index

-- Reads one page: every executor slot, one object at a time. names caches assigned-object
-- names across pages; index (optional) collects index[assigned address] = { {page, executor,
-- page_name, label} }.
local function read_page(c, b, pg, slot, names, index)
  local page = { no = num(prop(pg, "NO")) or slot, name = name_of(pg), address = pg:ToAddr(), executors = {} }
  for i = 1, pg:Count() do
    local ex = pg:Ptr(i)
    if ex then
      local assigned = prop(ex, "OBJECT")
      local row = {
        executor = num(prop(ex, "NO")) or i, label = name_of(ex), assigned = assigned,
        key = prop(ex, "KEYPRESS"), fader = prop(ex, "FADER"), width = num(prop(ex, "WIDTH")), height = num(prop(ex, "HEIGHT")),
      }
      if assigned then
        if names[assigned] == nil then
          local okN, obj = pcall(function() return c:object(assigned) end)
          names[assigned] = (okN and obj and name_of(obj)) or false
        end
        row.assigned_name = names[assigned] or nil
        if index then
          index[assigned] = index[assigned] or {}
          table.insert(index[assigned], { page = page.no, executor = row.executor, page_name = page.name, label = row.label })
        end
      end
      page.executors[#page.executors + 1] = row
    end
    b.tick()
  end
  table.sort(page.executors, function(a, z) return a.executor < z.executor end)
  return page
end

-- Walks every page for the executor index: index[assigned address] = { {page, executor,
-- page_name, label} }. It is a whole-show read with no paging, so its caller gives it its own
-- budget object (for pacing only) and starts the row budget afterwards.
local function executor_index(c, b)
  local pool = c:datapool().Pages
  local index, names = {}, {}
  if not pool then return index end
  for p = 1, pool:Count() do
    local pg = pool:Ptr(p)
    if pg then read_page(c, b, pg, p, names, index) end
    b.tick()
  end
  return index
end

----------------------------------------------------------------------------- register

function M.register(tools, c, ctx)
  tools.ma3_fixtures = {
    description = "The whole patch as a tree: every fixture with id, fid, cid, name, idtype, patch (universe.address), fixture_type, mode, sf_index, address, and its children (sub-fixtures / instances of multi-instance fixtures, or fixtures inside a grouping fixture) recursively. Also lists fixture_types. Filters: type (fixture type name substring), id_from/id_to (FID range), summary:true (top-level entries only, no children; cheap). Paged over top-level fixtures (offset, limit, next_offset); partial=true means the time budget ran out and the next call should resume at next_offset. Read-only.",
    inputSchema = { type = "object", properties = { offset = { type = "integer" }, limit = { type = "integer" }, type = { type = "string" }, id_from = { type = "integer" }, id_to = { type = "integer" }, summary = { type = "boolean" } } },
    handler = function(args)
      args = args or {}
      local b = budget(c, ctx)
      local offset, limit = limits(args)
      local fx = stage_fixtures(c)
      if not fx then return nil, "patch has no Stage 1 fixtures" end
      local types, type_names = fixture_types(c)
      local rows = {}
      local next_offset, partial = walk_pool(fx, offset, limit, b, function(h)
        local row = fixture_row(h, nil, type_names, b, args.summary and 6 or 0)
        if args.summary then row.child_count = h:Count() end
        if matches_type(row, args.type) and matches_range(row, num(args.id_from), num(args.id_to)) then
          rows[#rows + 1] = row
        else
          return false
        end
      end)
      return { rows = rows, total_top_level = fx:Count(), next_offset = next_offset, partial = partial, fixture_types = types }
    end,
  }

  tools.ma3_groups = {
    description = "Every group: no, name, note, tags, appearance, address, members (fixture ids such as '201.3' in selection order) and member_details (sf_index, name, address, grid x/y/z). Paged (offset, limit, next_offset, partial). Read-only.",
    inputSchema = { type = "object", properties = { offset = { type = "integer" }, limit = { type = "integer" } } },
    handler = function(args)
      args = args or {}
      local b = budget(c, ctx)
      local offset, limit = limits(args)
      local pool = c:datapool().Groups
      if not pool then return nil, "no Groups pool" end
      local rows = {}
      local next_offset, partial = walk_pool(pool, offset, limit, b, function(g, slot)
        local row = { no = num(prop(g, "NO")) or slot, name = name_of(g), note = prop(g, "NOTE"), tags = prop(g, "TAGS"),
          appearance = prop(g, "APPEARANCE"), address = g:ToAddr(), members = {}, member_details = {} }
        local okD, data = pcall(function() return (g:Get("SELECTIONDATA")) end)
        if okD and type(data) == "table" then
          for _, e in ipairs(data) do
            if type(e) == "table" and e.sf_index then
              local sf = c.api.GetSubfixture and c.api.GetSubfixture(e.sf_index)
              local id = sf and select(1, fixture_id(sf, nil)) or ("sf" .. tostring(e.sf_index))
              if sf and not num(prop(sf, "FID")) then
                -- an instance: prefix the nearest ancestor's FID
                local parent = sf:Parent()
                local pfid = parent and num(prop(parent, "FID"))
                if pfid then id = tostring(pfid) .. "." .. tostring(num(prop(sf, "CID")) or num(prop(sf, "NO")) or "?") end
              end
              row.members[#row.members + 1] = id
              local g2 = e.grid or {}
              row.member_details[#row.member_details + 1] = { id = id, sf_index = e.sf_index, name = sf and name_of(sf) or nil,
                address = sf and sf:ToAddr() or nil, x = g2.x, y = g2.y, z = g2.z }
            end
          end
        end
        row.member_count = #row.members
        rows[#rows + 1] = row
      end)
      return { rows = rows, next_offset = next_offset, partial = partial }
    end,
  }

  tools.ma3_sequences = {
    description = "Every sequence: no, name, note, tags, appearance, address, cue_count (excluding CueZero), first_cue, last_cue, and executors = every page/executor it is assigned to ({page, executor, page_name, label}; executors:false skips that page walk and leaves the field out). include_cues:true adds cues [{no (console-internal thousandths: 1000 = Cue 1), name, trigger}]. Filters: from/to (sequence number range), name (case-insensitive substring). Paged (offset, limit, next_offset, partial). Built without any Page/Executor range. Read-only.",
    inputSchema = { type = "object", properties = { executors = { type = "boolean" }, offset = { type = "integer" }, limit = { type = "integer" }, include_cues = { type = "boolean" }, from = { type = "integer" }, to = { type = "integer" }, name = { type = "string" } } },
    handler = function(args)
      args = args or {}
      local b = budget(c, ctx)
      local offset, limit = limits(args)
      local pool = c:datapool().Sequences
      if not pool then return nil, "no Sequences pool" end
      -- The executor index is a walk over every page. It is done before the row budget
      -- starts, so a show with many pages cannot leave the rows with no time.
      local index = nil
      if args.executors ~= false then
        index = executor_index(c, b)
        b = budget(c, ctx)
      end
      local rows = {}
      local from, to, needle = num(args.from), num(args.to), args.name and args.name:lower() or nil
      local next_offset, partial = walk_pool(pool, offset, limit, b, function(s, slot)
        local sno = num(prop(s, "NO")) or slot
        if (from and sno < from) or (to and sno > to) then return false end
        local sname = name_of(s)
        if needle and not tostring(sname or ""):lower():find(needle, 1, true) then return false end
        local row = { no = sno, name = sname, note = prop(s, "NOTE"), tags = prop(s, "TAGS"),
          appearance = prop(s, "APPEARANCE"), address = s:ToAddr(), executors = index and (index[s:ToAddr()] or {}) or nil }
        local n = s:Count()
        local cues = {}
        for i = 1, n do
          local cue = s:Ptr(i)
          if cue then
            local no = num(prop(cue, "NO"))
            -- CueZero (0) and OffCue (no number) are the console's, not the programmer's
            if no and no > 0 then cues[#cues + 1] = { no = no, name = name_of(cue), trigger = prop(cue, "TRIGTYPE") } end
          end
        end
        row.cue_count = #cues
        row.first_cue = cues[1] and cues[1].name or nil
        row.last_cue = cues[#cues] and cues[#cues].name or nil
        if args.include_cues then row.cues = cues end
        rows[#rows + 1] = row
      end)
      return { rows = rows, next_offset = next_offset, partial = partial }
    end,
  }

  tools.ma3_pages = {
    description = "Every page with its executors: {no, name, address, executors=[{executor, label, assigned (object address), assigned_name, key, fader, width, height}]}, sorted by executor number. {page:n} reads that page only. Walks one page and one executor at a time (never a range). Paged over pages: offset counts pages, not pool slots (offset, limit, next_offset, partial); partial=true means the time budget ran out and the next call should resume at next_offset. Read-only.",
    inputSchema = { type = "object", properties = { offset = { type = "integer" }, limit = { type = "integer" }, page = { type = "integer" } } },
    handler = function(args)
      args = args or {}
      local b = budget(c, ctx)
      local offset, limit = limits(args)
      local pool = c:datapool().Pages
      if not pool then return { rows = {}, next_offset = nil, partial = false } end
      local names = {}
      local total = pool:Count()

      local want = num(args.page)
      if want then
        -- A page normally sits in the pool slot of its number; look there first and fall
        -- back to a scan (page handles only, no executors) if it does not.
        local pg, slot = nil, nil
        local direct = want >= 1 and want <= total and pool:Ptr(want) or nil
        if direct and (num(prop(direct, "NO")) or want) == want then
          pg, slot = direct, want
        else
          for p = 1, total do
            local x = pool:Ptr(p)
            if x and num(prop(x, "NO")) == want then pg, slot = x, p break end
            b.tick()
          end
        end
        local rows = {}
        if pg and offset == 0 then rows[1] = read_page(c, b, pg, slot, names) end
        return { rows = rows, next_offset = nil, partial = false }
      end

      local rows, seen, next_offset, partial = {}, 0, nil, false
      for p = 1, total do
        local pg = pool:Ptr(p)
        if pg then
          if seen >= offset then
            -- Reaching here with the limit full means another page exists after it.
            if #rows >= limit then next_offset = offset + #rows break end
            if #rows > 0 and b.over() then next_offset = offset + #rows; partial = true break end
            rows[#rows + 1] = read_page(c, b, pg, p, names)
          end
          seen = seen + 1
        end
        b.tick()
      end
      return { rows = rows, next_offset = next_offset, partial = partial }
    end,
  }

  tools.ma3_presets = {
    description = "Presets across every pool (or one pool with pool=<n>): {pool, pool_name, no, name, tags, appearance, note, address, child_count}. Values are not read. Paged (offset, limit, next_offset, partial); offset counts rows across pools. Read-only.",
    inputSchema = { type = "object", properties = { pool = { type = "integer" }, offset = { type = "integer" }, limit = { type = "integer" } } },
    handler = function(args)
      args = args or {}
      local b = budget(c, ctx)
      local offset, limit = limits(args)
      local pools = c:datapool().PresetPools
      if not pools then return nil, "no PresetPools" end
      local rows, seen, partial = {}, 0, false
      local want = num(args.pool)
      for _, pp in ipairs(pools:Children()) do
        local pno = num(prop(pp, "NO"))
        if not want or want == pno then
          for i = 1, pp:Count() do
            if #rows >= limit then break end
            if #rows > 0 and b.over() then partial = true break end
            local pr = pp:Ptr(i)
            if pr then
              seen = seen + 1
              if seen > offset then
                rows[#rows + 1] = { pool = pno, pool_name = name_of(pp), no = num(prop(pr, "NO")) or i, name = name_of(pr), tags = prop(pr, "TAGS"),
                  appearance = prop(pr, "APPEARANCE"), note = prop(pr, "NOTE"), address = pr:ToAddr(), child_count = pr:Count() }
              end
            end
            b.tick()
          end
        end
        if #rows >= limit or partial then break end
      end
      local next_offset = (#rows >= limit or partial) and (offset + #rows) or nil
      return { rows = rows, next_offset = next_offset, partial = partial }
    end,
  }

  tools.ma3_macros = {
    description = "Every macro with its lines: {no, name, note, tags, address, lines=[{no, name, command, wait, enabled}]}. Paged (offset, limit, next_offset, partial). Read-only.",
    inputSchema = { type = "object", properties = { offset = { type = "integer" }, limit = { type = "integer" } } },
    handler = function(args)
      args = args or {}
      local b = budget(c, ctx)
      local offset, limit = limits(args)
      local pool = c:datapool().Macros
      if not pool then return nil, "no Macros pool" end
      local rows = {}
      local next_offset, partial = walk_pool(pool, offset, limit, b, function(m, slot)
        local row = { no = num(prop(m, "NO")) or slot, name = name_of(m), note = prop(m, "NOTE"), tags = prop(m, "TAGS"), address = m:ToAddr(), lines = {} }
        for i = 1, m:Count() do
          local ln = m:Ptr(i)
          if ln then
            local en = prop(ln, "ENABLED")
            if type(en) == "string" then en = (en:lower() == "true" or en:lower() == "yes") end
            row.lines[#row.lines + 1] = { no = num(prop(ln, "NO")) or i, name = name_of(ln), command = prop(ln, "COMMAND"), wait = prop(ln, "WAIT"), enabled = en }
          end
        end
        rows[#rows + 1] = row
      end)
      return { rows = rows, next_offset = next_offset, partial = partial }
    end,
  }
end

return M
