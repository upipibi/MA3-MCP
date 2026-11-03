LUA ?= $(shell brew --prefix lua@5.4)/bin/lua
ROCKS := $(HOME)/.luarocks
LUA_PATH_T := ./src/?.lua;./src/?/init.lua;./test/vendor/?.lua;./test/?.lua;$(ROCKS)/share/lua/5.4/?.lua;$(ROCKS)/share/lua/5.4/?/init.lua;;
LUA_CPATH_T := $(ROCKS)/lib/lua/5.4/?.so;;

.PHONY: test build install-onpc release
test:
	@LUA_PATH="$(LUA_PATH_T)" LUA_CPATH="$(LUA_CPATH_T)" $(LUA) test/run.lua
