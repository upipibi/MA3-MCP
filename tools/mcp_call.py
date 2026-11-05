#!/usr/bin/env python3
"""Call one tool on the console's MA3 MCP server, the same JSON-RPC a Claude Code session sends.

Reads the URL and Authorization header of the `ma3` server from ~/.claude.json, so the PIN is never
on a command line or in this repo. For when a session's own connector is stale (after a PIN change).
usage: mcp_call.py <tool> ['<json arguments>']     e.g. mcp_call.py ma3_status
       mcp_call.py --list                          (tool names and input schemas)
Prints the tool's result as JSON. Exit 1 on an error result, 2 on HTTP failure (429 = locked out)."""
import json, os, sys, urllib.request, urllib.error

def server():
    cfg = json.load(open(os.path.expanduser("~/.claude.json")))
    s = cfg["mcpServers"]["ma3"]
    return s["url"], s.get("headers", {})

def rpc(method, params, timeout=180):
    url, headers = server()
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={**headers, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:300]}", file=sys.stderr); sys.exit(2)

def call(tool, args=None):
    r = rpc("tools/call", {"name": tool, "arguments": args or {}})
    if "error" in r: return False, r["error"]
    res = r["result"]; text = res["content"][0]["text"] if res.get("content") else ""
    try: val = json.loads(text)
    except ValueError: val = text
    return not res.get("isError"), val

if __name__ == "__main__":
    if sys.argv[1] == "--list":
        for t in rpc("tools/list", {})["result"]["tools"]:
            print(t["name"], json.dumps(t.get("inputSchema", {}).get("properties", {})))
        sys.exit(0)
    ok, val = call(sys.argv[1], json.loads(sys.argv[2]) if len(sys.argv) > 2 else {})
    print(json.dumps(val, indent=1) if not isinstance(val, str) else val)
    sys.exit(0 if ok else 1)
