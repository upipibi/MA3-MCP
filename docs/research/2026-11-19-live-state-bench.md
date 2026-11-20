# Live state: what to prove on onPC, in order (2026-11-19)

Aaron, 2026-11-19: "the MCP NEEDS TO BE ABLE TO SEE EVERYTHING". The trigger: ladders 7 and 8 show
colours with an empty programmer, and the plugin could not say what is running, what the fixtures
output, what their stored defaults are, or what comes in over the network. Every one of those was
handed to Aaron as a desk check. Each is a read the plugin should have.

Rules that still hold (project `CLAUDE.md`, "Console safety"): nothing unproven runs on the console.
Each read below is proven on onPC first (Aaron starts onPC, Standalone, plugin on; calls go through
`ma3_lua` with `MA3_MCP_URL` / `MA3_MCP_PIN`), then becomes a tool with tests, then goes to the desk.
A read proven on onPC is not proof for console hardware; on the desk each new tool is first called
once, on one object, outside a service, with the journal on.

| # | Question the tool answers | Tool | Calls to prove on onPC | State |
| --- | --- | --- | --- | --- |
| 0 | What is running right now? | `ma3_playbacks` | `seq:HasActivePlayback()`, `seq:CurrentChild()` | built in alpha.7; calls proven on the console by Cue Display |
| 0b | Does an input port, a parked channel or the tester drive this universe? Which station's port? | `ma3_universes`, `ma3_ports` | property reads on `DmxUniverse` (console) and `DeviceConfigurations > OutputStations` (onPC in the console's session) | built in alpha.7; solved ladders 7 and 8 (XLR G = In on universe 7) |
| 1 | What are this fixture's stored Default / Highlight / Lowlight values, DMX addresses and curve? | `ma3_parameters {fixture}` | `GetRTChannels(handle, true)` (handles into `Root 14.9.9`), then the entry's properties; fall back to the proven by-index read | to bench |
| 2 | What does the console send on this universe / this fixture right now? | `ma3_dmx {universe}` / `{fixture}` | `GetDMXUniverse(n)`, `GetDMXValue(addr, universe)` | to bench |
| 3 | What does the network put in and take out (sACN, Art-Net rows, sources seen)? | `ma3_network_dmx` | `DeviceConfiguration().DMXProtocols.sACN` (`sACNDataCollect`, `sACNDiscoveryCollect`), `.ArtNet.ArtNetDataCollect` (found in MA's `setupsacn.lua` / `setupartnet.lua`); then a guard rule for that branch | to bench |
| 4 | What is in the programmer, for every user? | `ma3_programmer` | `Programmer()`, `ProgrammerPart()`, the user profiles' programmers; `GetUIChannels` | to bench |
| 5 | Which cue, programmer, park or tester owns this attribute's value? | `ma3_why {fixture}` | the CueAbs layer by API (`GetRTChannel(i).info`), parked flag, tester flag; joins 0-4 | to bench |
| 6 | Selection, masters, session and users, messages | `ma3_selection`, `ma3_masters`, `ma3_session`, `ma3_messages` | `Selection()`, `SelectionFirst/Next`, `MasterPool()`, session objects, Message Center route | to bench |

After the bench, each proven branch gets a guard rule with the date and the evidence, as the guard's
own comment requires. The census that finds the object that froze the desk on 2026-11-08 belongs in
the same onPC session: until it is found, the guard stays an allow-list.

## Ladders 7 and 8: what each row would have answered

Row 0: nothing but the hazer runs (answered through Cue Display). Row 1: whether a stored Default
puts colours on those 100 LEDs (the leading explanation, unread). Row 2: what universe 7 carries.
Row 3: whether another source feeds universe 7. Row 4: whether another user's programmer holds them.
