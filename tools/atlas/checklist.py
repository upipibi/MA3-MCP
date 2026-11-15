#!/usr/bin/env python3
"""Build the console checklist: every item of the grandMA3 help (from tools/helpsite/extract.py)
checked against what this project knows, can read, and has proven.

Inputs: .cache/ma-help/<ver>/inventory.json, a class census (tools/atlas/census.py), and the project's
own notes (docs/, CLAUDE.md, README.md, .claude/skills/, src/ tool descriptions).
Outputs: docs/atlas/checklist.json (every item with its three marks and the evidence) and
docs/atlas/CHECKLIST.md (grouped by manual chapter and page).

The three marks, all automatic, all with evidence so a wrong mark can be found and fixed:
  N  named in our notes: the item's name appears in our docs (keywords and syntax only inside `code`;
     single generic words never count).
  R  readable: a console property with the same normalized name exists in the class census
     (so ma3_object reads it), or a plugin tool covers it (lua functions the plugin calls).
  P  proven: used on the desk in a job record or a verified fact (docs/jobs/, docs/research/*facts*,
     docs/CONVENTIONS.md), as a command in `code` or as a property name.
An item counts as covered when it is P, or both N and R. Everything else is the to-do list.
usage: tools/atlas/checklist.py <census.json> [version]"""
import glob, json, os, re, sys
from collections import defaultdict, Counter

HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
CENSUS = sys.argv[1]; VER = sys.argv[2] if len(sys.argv) > 2 else "2.5"
inv = json.load(open(os.path.join(REPO, ".cache", "ma-help", VER, "inventory.json")))
toc = json.load(open(os.path.join(REPO, ".cache", "ma-help", VER, "toc.json")))
census = json.load(open(CENSUS))["classes"]

# ---------- scope and noise filters ----------
BOILER = {"description", "syntax", "example", "examples", "return", "returns", "arguments", "argument", "location",
          "requirement", "requirements", "hint", "important", "restriction", "warning", "general keywords",
          "option keywords", "see also", "note", "notes", "overview", "introduction", "limitations"}
GENERIC = {"ok", "cancel", "please", "yes", "no", "close", "edit", "settings", "setting", "delete", "store", "on", "off",
           "ma", "esc", "enter", "set", "copy", "move", "name", "none", "all", "add", "insert", "remove", "new", "load",
           "save", "back", "next", "prev", "up", "down", "left", "right", "select", "clear", "x", "+", "-", "1", "2", "3",
           "handle", "string", "integer", "boolean", "table", "number", "value", "nil", "type", "mode", "on/off"}
def in_scope(it):
    top = it["path"].split(" > ")[0]
    if top == "Quick Manuals grandMA3 Devices": return False
    if top == "grandMA3 Release Notes":
        return it["kind"] == "topic" or (it["page"].startswith("rn_knownlimitations") and it["kind"] in ("table-row", "setting", "option"))
    if top == "grandMA3 Quick Start Guide": return it["kind"] == "topic"
    n = it["name"].lower()
    if it["kind"] == "section" and n in BOILER: return False
    if it["kind"] == "table-row" and ("»" in it["name"] or n.startswith("copy code") or re.fullmatch(r"\d+ ?x", n)): return False
    # a table cell that is a sentence is MA's prose, not a named thing (and is not ours to publish)
    if it["kind"] == "table-row" and (len(it["name"]) > 70 or len(it["name"].split()) > 9): return False
    if it["kind"] in ("button", "key", "option", "table-row") and n in GENERIC: return False
    if it["kind"] == "key" and not it["page"].startswith("key"): return False   # key mentions in prose; the Keys pages carry them
    if it["kind"] == "syntax" and it["name"] in ("object:function()", "object.function(object)", "[Function]"): return False
    return True
items = []; seen = set()
for it in inv:
    if not in_scope(it): continue
    k = (it["page"], it["kind"], it["name"].lower(), it["section"].lower())
    if k in seen: continue
    seen.add(k); items.append(it)

# ---------- our corpus ----------
def files(patterns):
    out = []
    for p in patterns: out += glob.glob(os.path.join(REPO, p), recursive=True)
    # docs/atlas is the checklist's own output, except the hand-written topic pages (the study
    # notes); keywords.md there is generated from the help itself and would match everything.
    def ours(f):
        if "/.cache/" in f: return False
        if "/docs/atlas/" not in f: return True
        return "/docs/atlas/topics/" in f and not f.endswith(("/keywords.md", "/INDEX.md"))
    return sorted(set(f for f in out if os.path.isfile(f) and ours(f)))
