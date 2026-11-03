local console = require("console")
local show = require("tools.show")
local fake_console = require("fake_console")
local fake_fs = require("fake_fs")
local h = require("helpers")

-- ma3_backup saves the show under its own name (no dialog), waits for the file to be
-- rewritten, then copies the file to the backup name. No SaveShow "<new name>" ever.
local function setup(show_name)
  local fake = fake_console.new()
  fake.by_addr["Root 14.5"].props.SHOWFILE.v = show_name or "TestShow"
  local c = console.new(fake.api)
  local fs = fake_fs.new()
  fs.files["/fake/shows/" .. (show_name or "TestShow") .. ".show"] = "SHOWBYTES"
  fake.dirlist = { { name = (show_name or "TestShow") .. ".show", size = 9, time = 100 } }
  -- the fake console "saves" when CmdIndirect runs: bump the file time
  local real_indirect = fake.api.CmdIndirect
  fake.api.CmdIndirect = function(text) real_indirect(text); fake.dirlist[1].time = fake.dirlist[1].time + 1 end
  local tools, ctx = {}, { budget_ms = 10000, backups = {}, now_date = function() return "1103_1420" end, fs = fs }
  show.register(tools, c, ctx)
  return fake, tools, ctx, fs
end

h.describe("ma3_backup saves under the current name and copies the file", function()
  local fake, tools, ctx, fs = setup("A very long show name here")
  local r = tools.ma3_backup.handler({}, ctx)
  h.truthy(r, "backup succeeded")
  h.eq(r.stem, "A very long show"); h.eq(r.backup, "A very long show_mcp_1103_1420"); h.eq(r.current, "A very long show name here")
  h.eq(#fake.indirect, 1); h.eq(fake.indirect[1], 'SaveShow "A very long show name here"', "only a plain save, never a rename")
  h.eq(fs.files["/fake/shows/A very long show_mcp_1103_1420.show"], "SHOWBYTES", "copy made")
  h.eq(#r.backup <= 31, true)
  h.eq(ctx.backups[1], r.backup); h.eq(ctx.last_backup, r.backup)
  h.eq(#fake.cmds, 0, "never deletes or renames through Cmd")
end)

h.describe("ma3_backup waits for the save and times out", function()
  local fake, tools, ctx = setup("Show")
  fake.api.CmdIndirect = function(text) table.insert(fake.indirect, text) end  -- the save never lands
  fake.slow = true; ctx.budget_ms = 5
  local r, err = tools.ma3_backup.handler({}, ctx)
  h.eq(r, nil); h.truthy(err:find("not rewritten"), err)
  h.truthy(fake.yields > 0, "polled across yields")
end)

h.describe("ma3_backup keeps five names and refuses odd show names", function()
  local fake, tools, ctx, fs = setup("Show")
  for i = 1, 7 do
    ctx.now_date = function() return "1103_14" .. (10 + i) end
    tools.ma3_backup.handler({}, ctx)
  end
  h.eq(#ctx.backups, 5); h.eq(ctx.backups[1], "Show_mcp_1103_1417"); h.eq(ctx.backups[5], "Show_mcp_1103_1413")
  local _, err = setup("")
  local r, e = _ and nil, nil
  local fake2, tools2, ctx2 = setup("")
  r, e = tools2.ma3_backup.handler({}, ctx2)
  h.eq(r, nil); h.truthy(e:find("show name"))
  local fake3, tools3, ctx3 = setup('Bad "Quote"')
  r, e = tools3.ma3_backup.handler({}, ctx3)
  h.eq(r, nil); h.truthy(e:find("quote"), e)
end)

h.describe("ma3_backup fails cleanly when the copy cannot be written", function()
  local fake, tools, ctx, fs = setup("Show")
  fs.files.readonly = true
  local r, err = tools.ma3_backup.handler({}, ctx)
  h.eq(r, nil); h.truthy(err:find("copy"), err)
end)

h.describe("ma3_save", function()
  local fake, tools, ctx = setup("Show")
  local r = tools.ma3_save.handler({}, ctx)
  h.eq(r.saved, "Show"); h.eq(fake.indirect[1], 'SaveShow "Show"')
end)
