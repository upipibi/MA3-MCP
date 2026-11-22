local addr = require("addr")
local h = require("helpers")

h.describe("addr_accepts_quoted_names", function()
  h.truthy(addr.check('Sequence "Song 2 (Key of D)"'))
  h.truthy(addr.check("Fixture 101.3"))
  h.truthy(addr.check("Page 2.5"))
  h.truthy(addr.check("Sequence 1 Thru 5"), "ranges elsewhere are fine")
  h.truthy(addr.check("Sequence 12 Cue 3 Part 0"))
  h.truthy(addr.check("DataPool 1 Preset 4.1"))
  h.truthy(addr.check('Group "Spots L"'))
end)

h.describe("addr refuses page and executor ranges", function()
  local ok, why = addr.check("Page 1.180 Thru 1.190"); h.eq(ok, false); h.eq(why, "[unsafe-range]")
  h.eq(select(2, addr.check("Executor *")), "[unsafe-range]")
  h.eq(select(2, addr.check("Page 1.1 + 1.2")), "[unsafe-range]")
  h.eq(select(2, addr.check("page 1 thru 3")), "[unsafe-range]", "case insensitive")
  h.eq(select(2, addr.check("Page *")), "[unsafe-range]")
  h.truthy(addr.check('Sequence "Page Thru"'), "keywords inside quotes do not count")
end)

h.describe("addr refuses empty and control characters", function()
  h.eq(addr.check(""), false)
  h.eq(addr.check("   "), false)
  h.eq(addr.check("Sequence 1\n"), false)
  h.eq(addr.check(nil), false)
end)

h.describe("addr.quote", function()
  h.eq(addr.quote('Song "Live"'), '"Song Live"')
  h.eq(addr.quote("Plain"), '"Plain"')
end)

-- 2026-11-08 the console froze, and 2026-11-21 onPC froze in the same census at the same call:
-- ma3_object {address = "Geometry "}. The geometry collection of a fixture type reports that as its
-- address, and resolving it never returns.
h.describe("addr refuses the address that froze the console: a bare Geometry keyword", function()
  for _, a in ipairs({ "Geometry ", "Geometry", "geometry 1", "  Geometry 3.2", "GEOMETRY" }) do
    local ok, why = addr.check(a)
    h.eq(ok, false, a); h.truthy(why:find("[unsafe-address]", 1, true), a)
  end
  h.truthy(addr.check('Sequence "Geometry"'), "a name in quotes is not the keyword")
  h.truthy(addr.check("FixtureType 1.5"), "the same object by its path is fine")
end)

h.describe("addr.first_keyword and addr.proven: the keywords an address may start with on a console", function()
  h.eq(addr.first_keyword("  Sequence 12 Cue 3"), "sequence")
  h.eq(addr.first_keyword("Root 14.9.9.5"), "root")
  h.eq(addr.first_keyword('"quoted"'), nil)
  for _, a in ipairs({ "Sequence 12", "Fixture 611", "Page 4.106", "Layout 1.199", "DMXUniverse 7", "Root 14.9", "UserProfile", "Master 2", "Timecode 14", "DataPool 1 Preset 4.1", "Group " }) do
    h.eq(addr.proven(a), true, a)
  end
  for _, a in ipairs({ "Geometry ", "DMXMode ", "Wheel 2", "SomethingNew 1" }) do h.eq(addr.proven(a), false, a) end
end)

h.describe("addr refuses the Geometry keyword anywhere in an address, and its shortened forms", function()
  for _, a in ipairs({ "FixtureType 1 Geometry", "FixtureType 1 Geometry 2", "Geom ", "geo 1", "Fixture 1 geomet" }) do
    local ok, why = addr.check(a)
    h.eq(ok, false, a); h.truthy(why:find("[unsafe-address]", 1, true), a)
  end
  h.truthy(addr.check('Group "Geometry Lights"'), "inside a quoted name it is only a name")
  h.truthy(addr.check("Gel 3"), "another keyword that starts with the same two letters")
  h.truthy(addr.check("Group 5"))
end)
