#!/usr/bin/env python3
"""Print downloaded help pages as plain text (from .cache/ma-help/<ver>/html/).
usage: tools/helpsite/text.py <page-id> [<page-id> ...] [--ver 2.5] [--grep word]
--grep prints only paragraphs that contain the word (case-insensitive), with the page id."""
import html, os, re, sys
args = sys.argv[1:]; ver = "2.5"; grep = None
if "--ver" in args: i = args.index("--ver"); ver = args[i + 1]; del args[i:i + 2]
if "--grep" in args: i = args.index("--grep"); grep = args[i + 1].lower(); del args[i:i + 2]
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".cache", "ma-help", ver, "html")
for pid in args:
    s = open(os.path.join(root, pid + ".html"), encoding="utf-8", errors="replace").read()
    i = s.find('class="topic-content"'); b = s[i:] if i >= 0 else s
    for stop in ('class="CHSeeAlso', 'id="pnlFooter"'):
        j = b.find(stop)
        if j > 0: b = b[:j]
    b = re.sub(r"<script.*?</script>|<style.*?</style>", "", b, flags=re.S)
    b = re.sub(r'<span class="(softkey|hardkey)">(.*?)</span>', r"[\2]", b, flags=re.S)
    b = re.sub(r"<(br|/p|/li|/h\d|/tr|/div|/pre|/figcaption)[^>]*>", "\n", b)
    b = re.sub(r"<li[^>]*>", "\n- ", b); b = re.sub(r"<h(\d)[^>]*>", lambda m: "\n" + "#" * int(m.group(1)) + " ", b)
    t = html.unescape(re.sub(r"<[^>]+>", "", b)).replace("\xa0", " ")
    t = re.sub(r"[ \t]+", " ", t); t = re.sub(r"\n\s*\n+", "\n", t).strip()
    if grep:
        for para in t.split("\n"):
            if grep in para.lower(): print(f"[{pid}] {para.strip()}")
    else:
        print(f"===== {pid}\n{t}\n")
