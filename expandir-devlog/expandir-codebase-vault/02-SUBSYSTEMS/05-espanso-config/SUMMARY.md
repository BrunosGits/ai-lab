# espanso-config — System Analysis

## 1. What Is This?

The espanso-config crate handles all configuration parsing, storage, and querying for espanso. It reads YAML config files and match group files, resolves imports, merges configurations per-application, and provides a clean API for the engine to query "what matches are active right now?" It's 22 files, 5,555 lines — the largest core crate, but well-structured with clear separation.

## 2. Why Does It Exist?

Espanso's configuration is complex:
- Multiple YAML files with imports and overrides
- Per-application config matching (different triggers for different apps)
- Global variables shared across match groups
- Recursive imports with circular dependency detection
- Platform-specific defaults

The config crate handles all of this, providing two clean abstractions:
1. **ConfigStore** — Which configuration is active for the current application?
2. **MatchStore** — What matches and variables are available?

## 3. How Does It Work?

### The Two-Store Architecture

```
ConfigStore                              MatchStore
    │                                        │
    ├─ default config (base.yml)             ├─ base.yml
    ├─ custom configs (per-app)              ├─ _shared.yml (imported)
    │   ├─ custom1.yml                       └─ sub/sub.yml
    │   └─ custom2.yml
    │
    └─ active(app) → Config                  query(paths) → MatchSet
        └─ match_paths: Vec<PathBuf>             ├─ matches: Vec<&Match>
                                                 └─ global_vars: Vec<&Variable>
```

**ConfigStore** knows *which* match files each config wants (via glob paths).
**MatchStore** loads *all* referenced match files and their imports.

### The Data Flow

```
1. load(base_path)
   ├── Load config/ directory → ConfigStore
   │   └── Parse default.yml + custom*.yml
   │   └── Compute match_paths via glob patterns
   └── Load match/ directory → MatchStore
       └── Parse all YAML files + follow imports

2. Runtime: ConfigStore::active(app)
   └── Returns Config for current application
       └── config.match_paths() → which match files to use

3. Runtime: MatchStore::query(match_paths)
   └── Returns MatchSet { matches, global_vars }
       └── Feed to MatcherMiddleware + RenderMiddleware
```

### Config File Parsing

Config files (`config/default.yml`) go through three stages:

```
YAML string
  → YAMLConfig (serde deserialization)
  → ParsedConfig (normalized, all Option<T>)
  → ResolvedConfig (final, merged with parent)
```

The `ResolvedConfig` implements the `Config` trait with 40+ accessor methods:
- `backend()` → Inject/Clipboard/Auto
- `delay()` → injection delay
- `inject_config()` → per-platform inject settings
- `filter_title()`, `filter_class()`, `filter_exec()` → regex patterns for app matching
- And many more

### Match Group Parsing

Match files (`match/base.yml`) go through:

```
YAML file
  → YAMLMatchGroup (serde deserialization)
  → MatchGroup { imports, global_vars, matches }
  → Each YAMLMatch → Match { cause, effect, label }
  → Each YAMLVariable → Variable { name, type, params }
```

### Per-Application Config Matching

When the engine asks `ConfigStore::active(app)`:

```rust
fn active(&self, app: &AppProperties) -> &dyn Config {
    // 1. Try each custom config
    for custom in &self.customs {
        if custom.is_match(app) {
            return custom.as_ref();  // First match wins
        }
    }
    // 2. Fall back to default
    &self.default
}
```

`is_match()` checks:
- `filter_title` regex against window title
- `filter_class` regex against window class
- `filter_exec` regex against executable name
- `filter_os` against current platform

### Recursive Imports

Match groups support imports:

```yaml
# base.yml
imports:
  - "_shared.yml"      # underscore = importable only, not glob-included
  - "sub/sub.yml"
```

The `DefaultMatchStore` loads recursively:
1. Start from top-level paths
2. Load each YAML file
3. Follow `imports` transitively
4. Use `visited` set to prevent infinite loops
5. Dedup matches by `StructId`

### The merge! Macro

Configs support parent-child merging. `custom.yml` inherits from `default.yml`:

```rust
macro_rules! merge {
    ($child:expr, $parent:expr, $($field:ident),+) {
        $(
            if $child.$field.is_none() {
                $child.$field = $parent.$field;
            }
        )+
    }
}
```

The macro has compile-time verification that all fields are listed — you can't add a new field to `ParsedConfig` without updating the merge call.

## 4. Key Types

### Config Trait

```rust
pub trait Config {
    fn id(&self) -> i32;
    fn backend(&self) -> Backend;
    fn delay(&self) -> u64;
    fn inject_config(&self) -> InjectConfig;
    fn clipboard_config(&self) -> ClipboardConfig;
    fn search_trigger(&self) -> Option<String>;
    fn search_shortcut(&self) -> Option<String>;
    fn toggle_key(&self) -> ToggleKey;
    // ... 30+ more methods
}
```

### Match Struct

```rust
pub struct Match {
    pub id: StructId,
    pub cause: MatchCause,      // Trigger, Regex, or None
    pub effect: MatchEffect,    // Text, Image, or None
    pub label: Option<String>,
    pub search_terms: Vec<String>,
}
```

### Variable Struct