NOTE_FILES = files(["CLAUDE.md", "README.md", "docs/**/*.md", ".claude/skills/**/*.md"])
PROVEN_FILES = files(["docs/jobs/**/*.md", "docs/jobs/**/*.py", "docs/research/*facts*.md", "docs/CONVENTIONS.md", "docs/INSTALL-CONSOLE.md"])
SRC_FILES = files(["src/**/*.lua"])
def load(fs): return {os.path.relpath(f, REPO): open(f, encoding="utf-8", errors="replace").read() for f in fs}
notes, proven, src = load(NOTE_FILES), load(PROVEN_FILES), load(SRC_FILES)
def code_spans(text): return "\n".join(re.findall(r"`([^`\n]+)`", text))
notes_code = {f: code_spans(t) for f, t in notes.items()}
proven_code = {f: code_spans(t) for f, t in proven.items()}
notes_low = {f: t.lower() for f, t in notes.items()}

def norm(s): return re.sub(r"[^A-Z0-9]", "", s.upper())
props = defaultdict(set)
for cls, r in census.items():
    for p in r.get("props") or []:
        if p.get("name"): props[norm(p["name"])].add(cls)
classes_norm = {norm(c): c for c in census}

# MA's own Lua shipped with onPC (system tests, menus): worked examples of commands. A lead for
# study (mark M), never coverage. Missing install = no M marks.
MA_RES = os.path.expanduser(f"~/MALightingTechnology/gma3_{'.'.join((VER + '.1').split('.')[:3])}/shared/resource")
ma_cmds = []
for f in glob.glob(MA_RES + "/lib_plugins/**/*.lua", recursive=True) + glob.glob(MA_RES + "/lib_menus/**/*.lua", recursive=True):
    t = open(f, encoding="utf-8", errors="replace").read()
    for m in re.finditer(r"""\b(?:C|Cmd|CmdIndirect|CmdIndirectWait)\(\s*['"]([^'"]+)['"]""", t):
        ma_cmds.append((os.path.relpath(f, MA_RES), m.group(1)))
def ma_example(word):
    rx = re.compile(r"(^|[\s;])" + re.escape(word.lower()) + r"(\s|$|[;\"'])")
    for f, c in ma_cmds:
        if rx.search(c.lower()): return f + ": " + c[:80]
    return None

def first_hit(pattern, texts, flags=0):
    rx = re.compile(pattern, flags)
    for f, t in texts.items():
        if rx.search(t): return f
    return None

def keyword_of(it):
    n = it["name"].strip()
    return ("/" + n.lstrip("/")) if it["kind"] == "option-keyword" else n

FAILED = re.compile(r"fail|not found|illegal|does not work|did not work|refus|hang|never |cannot|wrong|mistake|trap", re.I)
KEYWORDS = {i["name"] for i in inv if i["kind"] == "keyword"}
def command_lines(texts):
    """{file: code spans shaped like console commands, from lines that do not report a failure}.
    A command starts with a console keyword and carries a number, a quoted name or a <placeholder>;
    quoted names are blanked so words inside them never count ("King Of The World")."""
    out = {}
    for f, t in texts.items():
        spans = []
        for line in t.splitlines():
            if FAILED.search(line): continue
            for sp in re.findall(r"`([^`\n]+)`", line):
                first = sp.split()[0] if sp.split() else ""
                if first not in KEYWORDS: continue
                if not re.search(r"\d|\"|<", sp): continue
                spans.append(re.sub(r'"[^"]*"', '""', sp))
        out[f] = "\n".join(spans)
    return out
notes_cmd, proven_cmd = command_lines(notes), command_lines(proven)
GENERIC_PROPS = {"NAME", "NO", "INDEX", "LOCK", "COUNT", "DEFAULT", "NOTE", "OWNED", "HIDDEN", "TYPE", "MODE", "VALUE"}
VERIFIED_PATH = os.path.join(REPO, "docs", "atlas", "verified.json")
verified = json.load(open(VERIFIED_PATH)) if os.path.exists(VERIFIED_PATH) else {}

def mark(it):
    kind, name = it["kind"], it["name"]; ev = {}
    words = name.split()
    if kind in ("keyword", "option-keyword"):
        kw = re.escape(keyword_of(it))
        pat = r"(^|[\s\"(])" + kw + r"(?![A-Za-z])"
        ev["N"] = first_hit(pat, notes_cmd, re.M)
        ev["P"] = first_hit(pat, proven_cmd, re.M)
        ev["R"] = "ma3_command" if ev["P"] else None
        ev["M"] = ma_example(keyword_of(it))
    elif kind == "syntax":
        ev["N"] = ev["P"] = ev["R"] = None
    elif kind == "lua-function":
        fn = re.sub(r"\(.*", "", name).strip()
        ev["R"] = first_hit(r"(:|\b)" + re.escape(fn) + r"\s*\(", src)
        ev["N"] = first_hit(r"\b" + re.escape(fn) + r"\b", notes_code)
        ev["P"] = ev["R"]
    else:
        if len(words) >= 2 and len(name) >= 8:
            ev["N"] = first_hit(r"(?<![a-z])" + re.escape(name.lower()) + r"(?![a-z])", notes_low)
        elif len(name) >= 5 and name.lower() not in GENERIC:
            ev["N"] = first_hit(r"(?<![A-Za-z])" + re.escape(name) + r"(?![A-Za-z])", notes_code)
        p = norm(name)
        if len(p) >= 4 and p in props and p not in GENERIC_PROPS:
            ev["R"] = "property " + p + " on " + ", ".join(sorted(props[p])[:3]) + (" ..." if len(props[p]) > 3 else "")
        elif kind in ("topic", "section") and len(p) >= 4 and p in classes_norm:
            ev["R"] = "class " + classes_norm[p]
        if ev.get("R") and ev["R"].startswith("property"):
            ev["P"] = first_hit(r"\b" + re.escape(p) + r"\b", proven_cmd)
    for k in ("N", "R", "P", "M"): ev.setdefault(k, None)
    key = f'{it["page"]}|{kind}|{name}'
    if key in verified:
        v = verified[key]
        for k in ("N", "R", "P"):
            if k in v: ev[k] = v[k]
        ev["verified"] = v.get("note", True)
    ev["covered"] = bool(ev["P"] or (ev["N"] and ev["R"]))
    return ev

