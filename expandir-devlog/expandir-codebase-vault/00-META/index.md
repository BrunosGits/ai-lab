# Expandir Codebase Vault

A codebase study vault for the espanso text expander (Rust + C++/ObjC),
used as reference for implementing features in the expandir fork.

## Quick Links

### Architecture Docs
- [[event-pipeline]] - The core detect → match → render → inject flow
- [[config-system]] - YAML parsing, stores, hot-reload
- [[daemon-worker-ipc]] - IPC model, process lifecycle
- [[middleware-pattern]] - Engine middleware pipeline
- [[platform-abstraction]] - How platform code is abstracted

### Core
- [[CODEBASE_MAP]] - Project overview, crate sizes, build commands
- [[ARCHITECTURE]] - Event pipeline, middleware, dispatch
- [[CRATE_DEPENDENCIES]] - How crates depend on each other

### Subsystem Studies (13)
- [[01-event-pipeline]] - Core flow: detect → match → render → inject
- [[02-espanso-detect]] - Keyboard/input detection
- [[03-espanso-inject]] - Keyboard injection
- [[04-espanso-match]] - Pattern matching engine
- [[05-espanso-config]] - Configuration parsing
- [[06-espanso-render]] - Template rendering
- [[07-espanso-engine]] - Engine middleware & dispatch ← COMPLETE
- [[08-espanso-clipboard]] - Clipboard operations
- [[09-espanso-modulo]] - GUI components
- [[10-espanso-ui]] - System tray UI
- [[11-espanso-package]] - Package management
- [[12-cli-commands]] - CLI structure
- [[13-match-extensions]] - Built-in extensions

### Platform Studies
- [[macOS]] - ObjC FFI, accessibility, secure input
- [[Windows]] - Win32 API, smart screen
- [[Linux]] - X11, Wayland, evdev, uinput

### Fork Tracking
- [[expandir-changes]] - What's different from upstream
- [[feature-roadmap]] - Planned features
- [[branch-strategy]] - Branch management

### Queries
- [[code-refs]] - Cross-references
- [[grep-patterns]] - Useful grep commands

## Study Progress

| Subsystem | Status | Last Updated |
|-----------|--------|-------------|
| espanso-engine | COMPLETE | 2026-08-25 |
| All others | SKELETON | 2026-08-25 |
