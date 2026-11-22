#!/usr/bin/env python3
"""Program the four Nov 29 songs (Sequences 10-13) from Aaron's own cues on the current rig.

Each stored cue is a status copy (the full look, tracking included) of the cue in one of his finished
songs that plays the same role; each hold is an empty cue, as he leaves them. Sent through onPC as
the MCP user: no programmer of his and no output is touched. One undo group per song.
usage: build.py plan | run | verify"""
import json, os, subprocess, sys, time
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.join(HERE, "..", "..", "..")
H = None   # a hold
SONGS = [
 {"seq": 10, "title": "Thank The Lord", "donor": 6, "donor_name": "Praise", "cues": [
   ("Start - Thank The Lord", 1, "Start - Praise"), ("-> Follows", 2, "-> Follows"), ("Intro", H), ("Verse 1", 5, "Verse 1"), ("Pre Chorus 1", H), ("Interlude", H),
   ("Verse 2", H), ("Pre Chorus 2", H), ("Chorus / Hits", 18, "Chorus 1 / Breakdown"), ("Interlude", H), ("Verse 3", 9, "Verse 3"), ("Pre Chorus 3", H),
   ("Chorus / Hits", 18, "Chorus 1 / Breakdown"), ("Post Chorus 1", H), ("Post Chorus 2", H), ("Refrain 1 / All In", 8, "Chorus 1 / All In"),
   ("Bridge 1 / Kick", 17, "Bridge / Slowly Build"), ("Bridge 2", H), ("Bridge 1", H), ("Bridge 2 / Build", 18, "Chorus 1 / Breakdown"),
   ("Chorus / Hits", 20, "Build / Chorus 1 / All In"), ("Post Chorus 1", H), ("Post Chorus 2", H), ("Refrain 2", H), ("End", 26, "End")]},
 {"seq": 11, "title": "This Is Our God", "donor": 7, "donor_name": "Weight of Glory", "cues": [
   ("Start - This Is Our God", 1, "Start - Weight of Glory"), ("-> Follows", 2, "-> Follows"), ("Intro", H), ("Verse 1", 5, "Verse 1"), ("Turnaround", H), ("Verse 2", H),
   ("Turnaround", H), ("Chorus / Breakdown", 7, "Chorus / Breakdown"), ("Drums In", 8, "Instrumental / All In"), ("Turnaround", H), ("Verse 3", 9, "Verse 2"), ("Verse 4", H),
   ("Vamp / Build", 16, "Build"), ("Chorus / All In", 18, "Chorus / All In"), ("-> Follows", 19, "-> Follows"), ("Vamp", H), ("Bridge 1 / Breakdown", 13, "Bridge / Breakdown"),
   ("Bridge 2 / Drums In", 8, "Instrumental / All In"), ("(Build)", 16, "Build"), ("(HOLD / HIT)", H), ("Chorus", 18, "Chorus / All In"), ("Tag", H), ("Outro", H), ("Ending", 22, "End")]},
 {"seq": 12, "title": "Manger to the Cross", "donor": 5, "donor_name": "Goodness Of God", "cues": [
   ("Start - Manger to the Cross", 1, "Start - Goodness of God"), ("-> Follows", 2, "-> Follows"), ("Intro", H), ("Verse 1", H), ("Verse 2", H), ("Pre Chorus", H),
   ("Chorus / Breakdown", 12, "Interlude / Breakdown"), ("Interlude", H), ("Verse 3", 6, "Verse 2"), ("Pre Chorus", H), ("Chorus", 7, "Chorus"), ("Instrumental", H),
   ("Bridge 1", 8, "Bridge"), ("Bridge 1", H), ("Bridge 2", 10, "Bridge"), ("Bridge 2 / Build", 14, "Vamp / Build"), ("Chorus / Breakdown", 12, "Interlude / Breakdown"), ("End", 18, "End")]},
 {"seq": 13, "title": "King Of Kings/Angels We Have Heard on High", "donor": 8, "donor_name": "Abide", "cues": [
   ("Start - King Of Kings", 1, "Start - Abide"), ("-> Follows", 2, "-> Follows"), ("Intro", H), ("Verse 1", H), ("Turnaround", H), ("Chorus", 5, "Chorus 1"), ("Turnaround", H),
   ("Verse 2 / Drums In", 7, "Verse 2 / Drums In"), ("Turnaround", H), ("Chorus", 8, "Chorus 1"), ("Turnaround", H), ("Verse 3 / Breakdown", 10, "Turnaround / Breakdown"),
   ("Build", 12, "Drums In"), ("Verse 4 / All In", 13, "Build"), ("-> Follows", 18, "-> Follows"), ("Turnaround / Build", 12, "Drums In"), ("(Build)", H),
   ("Chorus / All In", 13, "Build"), ("Tag / Breakdown", 17, "Interlude / Breakdown"), ("Vamp", H), ("Vamp / Build", 12, "Drums In"), ("Bridge / All In", 13, "Build"),
   ("Bridge", H), ("Tag / Breakdown", 17, "Interlude / Breakdown"), ("Tag", H), ("Instrumental", H), ("Refrain / Angels", 8, "Chorus 1"), ("Refrain", H), ("Refrain", H),
   ("Refrain / All In", 13, "Build"), ("Refrain", H), ("Ending", 24, "Outro")]},
]
def call(tool, args):
    r = subprocess.run([sys.executable, os.path.join(REPO, "tools", "onpc_call.py"), tool, json.dumps(args)], capture_output=True, text=True, timeout=240); time.sleep(0.15)
    return json.loads(r.stdout)
