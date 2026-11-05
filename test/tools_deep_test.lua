local console = require("console")
local deep = require("tools.deep")
local bulk = require("tools.bulk")
local fake_console = require("fake_console")
local h = require("helpers")

local fake = fake_console.new()
local c = console.new(fake.api)
local tools = {}
local ctx = { budget_ms = 10000, lua_enabled = function() return false end, plugin_version = "0.2.0", started_at = 0, request_count = 0 }
local files = { ["/fake/temp/ma3_mcp_export.xml"] = "<GMA3 DataVersion=\"2.5.1.1\"><Sequence Name=\"Song A\"/></GMA3>" }
local fs = { read = function(path) return files[path] end }
deep.register(tools, c, ctx, { fs = fs })
bulk.register(tools, c, ctx)

h.describe("ma3_cue_timing reads part 0 of every cue and shows console cue numbers", function()
  local r = tools.ma3_cue_timing.handler({ sequence = 12 }, ctx)
  h.eq(r.address, "Sequence 12"); h.eq(r.name, "Song A"); h.eq(r.cue_count, 4)
  h.eq(r.cues[1].cue, 1); h.eq(r.cues[1].name, "Cue 1"); h.eq(r.cues[1].trigger, "Go"); h.eq(r.cues[1].in_fade, 4)
  h.eq(r.cues[2].cue, 2); h.eq(r.cues[2].trigger, "Follow"); h.eq(r.cues[2].in_fade, 2); h.eq(r.cues[2].out_fade, "CueTiming")
  h.eq(r.cues[4].parts, 1)
  h.eq(r.settings.note, "walk-in")
  local r2 = tools.ma3_cue_timing.handler({ address = "Sequence 12" }, ctx); h.eq(r2.cue_count, 4)
  local _, err = tools.ma3_cue_timing.handler({ sequence = 999 }, ctx); h.truthy(err:find("not found"))
  local _, e2 = tools.ma3_cue_timing.handler({}, ctx); h.truthy(e2)
end)

