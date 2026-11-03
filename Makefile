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

ONPC_PLUGINS := $(HOME)/MALightingTechnology/gma3_2.5.1/shared/resource/lib_plugins/ma3_mcp
# Copies the spike plugins (and dist/ once it exists) into onPC's plugin folder.
install-onpc:
	@mkdir -p "$(ONPC_PLUGINS)"
	@cp spike/gate-zero/*.lua spike/gate-zero/*.xml spike/onpc-facts/*.lua spike/onpc-facts/*.xml "$(ONPC_PLUGINS)/"
	@[ -d dist ] && cp dist/*.lua dist/*.xml "$(ONPC_PLUGINS)/" 2>/dev/null || true
	@ls -1 "$(ONPC_PLUGINS)"
