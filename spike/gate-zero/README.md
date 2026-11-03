# Gate zero: does a listener work on the real console?

Throwaway test. It proves one thing: a Lua plugin on the grandMA3 light can open a TCP
listener on the console's production-network address and answer a laptop, while the
desk stays responsive. Nothing in it touches the showfile beyond storing one plugin in an
empty pool slot.

## On the console (Aaron)

1. Copy both files in this folder to a USB stick at
   `grandMA3/gma3_library/datapools/plugins/`.
2. Plug the stick into the console. In the command line:

   ```
   Import Plugin Library "MA3 MCP Gate Zero.xml" At Plugin 90
   Plugin "MA3 MCP Gate Zero" "<console-ip>"
   ```

   (Plugin 90 must be empty; pick another empty slot if not, and use it below.)
3. The command line history / System Monitor shows `GateZero: listening on <console-ip>:9800 for 60 s`.
   The listener stops by itself after 60 seconds.

## From the laptop (within those 60 seconds)

```
curl -s http://<console-ip>:9800/
```

Expected: `MA3 MCP OK`. The console prints `GateZero: served <production network> (...)`.
While it runs, touch a view or two on the console: the UI must stay responsive.

## Afterwards

```
Delete Plugin 90 /NoConfirmation
```

Do not save the show with the plugin in it. Report what the console printed, including
any `BIND FAILED` line.