h.describe("ma3_timecode lists tracks, sorted events and markers", function()
  local r = tools.ma3_timecode.handler({ timecode = 1 }, ctx)
  h.eq(r.name, "Carol"); h.eq(r.duration, "3m27:00"); h.eq(r.slot, 1); h.eq(r.frame_readout, "S1<30 fps>")
  h.eq(#r.tracks, 1); h.eq(r.tracks[1].target, "Sequence 12"); h.eq(r.tracks[1].name, "<Carol>")
  local ev = r.tracks[1].ranges[1].events
  h.eq(#ev, 2); h.eq(ev[1].time, 0.7); h.eq(ev[1].cue, "Sequence 12.1000"); h.eq(ev[2].time, 9.1); h.eq(ev[1].command, nil)
  h.eq(r.event_count, 2); h.eq(r.truncated, false)
  h.eq(#r.markers, 1); h.eq(r.markers[1].name, "Verse"); h.eq(r.markers[1].time, 12.5)
  local r2 = tools.ma3_timecode.handler({ timecode = 1, max_events = 1 }, ctx)
  h.eq(r2.event_count, 1); h.eq(r2.truncated, true)
  local _, err = tools.ma3_timecode.handler({ timecode = 7 }, ctx); h.truthy(err:find("not found"))
end)

h.describe("ma3_history returns last command, undo list newest first with ANSI stripped", function()
  local r = tools.ma3_history.handler({ limit = 2 }, ctx)
  h.eq(#r.cmdlines, 1); h.eq(r.cmdlines[1].name, "Cmdline 1"); h.eq(r.cmdlines[1].user, "User 5")
  h.eq(r.cmdlines[1].last_command, 'OK: Label Sequence 68 "Joyful"')
  h.eq(r.undo_total, 3); h.eq(#r.undo, 2)
  h.eq(r.undo[1].index, 3); h.eq(r.undo[1].name, "Full"); h.eq(r.undo[1].session_time, "14:00:09")
  h.eq(r.undo[2].name, "Store Sequence 1", "colour codes stripped")
  h.eq(r.lines_supported, false); h.eq(#r.lines, 0)
  -- a console that exposes command-line text lines
  local cl = fake.by_addr["Root 20.1.1"]
  cl.GetLineCount = function() return 3 end
  cl.GetLineAt = function(_, i) return "\27[92mline " .. i .. "\27[97m" end
  local r2 = tools.ma3_history.handler({ limit = 2 }, ctx)
  h.eq(r2.lines_supported, true); h.eq(#r2.lines, 2); h.eq(r2.lines[1].no, 2); h.eq(r2.lines[1].text, "line 2"); h.eq(r2.lines[2].text, "line 3")
  cl.GetLineCount = nil; cl.GetLineAt = nil
end)

h.describe("strip_blocks removes nested DependencyExport blocks and nothing else", function()
  local xml = '<Cue><Part a="1"><DependencyExport Size="1"><Dependency><Preset><DependencyExport Size="1"><Dependency/></DependencyExport><PresetData/></Preset></Dependency></DependencyExport><PresetData Size="2"><Phaser/></PresetData></Part><DependencyExportX/></Cue>'
  local out, removed = deep.strip_blocks(xml, "DependencyExport")
  h.eq(out, '<Cue><Part a="1"><PresetData Size="2"><Phaser/></PresetData></Part><DependencyExportX/></Cue>')
  h.eq(removed, #xml - #out)
  local out2, r2 = deep.strip_blocks('<A><DependencyExport Size="0"/><B/></A>', "DependencyExport")
  h.eq(out2, "<A><B/></A>"); h.eq(r2, 28)
  local out3 = deep.strip_blocks("<A><B/></A>", "DependencyExport"); h.eq(out3, "<A><B/></A>")
  local out4 = deep.strip_blocks("<A><DependencyExport><x>", "DependencyExport"); h.eq(out4, "<A>", "unterminated block drops to the end")
end)

h.describe("ma3_export writes to Temp and returns the XML", function()
  files["/fake/temp/ma3_mcp_export.xml"] = '<GMA3 DataVersion="2.5.1.1"><Sequence Name="Song A"><DependencyExport Size="1"><Dependency><Preset Name="P"/></Dependency></DependencyExport><Cue No="1"/></Sequence></GMA3>'
  local r = tools.ma3_export.handler({ address = "Sequence 12" }, ctx)
  h.eq(r.class, "Sequence"); h.eq(r.name, "Song A"); h.eq(r.path, "/fake/temp/ma3_mcp_export.xml")
  h.eq(r.xml, '<GMA3 DataVersion="2.5.1.1"><Sequence Name="Song A"><Cue No="1"/></Sequence></GMA3>', "dependencies stripped by default")
  h.eq(r.raw_bytes, #files["/fake/temp/ma3_mcp_export.xml"]); h.eq(r.stripped_bytes, r.raw_bytes - r.bytes); h.truthy(r.stripped_bytes > 0)
  local rk = tools.ma3_export.handler({ address = "Sequence 12", strip_dependencies = false }, ctx)
  h.eq(rk.bytes, rk.raw_bytes); h.truthy(rk.xml:find("DependencyExport"))
  files["/fake/temp/ma3_mcp_export.xml"] = "<GMA3 DataVersion=\"2.5.1.1\"><Sequence Name=\"Song A\"/></GMA3>"
  r = tools.ma3_export.handler({ address = "Sequence 12" }, ctx)
  h.eq(fake.exported.addr, "Sequence 12"); h.eq(fake.exported.path, "/fake/temp"); h.eq(fake.exported.filename, "ma3_mcp_export.xml")
  h.truthy(r.xml:find("Song A")); h.eq(r.truncated, false); h.eq(r.bytes, #files["/fake/temp/ma3_mcp_export.xml"])
  local r2 = tools.ma3_export.handler({ address = "Sequence 12", max_bytes = 1024 }, ctx)
  h.eq(r2.truncated, false, "cap floors at 1024 and the file is smaller")
  local _, err = tools.ma3_export.handler({ address = "Page 1 Thru 3" }, ctx); h.truthy(err:find("unsafe"))
  local _, e2 = tools.ma3_export.handler({ address = "Sequence 999" }, ctx); h.truthy(e2:find("not found"))
  files["/fake/temp/ma3_mcp_export.xml"] = nil
  local _, e3 = tools.ma3_export.handler({ address = "Sequence 12" }, ctx); h.truthy(e3:find("no file appeared"))
  files["/fake/temp/ma3_mcp_export.xml"] = "<x/>"
end)

h.describe("ma3_sequences filters by range and name", function()
  local r = tools.ma3_sequences.handler({ from = 13, to = 20 }, ctx)
  h.eq(#r.rows, 3); h.eq(r.rows[1].no, 13); h.eq(r.rows[3].no, 20)
  local r2 = tools.ma3_sequences.handler({ name = "song" }, ctx)
  h.eq(#r2.rows, 3); h.eq(r2.rows[1].name, "Song A"); h.eq(r2.rows[3].name, "Old Song")
  local r3 = tools.ma3_sequences.handler({ name = "SONG", to = 14 }, ctx)
  h.eq(#r3.rows, 2)
end)

h.describe("ma3_pages one page and ma3_fixtures summary", function()
  local r = tools.ma3_pages.handler({ page = 3 }, ctx)
  h.eq(#r.rows, 1); h.eq(r.rows[1].name, "Busking")
  local r0 = tools.ma3_pages.handler({ page = 77 }, ctx); h.eq(#r0.rows, 0)
  local f = tools.ma3_fixtures.handler({ summary = true }, ctx)
  h.eq(f.rows[1].children, nil); h.eq(f.rows[1].child_count, 3); h.eq(f.rows[1].name, "Dimmer Rack")
  local f2 = tools.ma3_fixtures.handler({}, ctx)
  h.eq(#f2.rows[1].children, 3)
end)
