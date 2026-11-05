"""Write a copy of an MVR with the empty <Layer> elements removed.

A layer is empty when it holds nothing but ChildList and GroupObject shells.
Everything else in GeneralSceneDescription.xml is kept byte for byte, and every
other file in the archive is copied unchanged, in the same order.
usage: strip_layers.py <in.mvr> <out.mvr>
"""
import re, sys, zipfile
import xml.etree.ElementTree as ET

src, dst = sys.argv[1], sys.argv[2]
SHELLS = {"Layer", "ChildList", "GroupObject"}
LAYER = re.compile(rb"[ \t]*<Layer\b[^>]*?(?:/>|>.*?</Layer>)[ \t]*\r?\n", re.S)

zin = zipfile.ZipFile(src)
xml = zin.read("GeneralSceneDescription.xml")
kept, dropped = [], []

def decide(m):
    frag = ET.fromstring(m.group(0))
    name = frag.get("name")
    if all(e.tag in SHELLS for e in frag.iter()):
        dropped.append(name)
        return b""
    kept.append(name)
    return m.group(0)

out = LAYER.sub(decide, xml)
ET.fromstring(out)  # must still be well-formed
with zipfile.ZipFile(dst, "w") as zout:
    for info in zin.infolist():
        data = out if info.filename == "GeneralSceneDescription.xml" else zin.read(info.filename)
        zi = zipfile.ZipInfo(info.filename, date_time=info.date_time)
        zi.compress_type = info.compress_type  # Capture stores uncompressed; match it
        zi.external_attr = info.external_attr
        zout.writestr(zi, data)
print(f"layers kept {len(kept)}: {kept}")
print(f"layers dropped {len(dropped)}")
print(f"xml bytes {len(xml)} -> {len(out)}")