```rust
pub struct Variable {
    pub name: String,
    pub var_type: String,        // "date", "script", "shell", etc.
    pub params: Params,          // BTreeMap<String, Value>
    pub inject_vars: bool,       // Replace {{var}} in params?
    pub depends_on: Vec<String>, // Explicit ordering
}
```

## 5. Edge Cases

### Missing Default Config

If `config/default.yml` is missing, `load()` returns `ConfigStoreError::MissingDefault`. This is a fatal error — espanso can't start without a default config.

### Custom Config Errors

If a custom config file has errors, they're non-fatal — the file is skipped and loading continues. Errors are collected in `NonFatalErrorSet`.

### Circular Imports

The `visited` set in `load_match_groups_recursively()` prevents infinite loops. If file A imports B and B imports A, the second import is silently skipped.

### Glob Pattern Resolution

`STANDARD_INCLUDES` defines default glob patterns:
```rust
["../match/**/[!_]*.yml", "../match/**/[!_]*.yaml"]
```

The `[!_]` prefix excludes files starting with `_` (like `_shared.yml`). These are importable but not auto-included.

### Platform-Specific Defaults

Some config fields have platform-specific defaults:
- `emulate_alt_codes`: `true` on Windows, `false` elsewhere
- `disable_x11_fast_inject`: `false` on Linux, ignored elsewhere

These are handled by `cfg!(target_os = "...")` in `ResolvedConfig::load()`.

## 6. Key Patterns

### Two-Phase Loading

Config loading is split into two phases:
1. **Config phase** — Parse config files, compute match paths
2. **Match phase** — Load match files referenced by configs

This separation allows configs to reference match files via globs without loading them eagerly.

### Trait-Based Abstraction

`Config`, `ConfigStore`, and `MatchStore` are all traits. This enables:
- Mock implementations for testing
- Different store implementations (default vs. test)
- Clean dependency injection

### Non-Fatal Errors

The `NonFatalErrorSet` pattern allows loading to continue even when individual files have errors. This is critical for user experience — one bad match file shouldn't break all of espanso.

### YAML-First Design

Everything is YAML. Config files, match groups, variables — all YAML. The `serde_norway` crate (espanso's fork of serde_yaml) handles all deserialization.

## 7. Risk Assessment for Changes

| Area | Risk | Why |
|------|------|-----|
| config/resolve.rs | HIGH | Core config resolution, 1,011 lines |
| matches/group/loader/yaml/mod.rs | HIGH | YAML import, 939 lines, many edge cases |
| matches/store/default.rs | HIGH | Recursive loading, cycle detection |
| config/store.rs | MEDIUM | Active config selection |
| config/parse/yaml.rs | MEDIUM | YAML deserialization |
| matches/mod.rs | MEDIUM | Core types, affects all consumers |
| Other files | LOW | Utilities, error types |

## 8. What Was Studied

- **Files:** All 22 files in espanso-config/src/
- **Key Files:** lib.rs, config/mod.rs, config/resolve.rs, config/store.rs, config/parse/yaml.rs, matches/mod.rs, matches/group/loader/yaml/mod.rs, matches/store/default.rs
- **Patterns:** Two-phase loading, trait abstraction, non-fatal errors, recursive imports, YAML-first design, parent-child merging
- **Missing:** Nothing — this crate is fully studied
- **Coverage:** 100%

## 9. Evidence

- `espanso-config/src/lib.rs` — Entry point (303 lines)
- `espanso-config/src/config/mod.rs` — Config traits (370 lines)
- `espanso-config/src/config/resolve.rs` — Config resolution (1,011 lines)
- `espanso-config/src/config/store.rs` — ConfigStore (198 lines)
- `espanso-config/src/config/parse/yaml.rs` — YAML deserialization (401 lines)
- `espanso-config/src/config/parse/mod.rs` — ParsedConfig (97 lines)
- `espanso-config/src/config/path.rs` — Path resolution (178 lines)
- `espanso-config/src/config/default.rs` — Default config (26 lines)
- `espanso-config/src/config/util.rs` — Utilities (80 lines)
- `espanso-config/src/matches/mod.rs` — Match types (288 lines)
- `espanso-config/src/matches/group/mod.rs` — MatchGroup (41 lines)
- `espanso-config/src/matches/group/path.rs` — Import resolution (165 lines)
- `espanso-config/src/matches/group/loader/mod.rs` — Loader dispatch (178 lines)
- `espanso-config/src/matches/group/loader/yaml/mod.rs` — YAML importer (939 lines)
- `espanso-config/src/matches/group/loader/yaml/parse.rs` — YAML parsing (143 lines)
- `espanso-config/src/matches/group/loader/yaml/util.rs` — YAML utilities (179 lines)
- `espanso-config/src/matches/store/mod.rs` — MatchStore trait (41 lines)
- `espanso-config/src/matches/store/default.rs` — DefaultMatchStore (738 lines)
- `espanso-config/src/counter.rs` — ID generator (34 lines)
- `espanso-config/src/error.rs` — Error types (71 lines)
- `espanso-config/src/util.rs` — Utilities (74 lines)

## Related Pages

- [[05-espanso-config/MAP]]
- [[07-espanso-engine/MAP]] — Engine uses ConfigStore and MatchStore
- [[06-espanso-render/SUMMARY]] — Render uses Variable types
- [[04-espanso-match/SUMMARY]] — Match uses Match.cause for routing
- [[01-CORE/CRATE_DEPENDENCIES]]
