#!/usr/bin/env python3
"""Turn the downloaded grandMA3 help pages into an inventory of checklist items.

Reads .cache/ma-help/<ver>/{toc.json,html/*.html}; writes .cache/ma-help/<ver>/inventory.json:
one row per item with page id, chapter path, kind, name and the section it sits in.
Kinds: topic, section, setting (a bold paragraph that names a field, e.g. "Restart Mode"),
option (a bold list entry under a setting), button (softkey), key (hardkey), syntax (a command
syntax line), keyword / option-keyword / lua-function (one per reference page), table-row.
Names only: MA's prose is not copied. usage: tools/helpsite/extract.py [version]"""
import html, json, os, re, sys
from html.parser import HTMLParser

VER = sys.argv[1] if len(sys.argv) > 1 else "2.5"
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".cache", "ma-help", VER)

def clean(s):
    s = html.unescape(re.sub(r"<[^>]+>", "", s)).replace("\xa0", " ")
    return re.sub(r"\s+", " ", s).strip(" :.")

def content(raw):
    i = raw.find('class="topic-content"')
    if i < 0: i = raw.find("<h1")
    b = raw[i:]
    for stop in ('class="CHSeeAlso', 'id="pnlFooter"', 'class="TopicViewer_footer'):
        j = b.find(stop)
        if j > 0: b = b[:j]
    return re.sub(r"<script.*?</script>|<style.*?</style>|<figure.*?</figure>", "", b, flags=re.S)

def items_for(t, raw):
    pid, path = t["id"], t["path"]; out = []
    def add(kind, name, section=""):
        name = clean(name)
        if not name or len(name) > 160: return
        out.append({"page": pid, "path": path, "kind": kind, "name": name, "section": section})
    chapter = path.split(" > ")
    kind = "topic"
    if pid.startswith("keyword_"): kind = "keyword"
    elif pid.startswith("ok_"): kind = "option-keyword"
    elif pid.startswith("lua_objectfree_") or pid.startswith("lua_object_"): kind = "lua-function"
    add(kind, t["title"])
    b = content(raw)
    # walk the body in order, tracking the current heading
    section = ""
    seen = set()
    token = re.compile(r"<h([2-5])[^>]*>(.*?)</h\1>|<p[^>]*>\s*<strong>(.*?)</strong>\s*:?\s*</p>|<li[^>]*>\s*(?:<p[^>]*>\s*)?<strong>(.*?)</strong>"
                       r"|<span class=\"softkey\">(.*?)</span>|<span class=\"hardkey\">(.*?)</span>|<p class=\"syntax\"[^>]*>(.*?)</p>|class=\"syntax\"[^>]*>(.*?)</"
                       r"|<tr[^>]*>\s*<td[^>]*>(.*?)</td>", re.S)
    last_setting = ""
    for m in token.finditer(b):
        h, pstrong, listrong, soft, hard, syn, syn2, td = m.group(2), m.group(3), m.group(4), m.group(5), m.group(6), m.group(7), m.group(8), m.group(9)
        if h is not None:
            section = clean(h); last_setting = ""; add("section", section, ""); continue
        if pstrong is not None:
            last_setting = clean(pstrong); add("setting", pstrong, section); continue
        if listrong is not None:
            add("option", listrong, last_setting or section); continue
        for k, v in (("button", soft), ("key", hard)):
            if v is not None:
                key = (k, clean(v))
                if key not in seen: seen.add(key); add(k, v, section)
        if syn is not None or syn2 is not None:
            add("syntax", syn if syn is not None else syn2, section)
        if td is not None:
            add("table-row", td, section)
    return out

toc = json.load(open(os.path.join(ROOT, "toc.json")))
inv = []
for t in toc:
    if not t["id"]: continue
    f = os.path.join(ROOT, "html", t["id"] + ".html")
    if not os.path.exists(f): continue
    inv += items_for(t, open(f, encoding="utf-8", errors="replace").read())
json.dump(inv, open(os.path.join(ROOT, "inventory.json"), "w"), indent=0)
from collections import Counter
print(len(inv), "items"); print(Counter(i["kind"] for i in inv).most_common())
