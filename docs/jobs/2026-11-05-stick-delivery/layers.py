import sys, zipfile
import xml.etree.ElementTree as ET
root = ET.fromstring(zipfile.ZipFile(sys.argv[1]).read("GeneralSceneDescription.xml"))
rows = []
for layer in root.iter("Layer"):
    so = len(list(layer.iter("SceneObject"))); go = len(list(layer.iter("GroupObject")))
    rows.append((so, go, layer.get("name")))
full = [r for r in rows if r[0] > 0]
print("layers with scene objects:")
for so, go, n in sorted(full, reverse=True): print(f"  {n}: {so} objects in {go} groups")
print(f"\nempty layers: {len(rows) - len(full)} of {len(rows)}")
# bounding box of translations (mm)
import re
xs, ys, zs = [], [], []
for m in root.iter("Matrix"):
    t = re.findall(r"\{([^}]*)\}", m.text)[-1].split(",")
    xs.append(float(t[0])); ys.append(float(t[1])); zs.append(float(t[2]))
print(f"object origins span (m): x {min(xs)/1000:.1f}..{max(xs)/1000:.1f}, y {min(ys)/1000:.1f}..{max(ys)/1000:.1f}, z {min(zs)/1000:.1f}..{max(zs)/1000:.1f}")
