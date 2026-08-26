# Crate Dependencies

## Dependency Graph

```
espanso (main)
├── espanso-engine          ← Core event pipeline
│   ├── (external: crossbeam, pulldown-cmark, html2text)
│   └── (no internal deps — pure abstractions)
├── espanso-detect          ← Input detection
│   └── (platform-specific FFI)
├── espanso-inject          ← Keyboard injection
│   └── (platform-specific FFI)
├── espanso-match           ← Pattern matching
│   └── (pure Rust, no deps)
├── espanso-config          ← Configuration
│   └── (YAML parsing)
├── espanso-render          ← Template rendering
│   └── (espanso-match types)
├── espanso-clipboard       ← Clipboard ops
│   └── (platform-specific FFI)
├── espanso-modulo          ← GUI components
│   └── (wxWidgets FFI)
├── espanso-ui              ← System tray
│   └── (platform-specific FFI)
├── espanso-package         ← Package management
│   └── (git, HTTP)
├── espanso-info            ← System info
│   └── (platform-specific FFI)
├── espanso-ipc             ← IPC
│   └── (Unix sockets / named pipes)
├── espanso-kvs             ← Key-value storage
│   └── (file-based)
└── espanso-mac-utils       ← macOS utilities
    └── (Objective-C FFI)
```

## How Crates Connect

### The Engine as Integration Point

The engine crate is the integration point — it defines traits that other crates implement:

```
espanso-detect ──implements──▶ Source trait (funnel)
espanso-match  ──implements──▶ Matcher trait (middleware)
espanso-render ──implements──▶ Renderer trait (middleware)
espanso-inject ──implements──▶ TextInjector, KeyInjector traits (dispatch)
espanso-clipboard ─implements──▶ TextInjector trait (dispatch)
espanso-config ──provides──▶ Config data (middleware)
espanso-modulo ──implements──▶ TextUIHandler trait (dispatch)
espanso-ui     ──implements──▶ IconHandler, ContextMenuHandler traits (dispatch)
```

### Data Flow Through Crates

```
espanso-detect → Event → espanso-engine (funnel)
                          │
                          ▼
                    espanso-match (MatcherMiddleware)
                          │
                          ▼
                    espanso-config (match data)
                          │
                          ▼
                    espanso-render (RenderMiddleware)
                          │
                          ▼
                    espanso-inject (TextInjectExecutor)
```

### Shared Types

Key types that cross crate boundaries:

| Type | Defined In | Used By |
|------|-----------|---------|
| `Event` | espanso-engine | All crates |
| `EventType` | espanso-engine | All crates |
| `Key` | espanso-detect | espanso-engine, espanso-inject |
| `MatchResult` | espanso-engine | espanso-match, espanso-config |
| `DetectedMatch` | espanso-engine | espanso-match |
| `TextInjectRequest` | espanso-engine | espanso-render, espanso-inject |

## External Dependencies

### espanso-engine
- `crossbeam` — Channel-based Select for funnel
- `pulldown-cmark` — Markdown parsing
- `html2text` — HTML to text conversion
- `unicode-segmentation` — Unicode word boundaries

### espanso-config
- `yaml-rust` — YAML parsing
- `regex` — Pattern matching

### espanso-match
- (minimal deps — pure Rust algorithms)

### espanso-modulo
- `wxWidgets` — Cross-platform GUI (vendored)

## Build Order

When building from scratch, crates compile in this order:
1. `espanso-kvs`, `espanso-ipc`, `espanso-mac-utils` (leaf crates)
2. `espanso-match`, `espanso-info` (few deps)
3. `espanso-clipboard`, `espanso-detect`, `espanso-inject` (platform FFI)
4. `espanso-config`, `espanso-render`, `espanso-package` (business logic)
5. `espanso-engine` (pure abstractions)
6. `espanso-modulo`, `espanso-ui` (GUI)
7. `espanso` (main binary, ties everything together)
