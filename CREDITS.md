# Credits

## Frameworks & Libraries

| Name | Description | License |
|------|-------------|---------|
| [LuaSocket](https://github.com/lunarmodules/luasocket) | TCP sockets. Shipped inside grandMA3; this project does not redistribute it. The test harness installs its own copy through LuaRocks. | MIT |
| [json.lua](https://github.com/rxi/json.lua) by rxi | JSON encode/decode. Shipped inside grandMA3 (`lib_plugins/requirements/json.lua`); `test/vendor/json.lua` is a copy for the Mac test harness only. | MIT |

## Tools

| Name | Use |
|------|-----|
| Lua 5.4 (Homebrew `lua@5.4`) | Test harness interpreter |
| LuaRocks | Installs LuaSocket for the test harness |
| grandMA3 onPC 2.5.1 | Development bench |

## Inspiration

- [gma3-mcp](https://github.com/bdstark/gma3-mcp) (MIT): the non-blocking LuaSocket server loop inside a plugin and the 2.5.1 probe records (ObjectList range hang, dialogs stalling the plugin thread, SaveShow via CmdIndirect, tag handles).
- [MA3-MCP-Server](https://github.com/Pahegi/MA3-MCP-Server) (AGPL-3.0): the file-IPC alternative we chose not to use.
- MA Lighting's shipped `gma3_webserver.lua` and `webserver_example` plugin: the Timer-task lifecycle for a listening socket.
- [Model Context Protocol specification 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28).

grandMA3 and MA Lighting are trademarks of MA Lighting Technology GmbH. This project is independent and not affiliated with or endorsed by MA Lighting.
