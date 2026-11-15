# Remote in and out: DC, MIDI, DMX remotes, OSC, PSN, MVR-xchange, MSC

Written 2026-11-08 from the MA help 2.5 (chapter "Remote In and Out", 16 pages; keyword pages
`Remote`, `SendOSC`, `SendMIDI`, `SendMVR`, `List`, readout keywords), and the release notes 2.2 to
2.5.1.1. Study pack: `python3 tools/atlas/pack.py "Remote In and Out" --terms remote,osc,midi,psn,mvr,msc`.
How Aaron's console talks to Companion and other systems is not recorded yet [?: ask him].

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## In & Out menu (Menu > In & Out) [D]

Tabs DC Remotes, MIDI Remotes, DMX Remotes, OSC, PSN, MVR (MSC has its own menu). Each needs its
**Enable Input** / **Enable Output** switch (also in Station Control) and per-line settings.

- DC, MIDI and DMX remote lines share: Enabled, **Target** (World, Sequence, Macro, Group, Plugin, View,
  Master), **Fader** (Master, X, Temp, any fader function) or **Key** (any key function), Trigger On /
  Off thresholds, In From / To and Out From / To scaling, live In / Out readout, Note. DC and DMX
  thresholds are percent; MIDI uses velocity 1-127.
- By command: `Remote <type>.<n>` with type 1 = DC, 2 = MIDI, 3 = DMX; `Assign Sequence 5 At Remote
  2.1`, `Set Remote 2.1 Property "MIDIIndex" "42"`; properties Lock, Name, Target, Fader, Key,
  TriggerOn/Off, InFrom/To, OutFrom/To, Enabled, plus Address and Resolution (DMX), MIDIChannel,
  MIDIIndex, MIDIType (Note, NoteAttack, NoteAttackDecay, Control) and DC start signal.
- DC remotes: 7 signals per connector; DC Start (Connector Configuration) offsets them per device.
- MIDI: MIDI Data Mode per device (In, Out, In & Out & Thru, In & Out, Off) and MIDI Offset in
  Connector Configuration; "Show MIDI Data in System Monitor" to watch input.

## OSC [D]

- Message form `(/prefix)/address,type,value` (types i, f, s, T, F and more for sending); OSC 1.1;
  no bundles. Lines: Name, Destination IP (or broadcast), Mode UDP / TCP, Port (default 8000),
  Prefix (no slashes), Page / Fader / ExecutorKnob / Key address names, FaderRange, **Receive**,
  **Send**, **Receive Command**, **Send Command**, EchoInput / EchoOutput (to the System Monitor).
- Executors: `/Page1/Fader201,i,100`. Pool objects by their enumerated tree address, for example
  `/13.13.1.6.<n>` for sequence n with a key or fader function (addresses can change between
  software versions).
- **`/cmd,s,<command>` runs any command line** when Receive Command is Yes on that line. MA's own
  examples patch fixtures this way. Anything on the network that can reach the OSC port then has the
  whole command line with no PIN, no guard and no refused keywords; it is the console's setting, not
  the plugin's [D]. Worth knowing whether Aaron's console has it on [?].
- `SendOSC 1 "/cmd,s,FaderMaster Page 1.201 At 50"` sends through OSC line 1. The plugin allows
  `SendOSC` (Aaron may want the console to trigger other systems), so a `SendOSC` aimed back at the
  console with Receive Command on would reach its command line unfiltered [D: mechanism; a gap noted
  for a later plugin round].
- 2.5 fixed: an OSC TCP feedback loop to itself froze the UI during playback.

## PSN (PosiStageNet) [D]

Tracking positions in, mapped to MArker fixtures (MArker ID per tracker): Sender IP, Requested, Port
(56565), Multicast IP (236.10.10.10), axis Map and Invert, Merge Mode, DMX Priority, live position,
speed and rotation. Fixtures follow a MArker through XYZ.
PSN configuration is show data: MA's test edits it with `cd Root ShowData.PSNProtocol`, `Insert`,
`Set 1 Property "MArkerID" 2`, and sets universe merge with `Set DmxUniverse 11 Property "MergeMode"
"Prio"` (Prio, HTP, LowTP, Off) [M]. Up to 1,024 trackers per PSN system (2.3).

## MVR-xchange [D]

Share MVR files over the network in an exchange group (Group name, Interface, Enable): Local (files
committed here), Services (stations in the group; Join, Leave), Files (Request, Commit MVR with a
message). `SendMVR "Join" "3"`, `"Leave" "1"`, `"Commit" "<path>" "<name>"`, `"Request" "2"`. Our stage
model went the USB route [C].

## MSC (MIDI Show Control) [D]

Menu > In & Out > MSC: Input and Output (device ID, group ID, data pool, command formats: Extensions,
General Light, Moving Light, All) and Executor Mapping. **MSC runs as the Remote user profile.**

## SendMIDI [D]

`SendMIDI "Note" 2/42 99`, `SendMIDI "Control" 1/8 64`, `SendMIDI "Program" 12` (channel 1 when
omitted).

## Plugin access today, and gaps

- None of this is read by a tool. Remote lines are show data (`Remote` objects) [?: path]; OSC,
  PSN and MSC settings live in the device configuration [?]. A read of "which inputs can fire what"
  would complete the picture of how the show is triggered.
