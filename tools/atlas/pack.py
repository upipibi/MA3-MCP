#!/usr/bin/env python3
"""Study pack for one chapter of the grandMA3 manual: everything needed to write its topic page,
gathered in one local file (MA's content stays in .cache/, never committed).

Contents: the full text of every help page in the chapter; the command and option keyword pages
those pages link to; MA's own system tests and menu code for the chapter (from the onPC install);
release-note paragraphs (1.0 to 2.5) that mention the chapter's terms; and what our own notes say.
usage: tools/atlas/pack.py "<Chapter title>" [--terms a,b,c] [--ver 2.5]
       tools/atlas/pack.py --list            (chapters with page counts)"""
import glob, html, json, os, re, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
args = sys.argv[1:]; VER = "2.5"; extra = []
if "--ver" in args: i = args.index("--ver"); VER = args[i + 1]; del args[i:i + 2]
if "--terms" in args: i = args.index("--terms"); extra = [t.strip() for t in args[i + 1].split(",") if t.strip()]; del args[i:i + 2]
HELP = os.path.join(REPO, ".cache", "ma-help", VER); toc = json.load(open(os.path.join(HELP, "toc.json")))
RES = os.path.expanduser(f"~/MALightingTechnology/gma3_{VER}.1/shared/resource")

def text(pid):
    f = os.path.join(HELP, "html", pid + ".html")
    if not os.path.exists(f): return ""
    s = open(f, encoding="utf-8", errors="replace").read()
    i = s.find('class="topic-content"'); b = s[i:] if i >= 0 else s
    for stop in ('class="CHSeeAlso', 'id="pnlFooter"'):
        j = b.find(stop)
        if j > 0: b = b[:j]
    b = re.sub(r"<script.*?</script>|<style.*?</style>", "", b, flags=re.S)
    b = re.sub(r'<span class="(softkey|hardkey)">(.*?)</span>', r"[\2]", b, flags=re.S)
    b = re.sub(r"<(br|/p|/li|/h\d|/tr|/div|/pre|/figcaption)[^>]*>", "\n", b)
    b = re.sub(r"<li[^>]*>", "\n- ", b); b = re.sub(r"<h(\d)[^>]*>", lambda m: "\n" + "#" * (int(m.group(1)) + 2) + " ", b)
    t = html.unescape(re.sub(r"<[^>]+>", "", b)).replace("\xa0", " ")
    t = re.sub(r"[ \t]+", " ", t); return re.sub(r"\n\s*\n+", "\n", t).replace('class="topic-content">', "").strip()

def links(pid):
    f = os.path.join(HELP, "html", pid + ".html")
    if not os.path.exists(f): return []
    s = open(f, encoding="utf-8", errors="replace").read()
    i = s.find('class="topic-content"'); s = s[i:] if i >= 0 else s
    return sorted(set(re.findall(r'href="((?:keyword|ok)_[a-z0-9_-]+)\.html', s)))

if args and args[0] == "--list":
    from collections import Counter
    c = Counter(t["path"].split(" > ")[1] for t in toc if t["path"].startswith("grandMA3 User Manual > "))
    for k, n in c.items(): print(f"{n:4}  {k}")
    sys.exit(0)

