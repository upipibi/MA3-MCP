"""Rotation maths for re-describing the Tornado heads the way MA's XYZ wants them.

MA composes a geometry's ROTX/ROTY/ROTZ as M = Rz * Ry * Rx (measured 2026-11-05 from how it
re-normalises angles at ROTY = 90). `s` is the handedness: +1 = right-handed angles (GDTF's
convention, assumed), -1 = the mirror case, kept so both can be compared."""
import math
def mm(a, b): return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def mv(a, v): return [sum(a[i][k] * v[k] for k in range(3)) for i in range(3)]
def tr(a): return [[a[j][i] for j in range(3)] for i in range(3)]
def rx(d): c, s = math.cos(math.radians(d)), math.sin(math.radians(d)); return [[1, 0, 0], [0, c, -s], [0, s, c]]
def ry(d): c, s = math.cos(math.radians(d)), math.sin(math.radians(d)); return [[c, 0, s], [0, 1, 0], [-s, 0, c]]
def rz(d): c, s = math.cos(math.radians(d)), math.sin(math.radians(d)); return [[c, -s, 0], [s, c, 0], [0, 0, 1]]
def euler(t, s=1): return mm(rz(s * t[2]), mm(ry(s * t[1]), rx(s * t[0])))
def decompose(m, s=1):
    """Inverse of euler(): angles (x, y, z) in degrees. At y = +/-90 the x/z split is free; z = 0 is chosen."""
    sb = -m[2][0]
    if abs(sb) > 0.999999:
        b = math.copysign(90.0, sb)
        # m = Rz(c) Ry(b) Rx(a); with c = 0:  m[0][1] = sin(a)*sb, m[1][1] = cos(a)
        a = math.degrees(math.atan2(m[0][1] * sb, m[1][1])); c = 0.0
    else:
        b = math.degrees(math.asin(sb)); a = math.degrees(math.atan2(m[2][1], m[2][2])); c = math.degrees(math.atan2(m[1][0], m[0][0]))
    return [round(s * v, 4) + 0.0 for v in (a, b, c)]
def close(a, b, eps=1e-4): return all(abs(a[i][j] - b[i][j]) < eps for i in range(3) for j in range(3))
YOKE_NEW = (90.0, 0.0, 90.0)          # pan axis: local Z along the bar
ARRAY_OLD, HEAD_OLD = (0.0, 0.0, 90.0), (-90.0, 0.0, -90.0)
def K(s=1):
    """Maps a head child's old pose (in the old head frame) to its pose in the new, square head frame."""
    return mm(tr(euler(YOKE_NEW, s)), mm(euler(ARRAY_OLD, s), euler(HEAD_OLD, s)))
def head_pos(old, s=1): return [round(v, 6) + 0.0 for v in mv(tr(euler(YOKE_NEW, s)), mv(euler(ARRAY_OLD, s), old))]
def child(old_rot, old_pos, s=1):
    k = K(s); m = mm(k, euler(old_rot, s)); t = decompose(m, s)
    assert close(euler(t, s), m), (old_rot, t)
    return t, [round(v, 6) + 0.0 for v in mv(k, old_pos)]
if __name__ == "__main__":
    for s in (1, -1):
        print("handedness", s, "| yoke frame columns x,y,z ->", [[round(v) + 0 for v in col] for col in tr(euler(YOKE_NEW, s))], "| head pos", head_pos([0, 0, -0.048], s))
        for name, r in (("Beam", (90, 0, 0)), ("LED 1", (-90, -45, 180)), ("LED 2", (-90, 0, 180)), ("LED 3", (-90, 45, 180)), ("LED 4", (0, 90, -90)),
                        ("LED 5", (90, 45, 0)), ("LED 6", (90, 0, 0)), ("LED 7", (90, -45, 0)), ("LED 8", (0, -90, 90))):
            print("   ", name, r, "->", child(r, [0, 0.04, 0], s))
