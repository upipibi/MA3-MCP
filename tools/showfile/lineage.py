#!/usr/bin/env python3
"""Print the save history stored in a grandMA3 .show file's header: every name the show was
saved under, with the two timestamps MA writes per save. Offline, read-only, no console needed.

A .show file starts with "GMA3", then a list of records <u64 ms timestamp><u16 length><name>...,
oldest first, ending at the "ShowData" record; the body after it is MA's packed binary format
(not parsed here). The history survives Save As, so it shows which file a show was split from:
2026-11-08 it showed Christmas 2026 was split from "Late 2026" on 2026-10-22, while "Late 2026 2"
came from a later Late 2026 save. The meaning of the two timestamps (local vs UTC, save vs load)
is not confirmed; they differ by the console's UTC offset in most records.
usage: tools/showfile/lineage.py <file.show> [--all]   (default: the last 40 records)"""
import datetime, struct, sys

def records(b):
    out, i, end = [], 0x70, min(len(b), 0x80000)
    while i < end:
        n = struct.unpack_from("<H", b, i)[0] if i + 2 <= end else 0
        if 3 <= n <= 96 and i + 2 + n <= end:
            s = b[i + 2:i + 2 + n]
            if all(32 <= c < 127 for c in s):
                name = s.decode()
                if name == "ShowData": break
                before = struct.unpack_from("<Q", b, i - 8)[0] if i >= 8 else 0
                after = struct.unpack_from("<Q", b, i + 3 + n)[0] if i + 11 + n <= end else 0
                out.append((i, name, before, after)); i += 2 + n; continue
        i += 1
    return out

def fmt(ms):
    return datetime.datetime.fromtimestamp(ms / 1000).strftime("%Y-%m-%d %H:%M") if 1.2e12 < ms < 2.2e12 else ""

if __name__ == "__main__":
    b = open(sys.argv[1], "rb").read()
    if b[:4] != b"GMA3": sys.exit("not a grandMA3 show file")
    recs = records(b)
    if "--all" not in sys.argv: recs = recs[-40:]
    for off, name, t1, t2 in recs:
        print(f"{fmt(t1):16}  {fmt(t2):16}  {name}")