chapter = args[0]
pages = [t for t in toc if t["id"] and (t["path"] == "grandMA3 User Manual > " + chapter or t["path"].startswith("grandMA3 User Manual > " + chapter + " > "))]
if not pages: sys.exit("no such chapter: " + chapter)
slug = re.sub(r"[^a-z0-9]+", "-", chapter.lower()).strip("-")
kw = sorted({l for p in pages for l in links(p["id"])} - {p["id"] for p in pages})
kwnames = [re.sub(r"^(keyword|ok)_", "", k).replace("-", "") for k in kw]
terms = [t.lower() for t in extra] or [re.sub(r"s$", "", chapter.split()[0].lower())]
out = [f"# Study pack: {chapter} (help {VER})\n", f"Pages: {len(pages)}; linked keyword pages: {len(kw)}; terms: {terms}\n"]
out.append("\n## Help pages\n")
for p in pages: out.append(f"\n### [{p['id']}] {p['path']}\n{text(p['id'])}\n")
out.append("\n## Linked command and option keyword pages\n")
for k in kw: out.append(f"\n### [{k}]\n{text(k)}\n")
# MA's own code
tests = sorted(glob.glob(RES + "/lib_plugins/systemtests/db/system_test_*.lua"))
def tname(f): return os.path.basename(f)[len("system_test_"):-4].lower()
match = [f for f in tests if any(tname(f) == t or tname(f).startswith(t + "_") or tname(f).startswith(t) for t in terms)]
out.append(f"\n## MA system tests ({len(match)}): step descriptions and every command they send\n")
CMD_RX = re.compile(r"""\b(?:C|Cmd|CmdIndirect|CmdIndirectWait)\(\s*(['"])(.*?)\1""")
for f in match:
    body = open(f, encoding="utf-8", errors="replace").read()
    infos = re.findall(r"info\s*=\s*['\"](.+?)['\"]", body)
    cmds = []
    for m in CMD_RX.finditer(body):
        c = m.group(2).strip()
        if c and c not in cmds: cmds.append(c)
    props = sorted(set(re.findall(r"""(?:Get|Set)\(\s*['"]([A-Za-z]+)['"]""", body) + re.findall(r'Property\s+\\?"([A-Za-z]+)', body)))
    out.append(f"\n### {os.path.basename(f)}")
    if infos: out.append("steps: " + " | ".join(dict.fromkeys(infos)))
    if props: out.append("properties: " + ", ".join(props))
    out.append("commands:\n" + "\n".join("  " + c for c in cmds[:120]) + ("\n  ..." if len(cmds) > 120 else ""))
menus = [f for f in glob.glob(RES + "/lib_menus/**/*.lua", recursive=True) if any(t in os.path.basename(f).lower() for t in terms)]
out.append(f"\n## MA menu code: files and the properties they touch ({len(menus)})\n")
for f in sorted(menus):
    body = open(f, encoding="utf-8", errors="replace").read()
    props = sorted(set(re.findall(r"""(?:Get|Set)\(\s*['"]([A-Za-z]+)['"]""", body) + re.findall(r"\.([A-Z][A-Za-z]+)\s*=", body)))
    out.append(f"- {os.path.relpath(f, RES)}: {', '.join(props[:60])}")
# release notes
# Release notes from 2.2 on (the behaviour of the installed software); 1.x and 2.0-2.1 are history.
RN_KEEP = re.compile(r"key_rn_v2_2|key_releasenotes_2-3|rn_.*-2-4|rn_.*-2-5|release-notes-2-[45]|rn_bug_fix_version")
rn = [t["id"] for t in toc if t["id"] and t["path"].startswith("grandMA3 Release Notes") and RN_KEEP.search(t["id"])]
out.append("\n## Release-note paragraphs mentioning the terms\n")
for r in rn:
    for para in text(r).split("\n"):
        pl = para.lower()
        if any(re.search(r"\b" + re.escape(t), pl) for t in terms) and len(para) > 30:
            out.append(f"- [{r}] {para.strip()}")
# our notes
out.append("\n## Our notes mentioning the terms\n")
CURATED = ["docs/PROGRAMMING-STYLE.md", "docs/CONVENTIONS.md", "docs/research/2026-11-onpc-facts.md", "CLAUDE.md"]
for f in [REPO + "/" + c for c in CURATED] + sorted(glob.glob(REPO + "/docs/jobs/**/*.md", recursive=True)):
    if not os.path.exists(f): continue
    for ln in open(f, encoding="utf-8", errors="replace"):
        if any(re.search(r"\b" + re.escape(t), ln.lower()) for t in terms):
            out.append(f"- [{os.path.relpath(f, REPO)}] {ln.strip()[:300]}")
dst = os.path.join(REPO, ".cache", "atlas", "packs", slug + ".md")
os.makedirs(os.path.dirname(dst), exist_ok=True)
open(dst, "w").write("\n".join(out))
print(f"{dst}  {sum(len(x) for x in out)//1000} kB  pages={len(pages)} keywords={len(kw)} tests={len(match)} menus={len(menus)}")
