# Expandir Codebase Study

> A structured study of the espanso text expander codebase, used as reference
> for implementing features in the expandir fork.

---

## 1. Study Overview

**Purpose:** Understand how espanso works — from repository structure to runtime behavior — so we can make targeted, minimal changes in expandir without breaking the pipeline.

**Projects:**
- [espanso](https://github.com/espanso/espanso) — upstream (Rust, 15 crates, ~30k lines)
- [expandir](https://github.com/BrunosGits/expandir) — personal fork

**Primary questions:**
- How is the event pipeline structured?
- How do platform-specific crates connect to the core?
- How does config drive behavior per-application?
- How does template rendering resolve variables and extensions?
- Where are the safe extension points for new features?
- What breaks if you change a middleware?

---

## 2. Start Here

### Fundamentals

- [[01-CORE/CODEBASE_MAP]] — Project overview, 15 crates, build commands
- [[01-CORE/ARCHITECTURE]] — Event pipeline, middleware, dispatch
- [[01-CORE/CRATE_DEPENDENCIES]] — How crates depend on each other

### Core Concepts

- **Event pipeline** — All input flows through events: detect → funnel → process → dispatch → inject
- **Middleware pattern** — 24 middleware process events in sequence, each with a single responsibility
- **Dependency injection** — Traits for all platform-specific code, mockable for testing
- **Platform abstraction** — `#[cfg(target_os = "...")]` + trait objects isolate macOS/Windows/Linux
- **First-match dispatch** — 8 executors, first one to handle an event wins

---

## 3. Architecture

- [[01-CORE/ARCHITECTURE]] — Full system architecture
- [[01-CORE/CODEBASE_MAP]] — Module map with file counts and line counts
- [[01-CORE/CRATE_DEPENDENCIES]] — Dependency graph

### Data Flow

```
espanso-detect → Event → espanso-engine (funnel)
                           │
                     ┌─────┴─────┐
                     │ MatcherMiddleware ← espanso-match
                     │ ConfigMiddleware  ← espanso-config
                     │ RenderMiddleware  ← espanso-render
                     │ ... (24 total)
                     └─────┬─────┘
                           │
                     espanso-dispatch
                     ├── TextInjectExecutor → espanso-inject
                     ├── KeyInjectExecutor → espanso-inject
                     ├── ContextMenuExecutor → espanso-modulo
                     ├── IconUpdateExecutor → espanso-ui
                     └── ... (8 total)
```

### Runtime Flow

- **Daemon process** — Runs as service, manages lifecycle, elevated privileges
- **Worker process** — Runs the engine, handles matches, lower privileges
- **IPC** — Unix sockets (macOS/Linux) or named pipes (Windows)

---

## 4. Crate Studies

### Completed

| Crate | Files | Lines | Study |
|-------|-------|-------|-------|
| espanso-engine | 47 | 4,672 | [[02-SUBSYSTEMS/07-espanso-engine/MAP]] · [[02-SUBSYSTEMS/07-espanso-engine/SUMMARY]] |
| espanso-config | 22 | 5,555 | [[02-SUBSYSTEMS/05-espanso-config/MAP]] · [[02-SUBSYSTEMS/05-espanso-config/SUMMARY]] |
| espanso-render | 15 | 3,870 | [[02-SUBSYSTEMS/06-espanso-render/MAP]] · [[02-SUBSYSTEMS/06-espanso-render/SUMMARY]] |
| espanso-match | 8 | 1,553 | [[02-SUBSYSTEMS/04-espanso-match/MAP]] · [[02-SUBSYSTEMS/04-espanso-match/SUMMARY]] |

### Planned

| Crate | Files | Purpose | Priority |
|-------|-------|---------|----------|
| espanso-detect | 29 | Keyboard/input detection (macOS/Win32/X11/evdev) | High |
| espanso-inject | 29 | Keyboard injection (macOS/Win32/X11/evdev) | High |
| espanso-clipboard | 25 | Clipboard operations | Medium |
| espanso-modulo | 45 | GUI components (search bar, forms, wizard) | Medium |
| espanso-ui | 15 | System tray UI | Low |
| espanso-package | 20 | Package management | Low |
| cli-commands | 146 | CLI structure (daemon, worker, launcher) | Low |
| match-extensions | — | Built-in extensions | Low |

---

## 5. Platform Studies

| Platform | Crates | Status |
|----------|--------|--------|
| macOS | detect, inject, mac-utils, modulo | 🔴 Not investigated |
| Windows | detect, inject, modulo | 🔴 Not investigated |
| Linux | detect (X11 + evdev), inject (X11 + evdev) | 🔴 Not investigated |

---

## 6. Investigations

Questions investigated:

| Question | Status | Notes |
|----------|--------|-------|
| How does a keystroke become an expansion? | 🟢 | [[02-SUBSYSTEMS/07-espanso-engine/SUMMARY]] |
| How does config matching work per-app? | 🟢 | [[02-SUBSYSTEMS/05-espanso-config/SUMMARY]] |
| How does template rendering resolve variables? | 🟢 | [[02-SUBSYSTEMS/06-espanso-render/SUMMARY]] |
| How does the rolling matcher detect triggers? | 🟢 | [[02-SUBSYSTEMS/04-espanso-match/SUMMARY]] |
| How does platform detection work? | 🔴 | Not investigated |
| How does keyboard injection work? | 🔴 | Not investigated |
| How does the daemon communicate with the worker? | 🔴 | Not investigated |
| How does hot-reload of config files work? | 🔴 | Not investigated |

**Legend:** 🟢 Complete · 🟡 In progress · 🔴 Not investigated

---

## 7. Fork Tracking

- [[06-FORK-TRACKING/expandir-changes]] — What's different from upstream
- [[06-FORK-TRACKING/feature-roadmap]] — Planned features
- [[06-FORK-TRACKING/branch-strategy]] — Branch management

---

## 8. Code References

- [[08-QUERIES/code-refs]] — Cross-references by topic
- [[08-QUERIES/grep-patterns]] — Useful grep commands for exploring the codebase

---

## 9. Study Progress

| Subsystem | Status | Files | Lines | Last Updated |
|-----------|--------|-------|-------|-------------|
| espanso-engine | 🟢 COMPLETE | 47 | 4,672 | 2026-08-25 |
| espanso-config | 🟢 COMPLETE | 22 | 5,555 | 2026-08-25 |
| espanso-render | 🟢 COMPLETE | 15 | 3,870 | 2026-08-25 |
| espanso-match | 🟢 COMPLETE | 8 | 1,553 | 2026-08-25 |
| espanso-detect | 🔴 SKELETON | 29 | ~2,500 | — |
| espanso-inject | 🔴 SKELETON | 29 | ~2,500 | — |
| espanso-clipboard | 🔴 SKELETON | 25 | ~2,000 | — |
| espanso-modulo | 🔴 SKELETON | 45 | ~3,000 | — |
| espanso-ui | 🔴 SKELETON | 15 | ~1,000 | — |
| espanso-package | 🔴 SKELETON | 20 | ~1,500 | — |
| cli-commands | 🔴 SKELETON | 146 | ~8,000 | — |
| match-extensions | 🔴 SKELETON | — | — | — |
| event-pipeline | 🟡 COVERED | — | — | Covered by engine study |
| **Total studied** | | **92** | **15,650** | |

---

## 10. Open Questions

- How does espanso handle Wayland vs X11 on Linux?
- What is the exact IPC protocol between daemon and worker?
- How does hot-reload detect file changes (inotify? polling?).
- How does the modulo GUI integrate with the engine?
- What's the security model for script/shell extensions?
- How does espanso handle multiple keyboard layouts?
