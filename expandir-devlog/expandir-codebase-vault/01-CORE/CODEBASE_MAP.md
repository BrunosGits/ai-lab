# Espanso Codebase Map

## Project Overview
- **Language**: Rust (primary), C++/ObjC (platform bindings)
- **Lines of Code**: ~4,600 lines across 47 files (engine crate alone)
- **Build System**: Cargo workspace
- **License**: GPL-3.0
- **Repository**: https://github.com/espanso/espanso

## Workspace Structure (15 Crates)

| Crate | Files | LOC | Purpose |
|-------|-------|-----|---------|
| **espanso** (main) | 146 | ~8k | CLI, daemon, worker, launcher, service management |
| **espanso-engine** | 47 | ~4.6k | Core event pipeline: funnel → process → dispatch |
| **espanso-modulo** | 45 | ~3k | GUI: search bar, forms, wizard, textview |
| **espanso-detect** | 29 | ~2.5k | Keyboard/input detection (platform-specific) |
| **espanso-inject** | 29 | ~2.5k | Keyboard injection (platform-specific) |
| **espanso-clipboard** | 25 | ~2k | Clipboard operations (platform-specific) |
| **espanso-config** | 21 | ~2k | YAML config parsing, match groups, stores |
| **espanso-package** | 20 | ~1.5k | Package management (hub, git, archives) |
| **espanso-render** | 15 | ~1.2k | Template rendering (extensions: script, shell, date) |
| **espanso-ui** | 15 | ~1k | System tray UI (platform-specific) |
| **espanso-info** | 15 | ~1k | System info (platform-specific) |
| **espanso-match** | 8 | ~600 | Pattern matching (rolling matcher, regex) |
| **espanso-mac-utils** | 5 | ~400 | macOS-specific utilities |
| **espanso-ipc** | 4 | ~300 | Inter-process communication |
| **espanso-kvs** | 2 | ~150 | Key-value storage |

## Directory Structure

### Main Binary (`espanso/src/`)
| Module | Files | Description |
|--------|-------|-------------|
| `cli/` | 40+ | CLI commands: daemon, worker, launcher, edit, package, service |
| `cli/worker/` | 20+ | Worker process: engine setup, context, caches |
| `cli/daemon/` | 5 | Daemon process: IPC, keyboard layout watcher |
| `cli/launcher/` | 5 | Launcher: accessibility, edition check |
| `cli/service/` | 6 | Service management (linux/macos/win) |
| `cli/modulo/` | 6 | GUI wrappers (form, search, textview, wizard) |
| `patch/` | 20+ | App-specific patches (linux terminals, windows apps) |
| `res/` | 15+ | Resources: icons, configs, desktop files, scripts |

### Engine (`espanso-engine/src/`)
| Module | Files | Description |
|--------|-------|-------------|
| `event/` | 6 | Event types: input, internal, effect, external, ui |
| `funnel/` | 2 | Event sources, crossbeam Select |
| `process/middleware/` | 22 | Middleware chain (22 middleware) |
| `dispatch/executor/` | 8 | Dispatch executors (text, key, html, image, etc.) |

### Detect (`espanso-detect/src/`)
| Module | Files | Description |
|--------|-------|-------------|
| `mac/` | 3 | macOS: CGEvent, accessibility |
| `win32/` | 3 | Windows: Win32 hooks |
| `x11/` | 2 | Linux X11: XRecord |
| `evdev/` | 8 | Linux evdev: input devices, keymap |
| `hotkey/` | 3 | Hotkey detection |
| `layout/` | 4 | Keyboard layout detection |

### Inject (`espanso-inject/src/`)
| Module | Files | Description |
|--------|-------|-------------|
| `mac/` | 3 | macOS: CGEvent post |
| `win32/` | 3 | Windows: SendInput |
| `x11/` | 5 | Linux X11: xdotool, xclip |
| `evdev/` | 6 | Linux evdev: uinput |

## Build Commands
```bash
# Build the project
cargo build --release

# Run all tests
cargo test

# Run tests for a specific crate
cargo test -p espanso-engine

# Build for a specific platform (on VPS)
cargo build --release --target x86_64-unknown-linux-gnu
```

## Test Structure
Tests are co-located with source files (Rust convention):
- `src/lib.rs` or `src/main.rs` — integration tests
- `src/module_test.rs` — unit tests per module
- No separate test directory

## Key Architectural Patterns

1. **Event-Driven Architecture** — All input flows through events
2. **Middleware Pipeline** — 22 middleware process events in sequence
3. **Dependency Injection** — Traits for all platform-specific code
4. **Platform Abstraction** — `#[cfg(target_os = "...")]` + trait objects
5. **IPC Model** — Daemon process + worker process communicate via IPC
6. **First-Match Dispatch** — 8 executors, first one to handle an event wins

## Risk Areas for Changes

| Area | Risk | Notes |
|------|------|-------|
| `espanso-engine/process/middleware/` | HIGH | Core pipeline, all events pass through |
| `espanso-detect/` | HIGH | Platform-specific, hard to test cross-platform |
| `espanso-inject/` | HIGH | Platform-specific, security-sensitive |
| `espanso-config/` | MEDIUM | Config parsing, affects all features |
| `espanso-match/` | MEDIUM | Matching algorithm, performance-critical |
| `espanso-render/` | LOW | Template rendering, isolated |
| `espanso-modulo/` | LOW | GUI components, isolated |

## Recommended Workflow for Minimal Changes
1. **Identify exact behavior** — Reproduce first
2. **Find the middleware** — Which middleware handles this event type?
3. **Understand the event flow** — What events does it produce/consume?
4. **Write minimal fix** — Change only what's necessary
5. **Test cross-platform** — At least verify macOS + Linux
6. **Run full test suite** — `cargo test -p espanso-engine`
