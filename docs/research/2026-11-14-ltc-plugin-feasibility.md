# Can an onPC plugin listen to audio and make its own timecode? (2026-11-14)

Aaron: "Could we build a plugin on onpc that listens to an audio input and spits out MTC for
itself?" Context: house LTC arrives over Dante (Dante Virtual Soundcard on his MacBook); onPC has
no LTC port, so it needs MIDI timecode or Art-Net timecode (`docs/atlas/topics/timecode.md`).

## Answer: no, not inside MA. A small helper outside MA sending Art-Net timecode is the better build.

Evidence marks as in the atlas: [D] MA help 2.5, [O] proven on onPC, [?] not proven.

1. **A plugin cannot hear raw audio.** MA's audio input reaches the show only as processed sound
   channels: frequency bands, levels and BPM used in attribute calculators and the Sound window
   (`keyword_soundchannel`, `preview-and-sound.md`) [D]. The Lua API has no audio-sample function
   (none in the onPC object-API dump, `onpc-2.5.1.1-objapi.txt`, or the Lua help pages) [O, D].
   LTC is a 2,400 bit/s bi-phase signal; decoding it needs the raw waveform at audio sample rate,
   so band levels updated per frame are useless for it.
2. **A plugin cannot send MTC.** `SendMIDI` sends only notes, control change and program change
   [D]. MTC needs quarter-frame (`F1`) and full-frame SysEx messages, which it cannot send.
3. **Even with samples, Lua is the wrong place.** Plugins run on the screen thread; decoding
   48,000 samples/s in Lua there is exactly the kind of load that froze the console on 2026-11-08.
   The console guard exists to stop that.
4. **What a plugin can do:** LuaSocket 3.0 is loaded in plugin Lua [O], so a plugin could receive
   UDP from a helper. That still needs the helper to decode LTC, so the plugin adds nothing.

## Recommended build

The LTC decoding belongs in the Mac app that already does it (SMPTE to MIDI, moving to LTCKit,
session `smpte-midi`). Add **Art-Net timecode (ArtTimeCode) output** next to its MTC output:

- MA takes Art-Net timecode natively: Menu > DMX Protocols > Art-Net > Timecode tab, 16 streams by
  stream ID, Interface and Enable Input set [D, `dmx_ethernet_artnet`].
- It travels over the network, so it reaches onPC and **the console itself** with no MIDI port,
  no IAC bus and no cable into the console's LTC port.
- ArtTimeCode is one small UDP packet per frame (port 6454, OpCode 0x9700, frames/seconds/minutes/
  hours and a type: 0 Film 24, 1 EBU 25, 2 DF 29.97, 3 SMPTE 30). Public Art-Net 4 spec [?: not
  yet checked against MA's receiver].

Open before building: which network the console's Art-Net input listens on; whether onPC in the
console's session and the console would both take the same stream (first source wins per slot,
`timecode.md`); bench on onPC first.
