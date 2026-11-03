# The console runs Lua 5.5 (verified on onPC 2.5.1.1); tests run on Homebrew lua (5.5) by
# default and on lua@5.4 with `make test LUAV=5.4` as a compatibility check.
LUAV ?= 5.5
ifeq ($(LUAV),5.4)
LUA ?= $(shell brew --prefix lua@5.4)/bin/lua
else
LUA ?= $(shell brew --prefix lua)/bin/lua
endif
ROCKS := $(HOME)/.luarocks
BREWLUA := $(shell brew --prefix)
LUA_PATH_T := ./src/?.lua;./src/?/init.lua;./test/vendor/?.lua;./test/?.lua;$(ROCKS)/share/lua/$(LUAV)/?.lua;$(ROCKS)/share/lua/$(LUAV)/?/init.lua;$(BREWLUA)/share/lua/$(LUAV)/?.lua;$(BREWLUA)/share/lua/$(LUAV)/?/init.lua;;
LUA_CPATH_T := $(ROCKS)/lib/lua/$(LUAV)/?.so;$(BREWLUA)/lib/lua/$(LUAV)/?.so;;

.PHONY: test build install-onpc release
test:
	@LUA_PATH="$(LUA_PATH_T)" LUA_CPATH="$(LUA_CPATH_T)" $(LUA) test/run.lua

# Bundle every src module into one plugin file the console can import.
build:
	@mkdir -p dist
	@$(LUA) tools/bundle.lua "dist/MA3 MCP.lua"
	@cp "plugin/MA3 MCP.xml" dist/
	@$(dir $(LUA))luac -p "dist/MA3 MCP.lua" && echo "dist/MA3 MCP.lua compiles ($$(wc -c < 'dist/MA3 MCP.lua') bytes)"

# onPC imports plugins from the library's datapools/plugins folder:
#   Import Plugin Library "MA3 MCP.xml" At Plugin <n>
# ... and after the first import, ReloadAllPlugins re-reads the component from
# shared/resource/lib_plugins/<Path>/<FileName>, so the Lua goes to both places.
ONPC_LIBRARY := $(HOME)/MALightingTechnology/gma3_library/datapools/plugins
ONPC_LIB_PLUGINS := $(HOME)/MALightingTechnology/gma3_2.5.1/shared/resource/lib_plugins/ma3_mcp
install-onpc: build
	@mkdir -p "$(ONPC_LIBRARY)" "$(ONPC_LIB_PLUGINS)"
	@cp "dist/MA3 MCP.lua" "dist/MA3 MCP.xml" spike/gate-zero/*.lua spike/gate-zero/*.xml "$(ONPC_LIBRARY)/"
	@cp "dist/MA3 MCP.lua" spike/gate-zero/*.lua "$(ONPC_LIB_PLUGINS)/"
	@ls -1 "$(ONPC_LIB_PLUGINS)" | grep 'MA3 MCP'

VERSION := $(shell sed -n 's/^M.VERSION = "\(.*\)"/\1/p' src/main.lua)
release: build
	@rm -f dist/avl-ma3-mcp-*.zip
	@mkdir -p dist/stage && cp "dist/MA3 MCP.lua" "dist/MA3 MCP.xml" docs/CONVENTIONS.md docs/INSTALL-CONSOLE.md dist/stage/
	@cd dist/stage && zip -q "../avl-ma3-mcp-$(VERSION).zip" "MA3 MCP.lua" "MA3 MCP.xml" CONVENTIONS.md INSTALL-CONSOLE.md
	@rm -rf dist/stage && ls -1 dist/avl-ma3-mcp-*.zip
