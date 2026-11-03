# Security

## What listens

The plugin opens one TCP listener on the console, port 9800, bound to the console's production-network address only (never the lighting network, never all interfaces). It speaks plain HTTP; the console's Lua has no TLS.

## Who can talk to it

Every request must carry `Authorization: Bearer <PIN>`. The PIN is 8 characters, shown only in the plugin window on the console, and regenerated there. A wrong PIN gets HTTP 401 and is listed in the window; five wrong PINs from one address within a minute lock that address out for five minutes. A request with no `Authorization` header counts as a wrong PIN, so an unauthenticated probe that retries locks itself out too; that is intended.

`ma3_command` refuses `Lua`, `LuaFile`, `SaveShow`, `LoadShow` and `NewShow`: the only way to run Lua is `ma3_lua`, which is off unless the operator enables it in the window, and the only save paths are `ma3_save` and `ma3_backup`. The Lua sandbox removes `io`, `require`, `package`, `loadfile`, `dofile`, `debug`, `lfs` and the process/file functions of `os`.

The plugin ships off and is started by the operator after loading a show. Arbitrary Lua execution is off at every start and is enabled only in the window.

## What it can do

With the PIN, a client can read every object in the showfile and run any console command, so treat the PIN like console access. Keep the production network's membership in mind: anyone on it with the PIN can drive the desk.

## Reporting

Report a problem to the repository owner (Aaron Larson, Northwoods Community Church) by GitHub issue if it is not sensitive, or directly if it is.
