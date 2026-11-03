# Installing MA3 MCP on the grandMA3 light

Target: grandMA3 light, software 2.5.1.1, production-network address <console-ip>. The plugin
listens on port 9800 on that address only.

## Files

From the release zip: `MA3 MCP.lua` and `MA3 MCP.xml`.

## First install

1. Copy both files to a USB stick at `grandMA3/gma3_library/datapools/plugins/`.
2. Plug the stick into the console. In the command line, with an Admin user:

   ```
   Import Plugin Library "MA3 MCP.xml" At Plugin 91
   ```

   Use any empty Plugin pool slot. If the slot is not empty the import fails; pick another.
3. Save the show so the plugin stays in it.
4. Start it: tap the plugin in the Plugins pool, or type `Plugin "MA3 MCP"`.
   The window opens with the address, the PIN and the On/Off button.
   The command line history shows `MA3 MCP v0.1.0: listening on <console-ip>:9800`.

The plugin ships off. After every show load, start it again (one tap).

## Connect a client

On a machine on the production network:

```
claude mcp add --transport http ma3 http://<console-ip>:9800/mcp --header "Authorization: Bearer <PIN>" --scope user
```

The PIN is in the window (Regenerate makes a new one; reconnect clients afterwards).
Smoke test in Claude Code: ask for `ma3_status`; it returns the show name.

## Day to day

- Window buttons: On/Off, Regenerate PIN, Allow Lua execution (off at every start), the
  last ten clients (bad PINs in the list), the last five backups, and which display the
  window opens on.
- After tapping the window, tap the command line before typing a command; the overlay
  keeps keyboard focus otherwise.
- Command-line arguments: `Plugin "MA3 MCP" "off"`, `"status"`, `"pin"`, `"lua on"`,
  `"lua off"`, `"regen"`, `"bind <console-ip>"` or `"bind auto"`, `"<port>"` (bind and
  port take effect at the next start).
- If the startup line says `listening on 127.0.0.1` on the console, the plugin did not find
  the production-network address by itself: run `Plugin "MA3 MCP" "bind <console-ip>"` once,
  then stop and start it.
- Optional pool-button colour: store an Appearance named exactly `MA3 MCP` (any colour you
  like). While the server runs the plugin's pool button wears it; when stopped it is cleared.
  Without that Appearance the button never changes.
- Settings (PIN, port, display, backups, clients) live in
  `gma3_library/ma3_mcp_settings.json` on the console, not in the show file.
- Log: `onpc/temp/ma3_mcp.log` on onPC; the console's temp folder on hardware.
  `ma3_mcp_load.txt` next to it says whether the last plugin load succeeded.

## Update

Copy the new `MA3 MCP.lua` over the old one in both places the console reads it from:
the USB library folder (for a fresh import) and, on the console, the plugin's own folder
(`shared/resource/lib_plugins/ma3_mcp/`). Then:

```
Plugin "MA3 MCP" "off"
ReloadAllPlugins
Plugin "MA3 MCP"
```

`ReloadAllPlugins` reloads every plugin in the show; pick a quiet moment. If the console
cannot reach `lib_plugins` from a stick, delete the pool slot and import again.

## Uninstall

```
Plugin "MA3 MCP" "off"
Delete Plugin 91 /NoConfirmation
```

Then save the show. The settings file and log can be left or deleted.

## Backups the tools make

`ma3_backup` saves `<first 16 characters of the show name>_mcp_<MMDD_HHMM>` and then
saves the current show again under its own name. The plugin never deletes show files;
prune old `_mcp_` backups from the console's show file list when you like.
