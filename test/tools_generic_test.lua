local console = require("console")
local generic = require("tools.generic")
local log = require("log")
local fake_console = require("fake_console")
local h = require("helpers")

local fake = fake_console.new()
local c = console.new(fake.api)
local tools = {}
local ctx = { budget_ms = 10000, lua_enabled = function() return false end, plugin_version = "0.1.0", started_at = 0,
  request_count = 3, last_backup = nil, log = log.new(5), address = "127.0.0.1:9800" }
generic.register(tools, c, ctx)

h.describe("ma3_object", function()
  local r = tools.ma3_object.handler({ address = "Sequence 12" }, ctx)
  h.eq(r.class, "Sequence"); h.eq(r.name, "Song A"); h.eq(r.address, "Sequence 12"); h.eq(r.child_count, 6)
  h.eq(r.properties.NOTE, "walk-in"); h.eq(r.properties.NO, 12); h.eq(r.properties.TAGS, "Song:0")
  h.eq(r.properties.APPEARANCE, nil, "empty props are omitted")
  h.eq(r.schema, nil)
  local r2 = tools.ma3_object.handler({ address = "Sequence 12", schema = true }, ctx)
  h.eq(r2.schema[1].name, "NAME"); h.eq(r2.schema[1].type, "String"); h.eq(#r2.schema, 5)
  local _, err = tools.ma3_object.handler({ address = "Page 1 Thru 2" }, ctx); h.truthy(err:find("^%[unsafe%-range%]"))
  local _, e2 = tools.ma3_object.handler({ address = "Sequence 999" }, ctx); h.truthy(e2:find("not found"))
  local _, e3 = tools.ma3_object.handler({}, ctx); h.truthy(e3:find("address"))
end)

h.describe("ma3_object renders handle values as addresses", function()
  local r = tools.ma3_object.handler({ address = "Sequence 12 Cue 1" }, ctx)
  h.eq(r.properties.NAME, "Cue 1")
  local mn = tools.ma3_object.handler({ address = "Root 14.5" }, ctx)
  h.eq(mn.properties.SHOWFILE, "TestShow")
end)

h.describe("ma3_children pages", function()
  local r = tools.ma3_children.handler({ address = "Sequence 12", limit = 2 }, ctx)
  h.eq(#r.children, 2); h.eq(r.next_offset, 2); h.eq(r.total, 6)
  h.eq(r.children[1].class, "Cue"); h.eq(r.children[1].name, "CueZero"); h.eq(r.children[1].index, 1); h.eq(r.children[2].address, "Sequence 12 OffCue")
  local r2 = tools.ma3_children.handler({ address = "Sequence 12", offset = 2, limit = 10 }, ctx)
  h.eq(#r2.children, 4); h.eq(r2.next_offset, nil); h.eq(r2.children[1].name, "Cue 1")
  local r3 = tools.ma3_children.handler({ address = "Sequence 12", fields = { "NOTE", "NO" } }, ctx)
  h.eq(r3.children[3].properties.NO, 1000)
end)

h.describe("ma3_dump", function()
  local r = tools.ma3_dump.handler({ address = "Sequence 12", depth = 1 }, ctx)
  h.truthy(r.text:find("Sequence 12"), "root line"); h.truthy(r.text:find("NOTE = walk%-in")); h.truthy(r.text:find("Cue 4")); h.truthy(r.text:find("CueZero"))
  local r0 = tools.ma3_dump.handler({ address = "Sequence 12", depth = 0 }, ctx)
  h.truthy(not r0.text:find("Cue 4"), "depth 0 has no children")
end)

h.describe("ma3_set reads back", function()
  local r = tools.ma3_set.handler({ address = "Sequence 12", property = "Name", value = "Song B" }, ctx)
  h.eq(r.before, "Song A"); h.eq(r.after, "Song B")
  local _, err = tools.ma3_set.handler({ address = "Sequence 12", property = "Tags", value = "x" }, ctx); h.truthy(err:find("Assign Tag"))
  local _, e2 = tools.ma3_set.handler({ address = "Sequence 12", property = "Nope", value = "x" }, ctx); h.truthy(e2:find("no property"))
  tools.ma3_set.handler({ address = "Sequence 12", property = "Name", value = "Song A" }, ctx)
end)

h.describe("ma3_command", function()
  fake.cmd_result = "OK"
  local r = tools.ma3_command.handler({ command = 'Label Sequence 12 "Song C"' }, ctx)
  h.eq(r.result, "OK"); h.eq(fake.last_cmd, 'Label Sequence 12 "Song C"'); h.eq(r.noconfirmation_added, false); h.eq(r.command, fake.last_cmd)
  local r2 = tools.ma3_command.handler({ command = "Delete Sequence 12" }, ctx)
  h.eq(fake.last_cmd, "Delete Sequence 12 /NoConfirmation"); h.eq(r2.noconfirmation_added, true)
  tools.ma3_command.handler({ command = "delete Sequence 12 /NoConfirmation" }, ctx)
  h.eq(fake.last_cmd, "delete Sequence 12 /NoConfirmation", "not doubled")
  tools.ma3_command.handler({ command = "Store Group 7 \"Spots\"" }, ctx)
  h.eq(fake.last_cmd, 'Store Group 7 "Spots" /NoConfirmation')
  tools.ma3_command.handler({ command = "Assign Sequence 12 At Page 3.201" }, ctx)
  h.eq(fake.last_cmd, "Assign Sequence 12 At Page 3.201 /NoConfirmation")
  local _, err = tools.ma3_command.handler({ command = "" }, ctx); h.truthy(err)
  fake.cmd_result = "Object not found"
  local r3 = tools.ma3_command.handler({ command = "Sequence 999 Cue 1" }, ctx); h.eq(r3.result, "Object not found")
  fake.cmd_result = "OK"
end)

h.describe("ma3_command undo group", function()
  local r = tools.ma3_command.handler({ command = "Label Sequence 12 \"X\"", undo_group = "job1" }, ctx)
  h.eq(fake.last_created_undo.name, "job1"); h.eq(fake.last_undo, fake.last_created_undo); h.eq(r.undo_group, "job1")
  local first = fake.last_created_undo
  tools.ma3_command.handler({ command = "Label Sequence 12 \"Y\"", undo_group = "job1" }, ctx)
  h.eq(fake.last_undo, first, "same group reused")
  local rc = tools.ma3_undo_close.handler({ undo_group = "job1" }, ctx)
  h.eq(fake.closed_undo, first); h.eq(rc.closed, "job1")
  local _, err = tools.ma3_undo_close.handler({ undo_group = "nope" }, ctx); h.truthy(err)
end)

h.describe("ma3_status", function()
  local r = tools.ma3_status.handler({}, ctx)
  h.eq(r.show, "TestShow"); h.eq(r.lua_enabled, false); h.eq(r.version, "2.5.1.1"); h.eq(r.host_type, "onPC")
  h.eq(r.plugin_version, "0.1.0"); h.eq(r.requests, 3); h.eq(r.address, "127.0.0.1:9800"); h.eq(r.log_lines, nil)
  ctx.log:add("x"); ctx.log:add("y %d", 2)
  local r2 = tools.ma3_status.handler({ log = true }, ctx)
  h.eq(r2.log_lines[1], "x"); h.eq(r2.log_lines[2], "y 2")
end)

h.describe("log ring buffer", function()
  local l = log.new(3)
  for i = 1, 5 do l:add("l%d", i) end
  local lines = l:lines(); h.eq(#lines, 3); h.eq(lines[1], "l3"); h.eq(lines[3], "l5")
end)

h.describe("ma3_command refuses Lua and show-file commands", function()
  local before = #fake.cmds
  for _, cmd in ipairs({ 'Lua "os.remove(1)"', "lua 'x'", 'LuaFile "x.lua"', 'SaveShow "x"', "SaveShow", 'LoadShow "y"', "NewShow" }) do
    local r, err = tools.ma3_command.handler({ command = cmd }, ctx)
    h.eq(r, nil, cmd); h.truthy(err and (err:find("ma3_lua") or err:find("ma3_save") or err:find("refused")), cmd .. ": " .. tostring(err))
  end
  h.eq(#fake.cmds, before, "nothing reached the console")
  h.truthy(tools.ma3_command.handler({ command = "Call Plugin 1" }, ctx), "other plugins may be called")
  local r = tools.ma3_command.handler({ command = "Label Sequence 12 \"Luanne\"" }, ctx)
  h.truthy(r, "a name containing 'Lua' is fine")
  tools.ma3_command.handler({ command = "Copy Sequence 12 At 13" }, ctx)
  h.eq(fake.last_cmd, "Copy Sequence 12 At 13 /NoConfirmation", "copy onto a slot can ask to overwrite")
end)

h.describe("ma3_commands runs a batch in order in one undo group", function()
  fake.cmd_result = "OK"
  local before = #fake.cmds
  local r = tools.ma3_commands.handler({ commands = { 'Store Sequence 1 "A"', 'Label Sequence 1 "B"', "Delete Sequence 2" }, undo_group = "batch1" }, ctx)
  h.eq(r.sent, 3); h.eq(r.total, 3); h.eq(r.stopped_at, nil); h.eq(#r.results, 3)
  h.eq(fake.cmds[before + 1], 'Store Sequence 1 "A" /NoConfirmation'); h.eq(fake.cmds[before + 2], 'Label Sequence 1 "B"'); h.eq(fake.cmds[before + 3], "Delete Sequence 2 /NoConfirmation")
  h.eq(r.results[1].noconfirmation_added, true); h.eq(r.results[2].noconfirmation_added, false); h.eq(r.results[3].result, "OK")
  h.eq(fake.last_created_undo.name, "batch1"); h.eq(fake.last_undo, fake.last_created_undo); h.eq(r.undo_closed, false)
  h.truthy(ctx.undos.batch1, "group stays open")
  local r2 = tools.ma3_commands.handler({ commands = { "Label Sequence 1 \"C\"" }, undo_group = "batch1", close_undo = true }, ctx)
  h.eq(r2.undo_closed, true); h.eq(fake.closed_undo.name, "batch1"); h.eq(ctx.undos.batch1, nil)
end)

h.describe("ma3_commands validates everything before sending anything", function()
  local before = #fake.cmds
  local r, err = tools.ma3_commands.handler({ commands = { "Label Sequence 1 \"ok\"", 'Lua "x"', "Label Sequence 2 \"ok\"" } }, ctx)
  h.eq(r, nil); h.truthy(err:find("command 2 rejected")); h.truthy(err:find("ma3_lua"))
  h.eq(#fake.cmds, before, "nothing reached the console")
  local _, e2 = tools.ma3_commands.handler({ commands = {} }, ctx); h.truthy(e2:find("non%-empty"))
  local _, e3 = tools.ma3_commands.handler({}, ctx); h.truthy(e3)
  local big = {} for i = 1, 201 do big[i] = "Echo " .. i end
  local _, e4 = tools.ma3_commands.handler({ commands = big }, ctx); h.truthy(e4:find("200"))
end)

h.describe("ma3_commands stops at the first non-OK result unless told not to", function()
  local n = 0
  local saved = fake.api.Cmd
  fake.api.Cmd = function(text, undo) n = n + 1; table.insert(fake.cmds, text); fake.last_cmd = text; return n == 2 and "Object not found" or "OK" end
  local r = tools.ma3_commands.handler({ commands = { "Echo a", "Echo b", "Echo c" } }, ctx)
  h.eq(r.sent, 2); h.eq(r.stopped_at, 2); h.eq(#r.results, 2); h.eq(r.results[2].result, "Object not found")
  n = 0
  local r2 = tools.ma3_commands.handler({ commands = { "Echo a", "Echo b", "Echo c" }, stop_on_error = false }, ctx)
  h.eq(r2.sent, 3); h.eq(r2.stopped_at, nil); h.eq(r2.results[2].result, "Object not found"); h.eq(r2.results[3].result, "OK")
  n = 0
  fake.api.Cmd = function(text) n = n + 1; if n == 1 then error("boom") end return "OK" end
  local r3 = tools.ma3_commands.handler({ commands = { "Echo a", "Echo b" } }, ctx)
  h.eq(r3.stopped_at, 1); h.truthy(r3.results[1].result:find("command failed: .*boom"))
  fake.api.Cmd = saved
end)

h.describe("ma3_commands yields every 10 commands", function()
  local y0 = fake.yields
  local many = {} for i = 1, 25 do many[i] = "Echo " .. i end
  local r = tools.ma3_commands.handler({ commands = many }, ctx)
  h.eq(r.sent, 25); h.eq(fake.yields - y0, 2)
end)
