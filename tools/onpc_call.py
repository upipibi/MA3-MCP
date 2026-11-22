#!/usr/bin/env python3
"""Call the MA3 MCP plugin running in grandMA3 onPC on this Mac (the MCP user's station).

    python3 tools/onpc_call.py <tool> '<json args>'      python3 tools/onpc_call.py --list

Reads the port and PIN from onPC's own settings file, so neither is typed or stored in this repo,
then hands over to tools/mcp_call.py. Jobs and exploratory reads go this way: onPC is logged in as
the MCP user (own programmer, selection, command line) and a read that hangs stalls onPC, not the desk.
"""
import json, os, subprocess, sys

SETTINGS = os.path.expanduser("~/MALightingTechnology/gma3_library/ma3_mcp_settings.json")

def main():
    s = json.load(open(SETTINGS))
    env = dict(os.environ, MA3_MCP_URL="http://127.0.0.1:%s/mcp" % s.get("port", 9800), MA3_MCP_PIN=str(s.get("pin", "")))
    here = os.path.dirname(os.path.abspath(__file__))
    return subprocess.call([sys.executable, os.path.join(here, "mcp_call.py"), *sys.argv[1:]], env=env)

if __name__ == "__main__":
    sys.exit(main())
