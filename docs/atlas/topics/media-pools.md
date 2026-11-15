# Media pools (images, symbols, gobos, videos, meshes, sounds): what we know, how sure we are

Written 2026-11-08 from the MA help 2.5 (chapters "Images", "Symbols" 3 pages, "Gobos", "Videos",
"Meshes"; keyword pages `Image`, `GoboImage`, `Delete`), twelve of MA's image system tests, MA's video
editor code, and the release notes 2.2 to 2.5.1.1. Sounds are in `preview-and-sound.md`. Our stage
model import (MVR, meshes) is in `docs/jobs/2026-11-05-stick-delivery/`. Study packs: `pack.py
"Images" --terms image`, and the same for Symbols, Gobos, Videos, Meshes.

Evidence marks: **[D]** MA help · **[M]** MA's shipped Lua · **[O]** onPC · **[C]** console · **[?]** not proven.

## Limits [D]

- **All media pools together: 300 MB.** Images pool 100 MB, videos pool 100 MB, sounds pool 100 MB.
  MA advises images under 64 MB and at most 1920 x 1080.
- **An 8K video previewed can overload and crash the system**; keep videos at 1920 x 1080, 30 Hz for
  bitmaps (60 Hz maximum). Some codecs need Third-Party Software accepted under Menu > Settings >
  Software Update > EULA.
- Library folders: `gma3_library/media/images`, `.../symbols`, `.../videos`, `.../sounds` (and gobos,
  meshes in the fixture type library) [D: Folder Structure].

## Images, symbols, gobos: three image pools [D, M]

- One keyword, three pools: `Image 1.n` = Gobos, `Image 2.n` = Symbols, `Image 3.n` = Images
  (`Delete Image 3.4`, `Delete Image 2.15 Thru Image 2.20`, `Edit Image 3.1`). `GoboImage n` addresses
  the gobo pool directly (`Edit GoboImage 1`, `List GoboImage`). Path in the show:
  `ShowData/MediaPools/...` (the symbol import prompt shows `ShowData/MediaPools/Symbols`).
- Locks: gobos 1-4 system-locked (red padlock), symbols 1-29 locked (unlockable), meshes 1-9 locked.
  **Patching a fixture stores its gobos in the Gobo pool.**
- Image settings: Add Alpha (black becomes transparent), **Installed** (refresh from the source file
  archive), name, appearance, scribble; MA's test sets `addalpha`, `appearance`, `filename`, `filepath`,
  `scribble` [M].
- Import: edit an empty slot > Import > drive > file; Show Creator > Import > Images / Symbols; by
  command `ChangeDestination Image 2`, `Import Library "*.xml"`, `ChangeDestination Root` (factory
  symbols). MA's tests use `cd Image; cd Images; import lib ...` and `UpdateContent Image "Images"`
  (and `"Gobos"`, `"Symbols"`) [M].
- Assign to objects: `Assign Image 3.5 At Group 46` opens a Select Appearance pop-up (images reach
  objects through appearances; see `appearances-and-tags.md`). Deleting an image removes it from every
  appearance that uses it. Copy, Move, Label, Lock / Unlock and Oops work as on any pool [M].

## Videos [D]

- Video pool objects: imported files from `/gma3_library/media/videos` (Edit > Import > preview >
  Import; width, height and size shown) or an **NDI source** (Source > NDI > Select Source, two
  bandwidth settings). Used in appearances (loop everywhere the appearance shows) and bitmaps.
- Installed: refresh from the archive (files reach the console by FTP or a stick).
- Traps: video appearances on executors did not play until 2.5.1.0; importing into a video slot used
  by a running bitmap crashed (fixed 2.4); a blocked NDI stream pulses in the pool.

## Meshes [D]

- 3D models in the Mesh pool for fixture types and environmental objects (stage model). Edit Mesh:
  material colour or appearance per material (2.4), **Cull Mode** Front / Back / None / Auto (2.5),
  Import. Aaron's stage model arrived as MVR with its own meshes [C].
- Traps: deleting fixtures in the patch could shift meshes in the 3D viewer (fixed 2.5); importing
  certain meshes could crash (fixed 2.4); meshes could be lost after a PSR and restart (fixed 2.3).

## Plugin access today, and gaps

- No media job has run. The pools are readable as objects [?]. Media import and preview are crash
  classes in the release notes: any media job is onPC first, never during a service.
