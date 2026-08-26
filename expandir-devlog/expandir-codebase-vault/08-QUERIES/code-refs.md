# Cross-References

## Code References by Topic

### Engine Pipeline
- [[07-espanso-engine/MAP]] — espanso-engine file:line index
- [[07-espanso-engine/SUMMARY]] — espanso-engine analysis
- [[01-CORE/ARCHITECTURE]] — Full event pipeline architecture

### Matching
- espanso-match crate — Pattern matching algorithms
- espanso-engine/process/middleware/matcher.rs — MatcherMiddleware
- espanso-engine/process/middleware/alt_code_synthesizer.rs — Alt code handling

### Injection
- espanso-inject crate — Platform-specific injection
- espanso-engine/dispatch/executor/text_inject.rs — Text injection
- espanso-engine/dispatch/executor/key_inject.rs — Key injection

### Configuration
- espanso-config crate — YAML parsing, stores
- espanso-engine/process/middleware/config.rs — Config folder opening

### GUI
- espanso-modulo crate — GUI components (search bar, forms, wizard)
- espanso-ui crate — System tray

### Platform-Specific
- espanso-detect — Input detection (macOS/Win32/Linux)
- espanso-inject — Keyboard injection (macOS/Win32/Linux)
- espanso-mac-utils — macOS Objective-C FFI

## Shared Types

- `Event` — espanso-engine/event/mod.rs — All events share this
- `EventType` — espanso-engine/event/mod.rs — 40+ event variants
- `Key` — espanso-detect — 60+ key variants
- `MatchResult` — espanso-engine/process/middleware/matcher.rs — Match detection result
- `TextInjectRequest` — espanso-engine/event/effect.rs — Text to inject

## Crate Connections

```
espanso (main)
├── espanso-engine ←→ espanso-match (matcher)
├── espanso-engine ←→ espanso-render (renderer)
├── espanso-engine ←→ espanso-inject (text/key injector)
├── espanso-engine ←→ espanso-clipboard (text injector)
├── espanso-engine ←→ espanso-modulo (text UI)
├── espanso-engine ←→ espanso-ui (icon, context menu)
├── espanso-engine ←→ espanso-config (config data)
└── espanso (main) ←→ espanso-ipc (IPC)
```

## Platform Code Locations

### macOS
- espanso-detect/src/mac/ — CGEvent, accessibility
- espanso-inject/src/mac/ — CGEvent post
- espanso-mac-utils/ — Objective-C FFI

### Windows
- espanso-detect/src/win32/ — Win32 hooks
- espanso-inject/src/win32/ — SendInput

### Linux
- espanso-detect/src/x11/ — X11 XRecord
- espanso-detect/src/evdev/ — evdev input
- espanso-inject/src/x11/ — xdotool, xclip
- espanso-inject/src/evdev/ — uinput
