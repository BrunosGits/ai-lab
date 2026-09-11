# Debugger Setup Checklist

## ZeroBrane Studio
- [ ] Install ZeroBrane Studio v2.01 2023
- [ ] Set Project Directory to `CorsixTH/CorsixTH`
- [ ] Set Lua Interpreter to Lua 5.4
- [ ] Start Debugger Server
- [ ] Add MobDebug bootstrap to `CorsixTH.lua` (Windows/Linux/macOS paths)
- [ ] Launch CorsixTH and verify "Debugging session started"
- [ ] Test breakpoint on the fly and hover value

## Debugger.lua
- [ ] Download `debugger.lua` to `CorsixTH/CorsixTH/Lua`
- [ ] Add `local dbg = require('debugger')` and `dbg()` call
- [ ] Run CorsixTH from terminal
- [ ] Verify `debugger.lua>` prompt on breakpoint
- [ ] Test with statically compiled build

## Eclipse LDT
- [ ] Install Eclipse and `luarocks install luasocket`
- [ ] Create `debug_script.lua` with test code
- [ ] Set `debug = true` in config
- [ ] Start CorsixTH not fullscreen
- [ ] Set breakpoint and start DBGp server
- [ ] Press Ctrl+C to connect, Shift+D to run script
- [ ] Test F5 step into, F6 step over, F8 resume

## VSCode
- [ ] Follow https://github.com/CorsixTH/CorsixTH/wiki/Setting-Up-Visual-Studio-Code

## Live Reload
- [ ] Add `self:reloadFile("dialogs/...")` to class
- [ ] Test reload via button click

## Related Pages

- [[27-debugger/SUMMARY]]
- [[27-debugger/MAP]]
- [[27-debugger/SCAFFOLD]]
