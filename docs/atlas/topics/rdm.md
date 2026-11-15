# RDM (Remote Device Management): what we know, how sure we are

Written 2026-11-08 from the MA help 2.5 (chapter "RDM", 1 page) and the release notes. Study pack:
`python3 tools/atlas/pack.py "RDM (Remote Device Management)" --terms rdm`.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

- RDM (ANSI E1.20) talks both ways with RDM-ready fixtures over the normal DMX line [D].
- **Two switches**: RDM on globally (one linked button in Network > Stations, Station Control, Live
  Patch > RDM, Connector Configuration) **and** each XLR port set to Mode RDM (turquoise). Art-Net
  rows have their own Enable RDM [D].
- **An RDM port changes the DMX output**: values are sent only on change plus a refresh every 500 ms,
  and the rate can fall to 1 Hz. MA advises RDM off on universes that do not need it [D].
- RDM Devices window (Add Window > Tools; also Live Patch > RDM): RDMFixtureTypes (one per
  manufacturer ID + device model ID + software ID, so a firmware difference makes a new type) and
  RDMPorts (fixtures found per physical port). Editable cells only where the fixture allows Set;
  supported parameters include device and lamp hours, lamp state, sensors (present, lowest, highest,
  recorded), software version labels, slot info, proxied devices. A fixture missing for three
  discoveries in a row turns red [D].
- Discovery cycle: new fixtures, still-present check, parameters and sensors, 1 s pause, repeat [D].
- **Match** an RDM fixture to a patched fixture (fixture cell in the RDM window, or Live Patch > RDM;
  Unmatch / Clear) [D]. IDENTIFY_DEVICE flashes a fixture to find it [D].
- Proxies (wireless DMX links) count their own devices; fixtures with built-in wireless receivers
  are not discovered [D].

## Plugin access today, and gaps

- Not read by any tool; Aaron's rig use of RDM unknown [?]. Device hours and sensor values would be
  useful maintenance reads, onPC first (onPC has no XLR ports of its own, so the console or a node is
  where RDM data actually exists).
