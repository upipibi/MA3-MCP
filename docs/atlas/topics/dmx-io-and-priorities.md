# DMX in and out, Art-Net, sACN, and the output priority ladder

Written 2026-11-08 from the MA help 2.5 (chapter "DMX In and Out", 7 pages; keyword pages `Freeze`,
`OSC`, `Park`), MA's DMX universe system tests (label, move, park), and the release notes 2.2 to
2.5.1.1. Study pack: `python3 tools/atlas/pack.py "DMX In and Out" --terms dmx,artnet,sacn,universe`.
Patch-side universes and the DMX sheet are in `patch.md`; curves in `dmx-curves.md`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

**Every setting in this chapter changes live output or the network at once.** Nothing here is a plugin
job without Aaron's explicit ask; most of it is device configuration that lives in the station, not
the show (below).

## Refresh rate [D]

Whole universes are sent; 30 Hz maximum and default, 1 Hz minimum. XLR ports set to Out stay at a
constant 30 Hz; RDM ports, Art-Net and sACN drop to as low as 1 Hz on universes that are not
changing.

## Connector configuration (`Menu "ConnectorConfig"`) [D]

- Lists every device (Console, onPC, PU, NetworkNode; device index numbers can change, so refer to
  devices by name), with a Devices in Session count (red when one is missing).
- Each XLR port: **Mode** Off, Out (default), RDM (DMX plus RDM, variable rate), In (merged into the
  universe); **Failure Mode** (how long the last values hold when the software stops); **XLR** = the
  universe (1-1,024); for inputs **Merge** Off, Prio, HTP, LowTP and **Prio** Super, Prog, Highest,
  High, LTP, Low, Lowest.
- **Port configuration is stored in the device, not the show file**; it is kept when the device joins
  a session until changed there. Save / Load Device Configuration (all devices plus DMX protocol
  settings in one file), Export / Import for single devices. Add Present, Remove Absent. onPC has three
  ports by default (a command wing); fader wings and DMX-keys can be added. `Menu "ConnectorView"`
  shows the connector map on the letterbox screens.

## Ethernet DMX (`Menu "ArtNet"`, `Menu "sACN"`) [D]

- **Only the session master outputs network DMX**; a station alone (IdleMaster) outputs only with
  Send Art-Net / sACN If IdleMaster on.
- Shared settings: Preferred IP and Interface (Auto picks the interface matching the preferred
  range), Enable Output, Enable Input, Setup Mode (node configuration only), Output Delay 0-30 ms.
- Art-Net 4: Broadcast Threshold (Auto mode unicasts until more than 5 receivers subscribe to a
  universe), ArtPollRate; Data rows: Enabled (default **No**), Mode (Broadcast, Unicast, Auto, Input),
  Destination IP, Subscribed Nodes, Local Universe, Amount, Net (0-127), Sub-Net and Universe (0-15),
  Art-Net Absolute, Packet Delay, Merge Mode, Input Priority, Enable RDM. Nodes tab edits node names,
  IPs and ports where the node allows it.
- sACN: Data rows Enabled (default **Yes**), Mode (Output Multicast, Output Unicast, Input Multicast
  up to 20 universes, Input Unicast), Local Universe, Amount, Priority 0-200 (default 100), **Preview
  Only** (for visualisers), TTL (default 8), Delay, Merge Mode, Input Priority (incoming sACN
  priorities are ignored; this one is used). Discovery tab lists transmitting sources.
- Total network DMX input: 128 universes (Art-Net and sACN together).
- Row text: red = invalid or disabled, flashing green = sending, orange = receiving.

## The output priority ladder (why a light does what it does) [D]

From strongest to weakest:

1. External inputs (sACN, Art-Net, DMX In, PSN), by their merge mode and input priority.
2. **DMX Tester** (beats programmer, playbacks and park; stays until cleared).
3. **Parked** values (unaffected by Highlight, Lowlight, Solo; layouts still show the unparked value).
4. Playbacks at **Super** priority.
5. Programmer with **Freeze** on (beats every playback except Super).
6. Playbacks: Swap, Highest, HTP, High, LTP, Low, Lowest.
7. Programmer with Freeze off (about the level of a normal playback).

Then output modifiers: Grand Master, World Masters, Group Masters (Negative, Positive and Scaling beat
Highlight), and selection overrides: Highlight, Lowlight, Solo (they beat playbacks, Super included,
but not parked values). Merge: HTP for dimmers, LTP for the rest.

A read-only "why is this fixture at this value" tool would walk this ladder: tester, park, inputs,
then the CueAbs layer (which sequence and cue owns the attribute) [?: see `operate-fixtures.md`].

## Plugin access today, and gaps

- No tool reads connector or protocol configuration, parked channels, or the tester [?]. These are
  read candidates for a diagnosis tool; writes stay manual.
- **Read first when a fixture does something by itself** [C, 2026-11-19]: `ma3_object "DMXUniverse <n>"`
  shows `PORTIN` / `PORTOUT` / `PORTRDM` (a station's physical port is mapped to the universe), `USED`,
  `COARSEPARAMS`, `PARKEDCOUNT`, `TESTERCOUNT`, `GRANTED`. The 2026-11-19 case: ladders 7 and 8 lit in
  colours with an empty programmer because the console's XLR G is an input on universe 7 (LTP) and they
  were patched there.
- Port setup per station [O, read on an onPC inside the console's session, which lists every station]:
  `Root 22.1.<type>.<station>.1` (`OutputConfiguration`): `MODEA..G` (Out / In), `XLRA..G` (universe),
  `MERGEx`, `PRIOx`, `FAILUREMODEx`. The console guard still refuses `Root 22` on a console.
- Where the protocol settings live [M, found 2026-11-19 in `lib_menus_node/setupsacn.lua` and
  `setupartnet.lua`]: `DeviceConfiguration().DMXProtocols.sACN` (`.sACNDataCollect` = the Data rows,
  `.sACNDiscoveryCollect` = sources seen on the network, `.PreferredIP`) and
  `DeviceConfiguration().DMXProtocols.ArtNet` (`.ArtNetDataCollect`). Device configuration, not show
  data, so the console guard refuses it; read it on onPC first, then allow-list it.