out = []
for it in items:
    ev = mark(it); out.append({**it, **ev})
os.makedirs(os.path.join(REPO, "docs", "atlas"), exist_ok=True)
json.dump({"version": VER, "census": os.path.basename(CENSUS), "items": out},
          open(os.path.join(REPO, "docs", "atlas", "checklist.json"), "w"), indent=0)

# ---------- markdown ----------
url = f"https://help.malighting.com/grandMA3/{VER}/HTML/"
order = {t["id"]: i for i, t in enumerate(toc)}
by_page = defaultdict(list)
for it in out: by_page[it["page"]].append(it)
def chapter(path):
    p = path.split(" > ")
    return p[1] if p[0] == "grandMA3 User Manual" and len(p) > 1 else p[0]
chap_pages = defaultdict(list)
for pid in sorted(by_page, key=lambda p: order.get(p, 1e9)):
    chap_pages[chapter(by_page[pid][0]["path"])].append(pid)
tot = Counter(); cov = Counter()
for it in out:
    tot[it["kind"]] += 1; cov[it["kind"]] += it["covered"]
L = []
L.append(f"# grandMA3 console checklist (help version {VER})\n")
L.append("Every feature, menu, setting, button, command and Lua function in the grandMA3 help, checked against "
         "what this project knows (N), can read through the plugin (R) and has proven on the desk (P). "
         "M marks a worked example in MA's own Lua shipped with onPC (a lead to study, not coverage). "
         "A ticked box means P, or N and R together. Unticked items are the to-do list. "
         "Built by `tools/atlas/checklist.py` from the help download and the console class census; "
         "the evidence for every mark is in `checklist.json`. Marks are automatic name matches: a wrong tick is "
         "a bug in the matcher, fix the rule and rebuild.\n")
L.append(f"Census: `{os.path.basename(CENSUS)}`, {len(census)} classes. Out of scope: the 414 hardware quick-manual pages "
         "and the release-note bug lists (topics only).\n")
L.append("| Kind | Items | Covered | Open |\n| --- | ---: | ---: | ---: |")
for k, n in tot.most_common():
    L.append(f"| {k} | {n} | {cov[k]} | {n - cov[k]} |")
L.append(f"| **all** | **{sum(tot.values())}** | **{sum(cov.values())}** | **{sum(tot.values()) - sum(cov.values())}** |\n")
L.append("## Chapters\n\n| Chapter | Items | Covered |\n| --- | ---: | ---: |")
for ch, pids in chap_pages.items():
    its = [i for p in pids for i in by_page[p]]
    L.append(f"| [{ch}](#{re.sub(r'[^a-z0-9 -]', '', ch.lower()).replace(' ', '-')}) | {len(its)} | {sum(i['covered'] for i in its)} |")
L.append("")
for ch, pids in chap_pages.items():
    L.append(f"## {ch}\n")
    for pid in pids:
        its = by_page[pid]; head = its[0]
        topic = next((i for i in its if i["kind"] in ("topic", "keyword", "option-keyword", "lua-function")), head)
        L.append(f"### [{topic['name']}]({url}{pid}.html)\n")
        for i in its:
            marks = "".join(k if i.get(k) else "·" for k in ("N", "R", "P", "M"))
            box = "x" if i["covered"] else " "
            sec = f" ({i['section']})" if i["section"] and i["kind"] not in ("section", "topic") else ""
            label = "page" if i is topic else i["kind"]
            L.append(f"- [{box}] `{marks}` {label}: {i['name']}{sec}")
        L.append("")
open(os.path.join(REPO, "docs", "atlas", "CHECKLIST.md"), "w").write("\n".join(L))
print(f"{len(out)} items, covered {sum(cov.values())}"); print(tot.most_common()); print(cov.most_common())
