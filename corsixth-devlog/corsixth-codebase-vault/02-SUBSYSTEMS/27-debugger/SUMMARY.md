# Debugging in CorsixTH

## Overview

This document covers the debugging options for CorsixTH's Lua code, based on the wiki's Debugger Tutorials. Three main debuggers are supported, plus live code reloading for rapid iteration.

## 1. ZeroBrane Studio

**Type:** Full IDE with GUI, uses MobDebug over TCP via luasocket.

**Setup:**
- Install ZeroBrane Studio v2.01 2023, set Project Directory to `CorsixTH/CorsixTH`, set Lua Interpreter to Lua 5.4, start Debugger Server, open `CorsixTH.lua` and add at top:
  - Windows: `local zbs = 'D:/path/to/ZeroBraneStudio' package.path = zbs .. '/lualibs/?/?.lua;' .. zbs .. '/lualibs/?.lua;' .. package.path package.cpath = zbs .. '/bin/?.dll;' .. zbs ..'/bin/clibs54/?.dll;' .. package.cpath require('mobdebug').start()`
  - Linux: `local zbs = '/path/to/ZeroBraneStudio' package.path = zbs .. '/lualibs/?/?.lua;' .. zbs .. '/lualibs/?.lua;' .. package.path package.cpath = zbs .. '/bin/linux/x64/?.dll;' .. zbs ..'/bin/linux/x64/clibs54/?.dll;' .. package.cpath require('mobdebug').start()`
  - macOS: `local zbs = '/path/to/ZeroBraneStudio.app/Contents/ZeroBraneStudio' package.path = zbs .. '/lualibs/?/?.lua;' .. zbs .. '/lualibs/?.lua;' .. package.path package.cpath = zbs .. '/bin/?.dylib;' .. zbs ..'/bin/clibs54/?.dylib;' .. package.cpath require('mobdebug').start()`
- Launch CorsixTH, it will freeze and ZeroBrane will show "Debugging session started", use Project > Continue.

**Pros:** Breakpoints on the fly, hover to see values, conventional GUI.
**Cons:** Extra setup, luasocket may not work in all envs, slows execution. On macOS may need `codesign --remove-signature CorsixTH.app`.

## 2. Debugger.lua

**Type:** Single standalone script, uses stdin/out on terminal.

**Setup:**
- Download `debugger.lua` from https://github.com/slembcke/debugger.lua and put in `CorsixTH/CorsixTH/Lua` (or lua path).
- Add `local dbg = require('debugger')` at top of file to debug, call `dbg()` where you want to break.
- Run CorsixTH from terminal: `cd path_to_CorsixTH.app/Contents/MacOS && ./CorsixTH` (macOS) or `cd CorsixTH && ./CorsixTH` (Linux/Windows). When breakpoint hits, you get `debugger.lua>` prompt in terminal.

**Pros:** Easy to integrate, terminal based, works with statically compiled CorsixTH where luasocket debuggers fail.
**Cons:** No live breakpoint updating, no code view.

## 3. Eclipse LDT

**Type:** Eclipse plugin with DBGp server, requires luasocket via `luarocks install luasocket`.

**Setup:** Via `https://github.com/CorsixTH/CorsixTH/wiki/Setting-Up-Eclipse-(Any-OS)#setup_lua_debugging`. Create `debug_script.lua` with test code, set `debug = true` in config, start CorsixTH, set Eclipse to not fullscreen, add breakpoint, start DBGp server via Debug Configurations, switch to Debug perspective, press Ctrl+C in CorsixTH to connect, or start with `--connect-lua-dbgp`, then Shift+D to run debug script. Use F6 step over, F5 step into, F8 resume.

**Note:** Eclipse LDT has not been updated in many years and is no longer recommended. Debuggers that depend on luasocket may not work if CorsixTH is compiled statically (default linux-vcpkg and all macos presets).

## 4. VSCode

See `https://github.com/CorsixTH/CorsixTH/wiki/Setting-Up-Visual-Studio-Code`.

## 5. Live Code Reloading

Developer mode that dynamically reloads Lua. See https://gist.github.com/4034387. Put `self:reloadFile("dialogs/fullscreen/progress_report.lua")` in classes you need to reload, e.g.:

```lua
function UIBottomPanel:dialogStatus()
  self:reloadFile("dialogs/fullscreen/progress_report.lua")
  self:addDialog(UIProgressReport(self.ui))
end
```

This reloads the ProgressReport dialog every time you click the progress report button.

## Related Pages

- [[27-debugger/MAP]]
- [[27-debugger/CHECKLIST]]
- [[27-debugger/SCAFFOLD]]
