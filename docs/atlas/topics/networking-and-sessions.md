# Networking, sessions, web remote: what we know, how sure we are, how to stay safe

Written 2026-11-08 from the MA help 2.5 (chapter "Networking", 17 pages; keyword pages `Invite`,
`Dismiss`, `LeaveSession`, `JoinSession`, `Disconnect`, `Reconnect`, `RemoteCommand`,
`NetworkSpeedTest`, `ChangeMulticastBase`, `Reboot`, `Restart`, `ShutDown`), and the release notes
2.2 to 2.5.1.1. Study pack: `python3 tools/atlas/pack.py "Networking" --terms network,session,station`.
No console or network addresses of Aaron's go in this page (public repo).

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## The rule this chapter adds

**The onPC on Aaron's Mac must never join the console's session.** It runs the same streaming
version (the first three numbers, 2.5.1) [C: both hosts], every new show carries the same default
session key [D], and joining or being invited moves show files between stations:

- A joining station with **lower or equal** priority downloads the session's show (the bench show is
  replaced by the live one, and from then on every bench experiment is live) [D].
- A joining or invited station with **higher** priority **uploads its show to every station**, the
  console included: the live show is replaced [D].
- A station that rejoins after a disconnect gets the **Session Data Merge** pop-up (Merge All Data,
  Keep Only Master Data, Keep My Show File, Cancel); with no answer the default option is applied
  after **60 s** [D]. "Keep My Show File" deletes unsaved data on the other stations.
- Stations listed in a show's network list are **auto-invited** when they come back online if their
  Invite switch is on [D].

Before any onPC bench: check in onPC's Network menu that it is Standalone or in its own session (own
session name), never "Connected" to the console's session [D: status colours]. The plugin refuses
`JoinSession`, `LeaveSession`, `Invite`, `Dismiss`, `Disconnect`, `Reconnect` and the rest (alpha.6)
[C: code, tests].

## Session rules [D]

- Stations (consoles, onPC, replay unit) join sessions identified by **session name + location +
  key**; one master per session (IdleMaster alone, GlobalMaster with others); a unique session index;
  up to 32 sessions per network, one fully loaded session (262,144 parameters) in total.
- Same user on two stations = full tracking; different users = multi-user.
- **DMX network protocols are output by the master only.** Latency must stay under 2 ms; the session
  timeout is 5 s.
- Master priority: Never, Very Low, Low, Normal, High; ties go to the lowest slot number. Only a
  station not in a session can change its HostName, Session, Location or Master Priority.
- Network menu (`Menu "Network"`, or the network icon on the command line): HostName, Session,
  Location, Multicast Base (Default 236.4.1.x or Alternative 239.4.1.x; changing it needs every
  device to match and cannot be oopsed), MA-Net Interface (Auto prefers a 192.168 address, then
  172.16, then 10.x), World Server, Key, Master Priority, Invite, Web Remote, Remote HID, RDM, network
  on/off. Stations tab: type, IP, session, show file, status, version, online time, slot, flow
  control level. Filters: All, My Session, Not My Session, Wrong Version, My Location.
- Keys (Network > Keys): hashes from a seed; MAnet, Remote Call and Terminal permissions per key;
  locked by default; export / import by drive.
- Station Control: Invite, Web Remote, Remote HID, **SFTP Access**, Send Art-Net / sACN If
  IdleMaster, USB Network; session-wide DSCP, Data Merge Default Mode and Timeout (Unlimited, or 0 to
  skip the pop-up), TTL, input enables for DC, MIDI, DMX remotes and OSC.

## Interfaces [D]

- Consoles have three rear Ethernet ports (Con1-3); interfaces named imx6 are internal (never touch).
  IP, mask, gateway, DHCP and DNS are edited on the console (on onPC, in the operating system);
  192.168.33.x is not allowed on Con1-3. Changes apply without a reboot.
- USB Network: internet for the world server through a tethered phone.
- WiFi only for web remotes, never for a session; access points in their own VLAN.

## Web remote [D]

- Any browser at the station's address on port 8080 (or the QR code in `Menu "WebremoteView"`); up
  to five devices on onPC, two on a console; resolution limit per station (consoles 1440p).
- Admin, Guest and 3D users cannot log in; a new show has a **Remote** user (`LogIn "Remote"`, in
  quotes because Remote is a keyword). A URL can carry user and password (`?user=...&password=...`).
- **Linked command lines**: a remote's command line can mirror the host's for users on the same
  profile; commands run on the host station.

## Protocol ports (MA defaults) [D]

| Protocol | Transport, port |
| --- | --- |
| MA-Net3 session | UDP multicast 30020 (236.4.1.0-4 for session 1, +4 per index); TCP 30022+ for bulk transfers |
| MA world server | TCP 30021 |
| Web remote | TCP 80 (HTTP), 8080 (websocket) |
| Art-Net | UDP broadcast / TCP 6454 (unicast until more than 5 receivers per universe) |
| sACN | UDP multicast 239.255.x.y / TCP 5568 |
| PSN | UDP multicast 236.10.10.10:65565 |
| OSC | TCP/UDP 8000 (configurable) |
| NDI | mDNS 5353, TCP 5959, 5960-7960+ |
| MVR-xchange | mDNS 5353, TCP 42424 |
| SFTP | TCP 22 |
| SNMP | 161, 162 (v1, v2c, public) |

## Commands [D]

`Invite Console 6`, `Invite IP ...`, `Dismiss Console "FOH2"`, `Disconnect ...`, `Reconnect ...`,
`LeaveSession`, `JoinSession`, `RemoteCommand IP ... "Call ViewButton 2.1"` (any command on another
station, desk lock included), `NetworkSpeedTest Session`, `ChangeMulticastBase ... /Type ...`,
`Reboot`, `Restart` (`/NoSave`), `ShutDown`, each with `/NoConfirmation`. **All of these are refused
by the plugin** [C: alpha.6].

## Release-note traps [D]

- Saving a show whose name holds `%` could crash the software and connected stations (fixed 2.4).
- A crashed station rejoining forced a full show upload (fixed 2.5); the master could crash with sACN
  active while a show loaded in a session (fixed 2.3); the session data merge pop-up could crash the
  software when references collided (fixed 2.4).

## Plugin access today, and gaps

- `ma3_status` reports the host type and show [C]. `MAnetSocket` (Root 5) is allowed as a single
  object for the show name [C: guard]. No tool lists stations or session state; a read-only station
  list would let a job confirm the onPC is not in the console's session [?: bench].
