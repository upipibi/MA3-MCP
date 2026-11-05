import sys, zipfile, collections, re
import xml.etree.ElementTree as ET
z = zipfile.ZipFile(sys.argv[1])
print("files in archive:")
for i in z.infolist(): print(f"  {i.file_size:>9}  {i.filename}")
xml = z.read("GeneralSceneDescription.xml").decode("utf-8", "replace")
root = ET.fromstring(xml)
print("\nroot:", root.tag, dict(root.attrib))
tags = collections.Counter(e.tag for e in root.iter())
print("element counts:", {k: v for k, v in tags.most_common(30)})
def name(e): return e.get("name") or e.get("Name") or ""
for kind in ["Layer", "SceneObject", "Fixture", "Truss", "Support", "FocusPoint", "VideoScreen", "Projector", "GroupObject", "Symdef"]:
    items = list(root.iter(kind))
    if items:
        names = [name(e) for e in items]
        print(f"\n{kind}: {len(items)}")
        for n, c in collections.Counter(names).most_common(40): print(f"   {c} x {n!r}")
print("\nGeometry3D files referenced:", collections.Counter(e.get("fileName") for e in root.iter("Geometry3D")).most_common(20))
m = [e.text for e in root.iter("Matrix")][:3]
print("first matrices:", m)
