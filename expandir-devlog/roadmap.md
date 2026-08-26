# Expandir Development Roadmap

A personal fork of [espanso](https://github.com/espanso/espanso), the cross-platform text expander written in Rust. Started 2026-08-16.

This document tracks the expandir project: what's been studied, what's been built, and what comes next.

---

## Project Status

- **Repo:** [BrunosGits/expandir](https://github.com/BrunosGits/expandir) (public)
- **Default branch:** `dev`
- **Current tag:** `expandir-0.1.0` (fork point, identical to espanso v2.2.3)
- **Binary name:** `expandir` (replaces `espanso`)
- **License:** GPL-3.0 (inherited from espanso)

## What's Different from Upstream

| Feature | Status |
|---------|--------|
| Search window opens near mouse cursor (`search_use_cursor_position`) | Working on macOS, Windows/Linux pending |
| Clipboard history and searchable history UI | Planned |
| Temporary copy/paste hotspots (register slots) | Planned |
| AI snippet authoring assistant | Planned |
| Settings panel (GUI for config toggles) | Planned |
| Match editor GUI | Planned |

---

## Codebase Study Progress

The espanso codebase is 15 crates, ~30k lines of Rust. Four core crates have been fully studied.

### Completed Studies

| Crate | Files | Lines | What It Does | Key Insight |
|-------|-------|-------|--------------|-------------|
| **espanso-engine** | 47 | 4,672 | Event pipeline: funnel → process → dispatch | 24 middleware in sequence, 8 executors, first-match-wins |
| **espanso-config** | 22 | 5,555 | YAML config parsing, match groups, stores | Two-store architecture: ConfigStore (per-app) + MatchStore (recursive imports) |
| **espanso-render** | 15 | 3,870 | Template rendering + 9 extensions | Topological sort for variable dependencies, extension registry |
| **espanso-match** | 8 | 1,553 | Rolling matcher (trie) + regex matcher | O(1) per-event trie lookup, multiple active paths |
| **Total** | **92** | **15,650** | | |

### Remaining Studies

| Crate | Files | Purpose | Priority |
|-------|-------|---------|----------|
| espanso-detect | 29 | Keyboard/input detection (macOS/Win32/X11/evdev) | High — platform-specific, needed for input changes |
| espanso-inject | 29 | Keyboard injection (macOS/Win32/X11/evdev) | High — platform-specific, needed for injection changes |
| espanso-clipboard | 25 | Clipboard operations | Medium — needed for clipboard history feature |
| espanso-modulo | 45 | GUI components (search bar, forms, wizard) | Medium — needed for settings panel, match editor |
| espanso-ui | 15 | System tray UI | Low |
| espanso-package | 20 | Package management (hub, git, archives) | Low |
| cli-commands | 146 | CLI structure (daemon, worker, launcher) | Low |
| match-extensions | - | Built-in extensions | Low |
| event-pipeline | - | Core flow: detect → match → render → inject | Already covered by engine study |

### Architecture Summary

```
espanso-detect → Event → espanso-engine (funnel)
                           │
                     ┌─────┴─────┐
                     │ MatcherMiddleware ← espanso-match (trie/regex)
                     │ ConfigMiddleware  ← espanso-config (per-app config)
                     │ RenderMiddleware  ← espanso-render (extensions)
                     │ ... (24 total)
                     └─────┬─────┘
                           │
                     espanso-dispatch
                     ├── TextInjectExecutor → espanso-inject
                     ├── KeyInjectExecutor → espanso-inject
                     ├── HtmlInjectExecutor
                     ├── ImageInjectExecutor
                     ├── ContextMenuExecutor → espanso-modulo
                     ├── IconUpdateExecutor → espanso-ui
                     ├── SecureInputExecutor
                     └── TextUIExecutor → espanso-modulo
```

---

## Feature Roadmap

### Phase 1: Build & Learn (Weeks 1-2)

- [x] Fork espanso, set up repo (expandir-0.1.0 tag)
- [x] Clean up repo (remove CI, docs, images, snap, nix)
- [x] Study espanso-engine — understand the event pipeline
- [ ] Get espanso building on VPS (Ubuntu 22.04)
- [ ] Fix build issues, document in expandir-devlog
- [ ] Package AppImage (Linux)
- [ ] Basic config changes
- [ ] Add a new keybinding

### Phase 2: Core Understanding (Weeks 3-4)

- [x] Study espanso-config — YAML parsing, match groups, stores
- [x] Study espanso-render — template rendering, extensions
- [x] Study espanso-match — rolling matcher, regex matcher
- [ ] Study espanso-detect — platform-specific input detection
- [ ] Study espanso-inject — platform-specific keyboard injection
- [ ] Study espanso-clipboard — clipboard operations

### Phase 3: Features (Weeks 5-8)

- [ ] Search window near cursor (already working on macOS)
- [ ] Test search cursor feature on Windows + Linux
- [ ] Clipboard history — store recent expansions
- [ ] Better error messages
- [ ] Custom extensions (AI assistant placeholder)

### Phase 4: GUI & Packaging (Weeks 9-12)

- [ ] Study espanso-modulo — GUI components
- [ ] Settings panel (GUI for config toggles)
- [ ] Match editor GUI
- [ ] AppImage (Linux)
- [ ] DMG (macOS) — optional
- [ ] Documentation

### Phase 5: Polish & Publish (Week 13+)

- [ ] Clipboard history searchable UI
- [ ] Temporary copy/paste hotspots
- [ ] AI snippet authoring assistant (local LLM)
- [ ] Polish README, contribution guide
- [ ] Published releases on GitHub

---

## Codebase Notes

### Build Commands

```bash
# Standard build
cargo build --release

# Build with modulo UI
cargo build --release --no-default-features --features modulo,vendored-tls

# Run tests
cargo test

# Run tests for specific crate
cargo test -p espanso-engine
```

### Key Files

- `espanso-engine/src/lib.rs` — Engine loop (77 lines)
- `espanso-engine/src/process/default.rs` — 24 middleware (187 lines)
- `espanso-engine/src/dispatch/default.rs` — 8 executors (84 lines)
- `espanso-config/src/lib.rs` — Entry point (303 lines)
- `espanso-config/src/config/resolve.rs` — Config resolution (1,011 lines)
- `espanso-render/src/renderer/mod.rs` — Template rendering (950 lines)
- `espanso-match/src/rolling/matcher.rs` — Trie-based matching (352 lines)

### Risk Areas for Changes

| Area | Risk | Why |
|------|------|-----|
| Engine middleware | HIGH | All events pass through, bugs break everything |
| Platform-specific code (detect/inject) | HIGH | Hard to test cross-platform, security-sensitive |
| Config parsing | MEDIUM | Affects all features, many edge cases |
| Match algorithm | MEDIUM | Performance-critical, subtle word boundary logic |
| Render extensions | LOW | Isolated, easy to test |

### Working Effectively

1. **Start with the config** — understand what the user has configured
2. **Trace the event** — follow a keystroke through the pipeline
3. **Find the middleware** — each feature has a specific middleware
4. **Write minimal changes** — espanso is well-structured, small changes work
5. **Test cross-platform** — at least macOS + Linux
6. **Run the test suite** — `cargo test -p <crate>`

---

## Resources

- [espanso documentation](https://espanso.org/docs/)
- [espanso hub](https://hub.espanso.org)
- [expandir repo](https://github.com/BrunosGits/expandir)
- [codebase vault](./expandir-codebase-vault/) — Obsidian vault with full study notes
