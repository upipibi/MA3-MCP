local console = require("console")
local show = require("tools.show")
local fake_console = require("fake_console")
local h = require("helpers")

local function setup(show_name)
  local fake = fake_console.new()
  fake.by_addr["Root 14.5"].props.SHOWFILE.v = show_name or "TestShow"
  local c = console.new(fake.api)
  local tools, ctx = {}, { budget_ms = 10000, backups = {}, now_date = function() return "1103_1420" end }
  show.register(tools, c, ctx)
  return fake, tools, ctx
end

h.describe("ma3_backup name uses a 16-character stem and the date", function()
  local fake, tools, ctx = setup("A very long show name here")
  fake.dirlist = { { name = "A very long show_mcp_1103_1420.show", size = 1, time = 1 } }
  local r = tools.ma3_backup.handler({}, ctx)
  h.eq(r.stem, "A very long show"); h.eq(r.backup, "A very long show_mcp_1103_1420"); h.eq(r.current, "A very long show name here")
  h.eq(fake.indirect[1], 'SaveShow "A very long show_mcp_1103_1420"')
  h.eq(fake.indirect[2], 'SaveShow "A very long show name here"')
  h.eq(#r.backup <= 31, true)
  h.eq(ctx.backups[1], "A very long show_mcp_1103_1420"); h.eq(ctx.last_backup, "A very long show_mcp_1103_1420")
end)

h.describe("ma3_backup waits for the file and times out", function()
  local fake, tools, ctx = setup("Show")
  fake.dirlist = {}
  fake.slow = true; ctx.budget_ms = 5
  local r, err = tools.ma3_backup.handler({}, ctx)
  h.eq(r, nil); h.truthy(err:find("not listed"), err)
  h.truthy(fake.yields > 0, "polled across yields")
end)

h.describe("ma3_backup keeps five names", function()
  local fake, tools, ctx = setup("Show")
  for i = 1, 7 do
    ctx.now_date = function() return "1103_14" .. (10 + i) end
    fake.dirlist = { { name = "Show_mcp_1103_14" .. (10 + i) .. ".show" } }
    tools.ma3_backup.handler({}, ctx)
  end
  h.eq(#ctx.backups, 5); h.eq(ctx.backups[1], "Show_mcp_1103_1417"); h.eq(ctx.backups[5], "Show_mcp_1103_1413")
  h.eq(#fake.cmds, 0, "never deletes a show file")
end)

h.describe("ma3_backup refuses without a show name", function()
  local fake, tools, ctx = setup("")
  local r, err = tools.ma3_backup.handler({}, ctx)
  h.eq(r, nil); h.truthy(err:find("show name"))
end)

h.describe("ma3_save", function()
  local fake, tools, ctx = setup("Show")
  local r = tools.ma3_save.handler({}, ctx)
  h.eq(r.saved, "Show"); h.eq(fake.indirect[1], 'SaveShow "Show"')
end)
