"""Draw a layout export (XML) as a PNG, Y up, to eyeball element positions.
usage: draw_layout.py <layout.xml> <out.png> [xmin xmax ymin ymax]"""
import sys, re
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw
def s16(v):
    v = int(v); return v - 65536 if v > 32767 else v
root = ET.fromstring(open(sys.argv[1]).read())
lay = next(root.iter("Layout"))
els = []
for e in lay.iter("Element"):
    o = e.get("Object", "")
    m = re.search(r"Fixtures\.([^.]*)", o)
    fam = m.group(1).strip() if m else None
    els.append((s16(e.get("PosX")), s16(e.get("PosY")), int(e.get("Width") or 0), int(e.get("Height") or 0), fam,
                e.get("CustomTextText") or "", e.get("FixtureID") or ""))
if len(sys.argv) > 3: xmin, xmax, ymin, ymax = map(int, sys.argv[3:7])
else:
    xmin = min(a[0] for a in els) - 20; xmax = max(a[0] + a[2] for a in els) + 20
    ymin = min(a[1] for a in els) - 20; ymax = max(a[1] + a[3] for a in els) + 20
sc = 1600 / (xmax - xmin)
W, H = 1600, int((ymax - ymin) * sc)
im = Image.new("RGB", (W, H), (20, 20, 24)); d = ImageDraw.Draw(im)
COL = {"Portmans": (255, 190, 60), "InfiniBars": (90, 200, 255), "Q40": (200, 120, 255), "Key / Wash": (120, 255, 150),
       "Era": (255, 110, 110), "R1s": (255, 255, 255), "Dimmer Racks": (180, 180, 180), "Pixels": (70, 110, 90)}
def px(x, y): return ((x - xmin) * sc, (ymax - y) * sc)
for x, y, w, h, fam, txt, fid in sorted(els, key=lambda a: -(a[2] * a[3])):
    x0, y1 = px(x, y); x1, y0 = px(x + w, y + h)
    if fam is None:
        d.rectangle([x0, y0, x1, y1], outline=(110, 110, 130)); d.text((x0 + 4, y0 + 2), txt, fill=(160, 160, 190))
    else:
        d.rectangle([x0, y0, x1, y1], outline=COL.get(fam, (150, 150, 90)))
        if "." not in fid and w >= 40: d.text((x0 + 2, y0 + 2), fid, fill=COL.get(fam, (150, 150, 90)))
ox, oy = px(0, 0); d.line([ox - 8, oy, ox + 8, oy], fill=(255, 0, 0)); d.line([ox, oy - 8, ox, oy + 8], fill=(255, 0, 0))
im.save(sys.argv[2]); print(sys.argv[2], W, H, (xmin, xmax, ymin, ymax))
