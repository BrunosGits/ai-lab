# Debugger File:Line Index

## Overview

This map indexes the files involved in debugging CorsixTH's Lua code.

## Core Files

| File | Lines | Symbol | Description |
|------|-------|--------|-------------|
| `CorsixTH/CorsixTH/CorsixTH.lua` | 1-20 | `package.path` `mobdebug` | Bootstrap for ZeroBrane MobDebug |
| `CorsixTH/CorsixTH/Lua/debugger.lua` | 1-1 | `dbg()` | Single-file debugger via stdin/out |
| `CorsixTH/CorsixTH/Lua/app.lua` | 300-310 | `MoviePlayer` `debug` | Debug flag handling |
| `CorsixTH/CorsixTH/Lua/config_finder.lua` | 1-50 | `debug` | Config debug = true for Eclipse |
| `CorsixTH/CorsixTH/Lua/ui.lua` | 880-900 | `debug_script` | Debug script loading via Shift+D |

## Wiki Pages

| Wiki Page | Vault Section | Description |
|-----------|---------------|-------------|
| `Debugger-Tutorials` | `27-debugger` | ZeroBrane, debugger.lua, Eclipse, VSCode, Live Reload |

## Related Pages

- [[27-debugger/SUMMARY]]
- [[27-debugger/CHECKLIST]]
- [[27-debugger/SCAFFOLD]]