def timing(seq): return {c["cue"]: c for c in call("ma3_cue_timing", {"sequence": seq}).get("cues", [])}
def commands(song):
    out = []
    for n, c in enumerate(song["cues"], 1):
        name, src = c[0], c[1]
        if src is H:
            out += [f'Store Sequence {song["seq"]} Cue {n}', f'Label Sequence {song["seq"]} Cue {n} "{name}"', f'Set Sequence {song["seq"]} Cue {n} Part 0 Property "CueInFade" 2']
        else:
            # ForceRelease: a value that tracks in from an earlier cue and that the source look does not hold is released,
            # so the cue equals its source look even when source cues are used out of their own order (found on Sequence 12).
            out += [f'Copy Sequence {song["donor"]} Cue {src} At Sequence {song["seq"]} Cue {n} /CopyCueSource "Status"' + (' /CopyCueDestination "Overwrite"' if n == 1 else ' /CopyCueDestination "ForceRelease"'),
                    f'Label Sequence {song["seq"]} Cue {n} "{name}"']
    return out
mode = sys.argv[1] if len(sys.argv) > 1 else "plan"
if mode == "plan":
    for s in SONGS:
        stored = sum(1 for c in s["cues"] if c[1] is not H)
        print(f'Sequence {s["seq"]} {s["title"]}: {len(s["cues"])} cues, {stored} stored, {len(s["cues"]) - stored} holds, from {s["donor_name"]} ({len(commands(s))} commands)')
elif mode == "run":
    me = call("ma3_programmer", {"profile": 7})["plugin"]
    if not (me["user"] == "User 9" and me["programmer_empty"]): sys.exit(f"not the MCP user with an empty programmer: {me}")
    running = [r["no"] for r in call("ma3_playbacks", {"executors": False})["rows"]]
    for s in SONGS:
        if s["seq"] in running or s["donor"] in running: sys.exit(f'Sequence {s["seq"]} or its donor {s["donor"]} is running: not now')
        tgt, don = timing(s["seq"]), timing(s["donor"])
        if [(k, v["name"]) for k, v in tgt.items()] != [(1, "Cue 1")]: sys.exit(f'Sequence {s["seq"]} is not the empty one-cue sequence any more: {list(tgt.items())[:3]}')
        bad = [(c[1], c[2], don.get(c[1], {}).get("name")) for c in s["cues"] if c[1] is not H and don.get(c[1], {}).get("name", "").strip() != c[2].strip()]
        if bad: sys.exit(f'donor cues moved in Sequence {s["donor"]}: {bad}')
    for s in SONGS:
        cmds = commands(s); G = f'nov29-{s["seq"]}'; sent = 0
        for i in range(0, len(cmds), 200):
            r = call("ma3_commands", {"commands": cmds[i:i + 200], "undo_group": G, **({"close_undo": True} if i + 200 >= len(cmds) else {})})
            badr = [(x["command"], x["result"]) for x in r.get("results", []) if x["result"] != "OK"]
            sent += r.get("sent", 0)
            if badr: print("STOPPED", s["seq"], badr[:3]); sys.exit(1)
        print(f'Sequence {s["seq"]} {s["title"]}: {sent} commands sent, undo group {G}')
elif mode == "verify":
    W = os.path.join(REPO, "docs", "research", "shows", "christmas-2026-study"); ok_all = True
    for s in SONGS:
        t = timing(s["seq"]); don = timing(s["donor"])
        for num in (s["seq"], s["donor"]):
            d = call("ma3_export", {"address": f"Sequence {num}", "max_bytes": 80000000}); assert not d.get("truncated"); open(f"{W}/seq{num}.xml", "w").write(d["xml"])
            subprocess.run([sys.executable, "-I", os.path.join(REPO, "tools", "song_looks.py"), f"{W}/seq{num}.xml", f"{W}/fixtures.json", "--json", f"{W}/looks{num}.json"], capture_output=True)
        new = json.load(open(f"{W}/looks{s['seq']}.json"))["cues"]; old = {int(c["no"]): c for c in json.load(open(f"{W}/looks{s['donor']}.json"))["cues"] if c["no"].isdigit()}
        problems = []
        if len(new) != len(s["cues"]): problems.append(f"{len(new)} cues, planned {len(s['cues'])}")
        for n, c in enumerate(s["cues"], 1):
            got = new[n - 1] if n - 1 < len(new) else None
            if not got: continue
            if got["name"] != c[0]: problems.append(f"cue {n} is named {got['name']!r}")
            if c[1] is H:
                if got["changes"]: problems.append(f"hold {n} stores values")
                if t.get(n, {}).get("in_fade") != 2: problems.append(f"hold {n} fade {t.get(n, {}).get('in_fade')}")
            else:
                if got["state"] != old[c[1]]["state"]: problems.append(f"cue {n} does not equal {s['donor_name']} cue {c[1]}")
                if t.get(n, {}).get("trigger") != don[c[1]]["trigger"] or t.get(n, {}).get("in_fade") != don[c[1]]["in_fade"]: problems.append(f"cue {n} trigger or fade differs from its source")
        ok_all &= not problems
        print(f'Sequence {s["seq"]} {s["title"]}: {len(new)} cues;', "all as planned" if not problems else problems[:6])
        print("   " + " | ".join(f'{n} {c["name"]}{" [F]" if c["trigger"] == "Follow" else ""} {c["in_fade"]:g}s' for n, c in sorted(t.items())))
    print("VERIFIED" if ok_all else "MISMATCH")
