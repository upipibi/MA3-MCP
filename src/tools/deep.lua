-- Deep reads that the bulk tools leave out: cue timing, timecode events, command history,
-- and a sequence/preset export (the only path to the values inside a cue).
local addr = require("addr")
local console = require("console")

local M = {}

local function num(v) if type(v) == "number" then return v end return tonumber(v) end
local function prop(h, name) return console.get(h, name) end
local function name_of(h) local n = h.name; if n == nil or n == "" then n = prop(h, "NAME") end return n end
local function strip_ansi(s) return (tostring(s or ""):gsub("\27%[[%d;]*m", "")) end

local function resolve(c, address)
  if address == nil then return nil, "address is required" end
  local ok, why = addr.check(address)
  if not ok then return nil, why .. " " .. tostring(address) end
  local h = c:object(address)
  if not h then return nil, "object not found: " .. address end
  return h
end

local function child_of_class(h, class)
  for _, ch in ipairs(h:Children()) do if ch:GetClass() == class then return ch end end
  return nil
end

-- Removes every <Tag ...>...</Tag> block (nesting-aware) and self-closing <Tag .../> from xml.
function M.strip_blocks(xml, tag)
  local open_pat, close_tag = "<" .. tag, "</" .. tag .. ">"
  local out, pos, removed = {}, 1, 0
  while true do
    local s0, e0 = xml:find(open_pat, pos, true)
    if not s0 then break end
    local nxt = xml:sub(e0 + 1, e0 + 1)
    if nxt ~= " " and nxt ~= ">" and nxt ~= "/" then  -- a longer tag name that merely starts the same
      out[#out + 1] = xml:sub(pos, e0); pos = e0 + 1
    else
      out[#out + 1] = xml:sub(pos, s0 - 1)
      local tag_end = xml:find(">", e0, true)
      if xml:sub(tag_end - 1, tag_end) == "/>" then
        removed = removed + (tag_end - s0 + 1); pos = tag_end + 1
      else
        local depth, cursor, finish = 1, tag_end + 1, nil
        while depth > 0 do
          local o = xml:find(open_pat, cursor, true)
          local c = xml:find(close_tag, cursor, true)
          if not c then finish = #xml break end
          if o and o < c then
            local oe = xml:find(">", o, true)
            if xml:sub(oe - 1, oe) ~= "/>" then depth = depth + 1 end
            cursor = oe + 1
          else
            depth = depth - 1; cursor = c + #close_tag; finish = cursor - 1
          end
        end
        removed = removed + (finish - s0 + 1); pos = finish + 1
      end
    end
  end
  out[#out + 1] = xml:sub(pos)
  return table.concat(out), removed
end

local function cue_number(raw)
  local n = num(raw)
  if n == nil then return nil end
  return n / 1000
end

function M.register(tools, c, ctx, deps)
  deps = deps or {}

  tools.ma3_cue_timing = {
    description = "Cue list of one sequence with timing: for every cue {cue (as the console shows it, 12.2 not 12200), name, trigger, trig_time, in_fade, in_delay, out_fade, out_delay, snap_delay, cmd_delay, mib, note} read from the cue's part 0, plus the sequence's settings (tracking, auto stop, priority, restart mode, appearance). {sequence: 54} or {address:'Sequence 54'}. Read-only.",
    inputSchema = { type = "object", properties = { sequence = { type = "integer" }, address = { type = "string" } } },
    handler = function(args)
      args = args or {}
      c:start_slice()
      local address = args.address or (args.sequence and ("Sequence " .. tostring(args.sequence)))
      local s, err = resolve(c, address)
      if not s then return nil, err end
      local keys = { "TRACKING", "AUTOSTOP", "AUTOSTART", "AUTOPREPOS", "PRIORITY", "RESTARTMODE", "WRAPAROUND", "SOFTLTP", "OFFWHENOVERRIDDEN", "RELEASEFIRSTCUE", "SEQUMIB", "SEQUMIBMODE", "XFADEMODE", "USEEXECUTORTIME", "APPEARANCE", "NOTE" }
      local settings = {}
      for _, k in ipairs(keys) do settings[k:lower()] = prop(s, k) end
      local cues = {}
      for i = 1, s:Count() do
        local cue = s:Ptr(i)
        if cue then
          local no = num(prop(cue, "NO"))
          if no and no > 0 then
            local part = cue:Ptr(1)
            local row = { cue = no / 1000, name = name_of(cue), trigger = prop(cue, "TRIGTYPE"), trig_time = prop(cue, "TRIGTIME"), note = prop(cue, "NOTE") }
            if part then
              row.in_fade = prop(part, "CUEINFADE"); row.in_delay = prop(part, "CUEINDELAY")
              row.out_fade = prop(part, "CUEOUTFADE"); row.out_delay = prop(part, "CUEOUTDELAY")
              row.snap_delay = prop(part, "SNAPDELAY"); row.cmd_delay = prop(part, "COMMANDDELAY")
              row.mib = prop(part, "MIBMODE"); row.command = prop(part, "COMMAND")
              row.parts = cue:Count()
            end
            cues[#cues + 1] = row
          end
        end
        c:pace()
      end
      return { address = s:ToAddr(), name = name_of(s), settings = settings, cue_count = #cues, cues = cues }
    end,
  }

  tools.ma3_timecode = {
    description = "One timecode show as tracks and events: {no, name, duration, slot, offset, frame_readout, tracks=[{no, name, target (sequence address), ranges=[{start, duration, speed, events=[{time (s), name, cue (destination address), command}]}]}], markers}. {timecode: 1} or {address:'Timecode 1'}. Yields between tracks; {max_events} caps the total (default 5000). Read-only.",
    inputSchema = { type = "object", properties = { timecode = { type = "integer" }, address = { type = "string" }, max_events = { type = "integer" } } },
    handler = function(args)
      args = args or {}
      c:start_slice()
      local address = args.address or (args.timecode and ("Timecode " .. tostring(args.timecode)))
      local tc, err = resolve(c, address)
      if not tc then return nil, err end
      local cap = math.max(1, math.floor(num(args.max_events) or 5000))
      local out = { address = tc:ToAddr(), name = name_of(tc), duration = prop(tc, "DURATION"), slot = prop(tc, "TCSLOT"), offset = prop(tc, "OFFSETTCSLOT"),
        frame_readout = prop(tc, "FRAMEREADOUT"), loop = prop(tc, "LOOPMODE"), tracks = {}, markers = {}, event_count = 0, truncated = false }
      for _, grp in ipairs(tc:Children()) do
        for _, tr in ipairs(grp:Children()) do
          local cls = tr:GetClass()
          if cls == "MarkerTrack" then
            for _, mk in ipairs(tr:Children()) do out.markers[#out.markers + 1] = { time = prop(mk, "TIME"), name = name_of(mk) } end
          else
            local track = { no = num(prop(tr, "NO")), name = name_of(tr), target = prop(tr, "TARGET"), group = name_of(grp), ranges = {} }
            for _, rg in ipairs(tr:Children()) do
              local range = { start = prop(rg, "START"), duration = prop(rg, "DURATION"), speed = prop(rg, "SPEEDFACTOR"), events = {} }
              for _, sub in ipairs(rg:Children()) do
                for _, ev in ipairs(sub:Children()) do
                  if out.event_count >= cap then out.truncated = true break end
                  out.event_count = out.event_count + 1
                  local e = { time = prop(ev, "TIME"), name = name_of(ev), cue = prop(ev, "CUEDESTINATION"), command = prop(ev, "EXECUTECOMMAND") }
                  if e.command == "---" then e.command = nil end
                  range.events[#range.events + 1] = e
                end
              end
              table.sort(range.events, function(a, z) return (num(a.time) or 0) < (num(z.time) or 0) end)
              track.ranges[#track.ranges + 1] = range
            end
            out.tracks[#out.tracks + 1] = track
          end
          c:pace()
        end
      end
      return out
    end,
  }

  tools.ma3_history = {
    description = "What happened on the console: per command line {name, user, profile, last_command (the console's response text followed by the command)}, the undo history newest first {index, name (action text), session_time, elapsed_ms} up to {limit} (default 50, max 500), and the command-line text lines if the console exposes them (lines_supported). Read-only.",
    inputSchema = { type = "object", properties = { limit = { type = "integer" } } },
    handler = function(args)
      args = args or {}
      c:start_slice()
      local limit = math.min(500, math.max(1, math.floor(num(args.limit) or 50)))
      local root = c:root()
      local temp = child_of_class(root, "Temp")
      local cmdlines = temp and child_of_class(temp, "Cmdlines")
      if not cmdlines then return nil, "no Cmdlines object under Root/Temp on this console" end
      local out = { cmdlines = {}, undo = {}, lines = {}, lines_supported = false }
      for _, cl in ipairs(cmdlines:Children()) do
        local row = { name = name_of(cl), user = prop(cl, "USER"), profile = prop(cl, "PROFILE"), last_command = prop(cl, "LASTCOMMAND"),
          last_execution_ms = prop(cl, "LASTCOMMANDEXECUTIONTIME") }
        local okN, n = pcall(function() return cl:GetLineCount() end)
        if okN and type(n) == "number" and n > 0 then
          out.lines_supported = true
          local first = math.max(1, n - limit + 1)
          for i = first, n do
            local okL, line = pcall(function() return cl:GetLineAt(i) end)
            if okL and line ~= nil then out.lines[#out.lines + 1] = { cmdline = row.name, no = i, text = strip_ansi(line) } end
          end
        end
        out.cmdlines[#out.cmdlines + 1] = row
        local undos = child_of_class(cl, "Undos")
        if undos and #out.undo == 0 then
          local total = undos:Count()
          out.undo_total = total
          local i = total
          while i >= 1 and #out.undo < limit do
            local u = undos:Ptr(i)
            if u then out.undo[#out.undo + 1] = { index = i, name = strip_ansi(name_of(u)), session_time = prop(u, "SESSIONTIME"), elapsed_ms = prop(u, "ELAPSEDTIME") } end
            i = i - 1
            c:pace()
          end
        end
      end
      return out
    end,
  }

  tools.ma3_export = {
    description = "Export one object (a sequence, preset, group, macro, page ...) to XML in the console's temp folder and return the XML text. This is the only way to read the values inside cues: fixtures, attributes, presets used (by name), per-fixture timing. By default the embedded copies of referenced presets/appearances (<DependencyExport> blocks, often most of the file) are stripped; {strip_dependencies:false} keeps them. {max_bytes} (default 8000000) truncates with truncated=true. Refuses Page/Executor ranges. Writes a scratch file; changes nothing in the show.",
    inputSchema = { type = "object", required = { "address" }, properties = { address = { type = "string" }, max_bytes = { type = "integer" }, strip_dependencies = { type = "boolean" } } },
    handler = function(args)
      args = args or {}
      c:start_slice()
      local h, err = resolve(c, args.address)
      if not h then return nil, err end
      local fs = deps.fs
      if not fs or not fs.read then return nil, "no filesystem access in this build" end
      local dir = c:path("Temp")
      local stem = "ma3_mcp_export"
      local ok, res = pcall(function() return h:Export(dir, stem .. ".xml") end)
      if not ok then return nil, "export failed: " .. tostring(res) end
      if res == false then return nil, "the console refused the export of " .. h:ToAddr() end
      local data, path
      for _, cand in ipairs({ dir .. "/" .. stem .. ".xml", dir .. "/" .. stem .. ".xml.xml", dir .. "/" .. stem }) do
        data = fs.read(cand)
        if data then path = cand break end
      end
      if not data then return nil, "export reported success but no file appeared in " .. dir end
      local raw_bytes, stripped = #data, 0
      if args.strip_dependencies ~= false then
        data, stripped = M.strip_blocks(data, "DependencyExport")
        c:yield()
      end
      local cap = math.max(1024, math.floor(num(args.max_bytes) or 8000000))
      local truncated = #data > cap
      return { address = h:ToAddr(), class = h:GetClass(), name = name_of(h), path = path, bytes = #data, raw_bytes = raw_bytes,
        stripped_bytes = stripped, truncated = truncated, xml = truncated and data:sub(1, cap) or data }
    end,
  }
end

return M
