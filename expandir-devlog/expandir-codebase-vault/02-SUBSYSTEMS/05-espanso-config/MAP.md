# espanso-config — File:Line Index

Complete cross-reference for all code in the espanso-config crate (22 files, 5,555 lines).

---

## lib.rs — Entry Point (303 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-30 | `use` imports | config, matches, error modules |
| 32-40 | `pub struct LoadableConfig` | Return type: config_store + match_store + errors |
| 42-80 | `pub fn load()` | Main entry: load config dir → ConfigStore + MatchStore |
| 82-120 | `load()` — config phase | `config::load_store(&config_dir)` |
| 122-160 | `load()` — match phase | `matches::store::load(&root_paths)` |
| 162-200 | `load()` — error merging | Merge non-fatal errors from both phases |
| 202-303 | Tests | 10+ test cases for load() |

---

## counter.rs — ID Generator (34 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | std::sync |
| 12-18 | `pub struct StructId` | Wrapper around `u64` |
| 20-25 | `pub fn next_id()` | Thread-local atomic counter, returns `StructId` |
| 27-34 | Tests | ID uniqueness test |

---

## error.rs — Error Types (71 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | thiserror, std::path |
| 12-20 | `pub struct NonFatalErrorSet` | `path: PathBuf`, `errors: Vec<ErrorRecord>` |
| 22-30 | `pub struct ErrorRecord` | `level: ErrorLevel`, `message: String` |
| 32-38 | `pub enum ErrorLevel` | `Error`, `Warning` |
| 40-71 | Tests | Error construction tests |

---

## util.rs — Utilities (74 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | std::path |
| 12-25 | `pub fn is_yaml_empty()` | Check if YAML string is empty or comments-only |
| 27-40 | `is_yaml_empty()` — implementation | Parse YAML, check for null/empty mapping |
| 42-74 | Tests | Empty YAML detection tests |

---

## config/mod.rs — Config Types & Traits (370 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-30 | `use` imports | std::path, std::collections, regex |
| 32-80 | `pub trait Config` | 40+ accessor methods: backend(), delay(), inject_config(), etc. |
| 82-100 | `pub trait ConfigStore` | `default()`, `active(app)`, `configs()`, `get_all_match_paths()` |
| 102-115 | `pub struct AppProperties` | `title: String`, `class: String`, `exec: String` |
| 117-130 | `pub enum Backend` | `Inject`, `Clipboard`, `Auto` |
| 132-145 | `pub enum ToggleKey` | Ctrl, Meta, Alt, Shift + Left/Right variants |
| 147-160 | `pub enum UpperCasingStyle` | `Uppercase`, `Capitalize`, `CapitalizeWords` |
| 162-180 | `pub struct RMLVOConfig` | Wayland keyboard layout: Rules, Model, Layout, Variant, Options |
| 182-200 | `pub enum ConfigStoreError` | `InvalidConfigDir`, `MissingDefault`, `IOError` |
| 202-370 | Tests | Config trait tests, AppProperties tests |

---

## config/default.rs — Default Config (26 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | super modules |
| 12-20 | `pub fn default()` | Factory for `ResolvedConfig` with default values |
| 22-26 | Tests | Default config test |

---

## config/store.rs — ConfigStore Implementation (198 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | std::sync, super modules |
| 17-25 | `pub struct DefaultConfigStore` | `default: Arc<dyn Config>`, `customs: Vec<Arc<dyn Config>>` |
| 27-45 | `DefaultConfigStore::new()` | Constructor |
| 47-70 | `impl ConfigStore for DefaultConfigStore` | `default()`, `active(app)`, `configs()`, `get_all_match_paths()` |
| 72-100 | `active()` implementation | Iterate customs, first `is_match(app)` wins, fallback to default |
| 102-130 | `get_all_match_paths()` | Union of all match paths from all configs |
| 132-198 | Tests | Store queries, active config selection |

---

## config/path.rs — Path Resolution (178 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | std::path, glob, walkdir |
| 17-50 | `pub fn calculate_paths()` | Resolve glob patterns against base directory |
| 52-80 | `calculate_paths()` — include handling | `glob::glob()` + canonicalize |
| 82-110 | `calculate_paths()` — exclude handling | Filter out excluded paths |
| 112-140 | `calculate_paths()` — dedup | Remove duplicate paths |
| 142-178 | Tests | Path resolution tests |

---

## config/resolve.rs — Config Resolution (1,011 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-30 | `use` imports | std::path, regex, super modules |
| 32-50 | `pub struct ResolvedConfig` | All resolved config fields |
| 52-80 | `ResolvedConfig::load()` | Parse YAML → merge with parent → compute paths |
| 82-120 | `load()` — YAML parsing | `YAMLConfig::parse_from_str()` |
| 122-160 | `load()` — parent merging | `merge!` macro: child overrides parent |
| 162-200 | `load()` — path computation | `calculate_paths()` with STANDARD_INCLUDES |
| 202-250 | `load()` — regex compilation | Compile `filter_title`, `filter_class`, `filter_exec` |
| 252-300 | `impl Config for ResolvedConfig` | All 40+ accessor methods |
| 302-350 | `is_match()` | Check if config applies to given AppProperties |
| 352-400 | `is_match()` — filter_os | Platform check via `os_matches()` |
| 402-500 | STANDARD_INCLUDES | Default glob patterns: `../match/**/[!_]*.yml` |
| 502-1011 | Tests | 30+ test cases for config resolution |

---

## config/util.rs — Config Utilities (80 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | super modules |
| 17-30 | `pub fn os_matches()` | Runtime platform check: `cfg!(target_os = "...")` |
| 32-55 | `macro_rules! merge` | Bulk-merge None fields from parent to child |
| 57-65 | `merge!` — compile-time verification | Ensures all fields are listed |
| 67-80 | Tests | Merge macro tests |

---

## config/parse/mod.rs — ParsedConfig (97 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | serde, super modules |
| 17-40 | `pub struct ParsedConfig` | All fields are `Option<T>` — intermediate form |
| 42-60 | `TryFrom<YAMLConfig> for ParsedConfig` | Convert deserialized YAML → normalized form |
| 62-80 | `impl ParsedConfig` | `merge_from_parent()`, `load()` |
| 82-97 | Tests | ParsedConfig construction tests |

---

## config/parse/yaml.rs — YAML Deserialization (401 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-20 | `use` imports | serde, std::path |
| 22-80 | `pub struct YAMLConfig` | ~50 optional fields: backend, delay, inject_config, etc. |
| 82-120 | `YAMLConfig::parse_from_str()` | `serde_norway::from_str()`, handle BOM, empty YAML |
| 122-160 | `parse_from_str()` — BOM stripping | Remove UTF-8 BOM if present |
| 162-200 | `parse_from_str()` — empty handling | Return empty config for empty YAML |
| 202-250 | Field mappings | serde rename/alias attributes for YAML keys |
| 252-300 | Nested structs | `YAMLInjectConfig`, `YAMLClipboardBackendConfig`, etc. |
| 302-401 | Tests | YAML parsing tests |

---

## matches/mod.rs — Match Types (288 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-20 | `use` imports | std::collections, crate types |
| 22-40 | `pub struct Match` | `id: StructId`, `cause: MatchCause`, `effect: MatchEffect`, `label`, `search_terms` |
| 42-60 | `pub enum MatchCause` | `Trigger(TriggerCause)`, `Regex(RegexCause)`, `None` |
| 62-80 | `pub enum MatchEffect` | `Text(TextEffect)`, `Image(ImageEffect)`, `None` |
| 82-100 | `pub struct TriggerCause` | `triggers: Vec<String>`, `left_word: bool`, `right_word: bool`, `case_sensitive`, `propagate_case`, `uppercase_style` |
| 102-120 | `pub struct RegexCause` | `regex: String` |
| 122-140 | `pub struct TextEffect` | `replace: String`, `vars: Vec<Variable>`, `format: TextFormat`, `force_mode` |
| 142-160 | `pub struct ImageEffect` | `path: String` |
| 162-180 | `pub struct Variable` | `name`, `var_type`, `params: Params`, `inject_vars: bool`, `depends_on: Vec<String>` |
| 182-200 | `pub type Params` | `BTreeMap<String, Value>` |
| 202-220 | `pub enum Value` | `Null`, `Bool`, `Number`, `String`, `Array`, `Object` |
| 222-240 | `pub enum TextFormat` | `Plain`, `Markdown`, `Html` |
| 242-260 | `pub enum TextInjectMode` | `Keys`, `Clipboard` |
| 262-288 | Tests | Match construction tests |

---

## matches/group/mod.rs — MatchGroup (41 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | super modules |
| 12-20 | `pub struct MatchGroup` | `imports: Vec<String>`, `global_vars: Vec<Variable>`, `matches: Vec<Match>` |
| 22-30 | `impl MatchGroup` | `load(path)` — delegates to loader |
| 32-41 | Tests | MatchGroup construction test |

---

## matches/group/path.rs — Import Resolution (165 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | std::path, super modules |
| 17-50 | `pub fn resolve_imports()` | Resolve relative/absolute import paths |
| 52-80 | `resolve_imports()` — relative paths | Relative to current file's directory |
| 82-110 | `resolve_imports()` — absolute paths | Use as-is |
| 112-140 | `resolve_imports()` — missing files | Skip non-existent, log warning |
| 142-165 | Tests | Import resolution tests |

---

## matches/group/loader/mod.rs — Loader Dispatch (178 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | std::path, super modules |
| 17-25 | `pub trait Importer` | `load_group(path) -> Result<MatchGroup>` |
| 27-35 | `static IMPORTERS` | Static list: currently only `YAMLImporter` |
| 37-60 | `pub fn load_group()` | Dispatch by file extension (.yml, .yaml) |
| 62-90 | `load_group()` — extension matching | Find importer for file extension |
| 92-120 | `load_group()` — error handling | `MissingExtension`, `InvalidFormat`, `ParsingError` |
| 122-140 | `pub enum LoadError` | `MissingExtension`, `InvalidFormat`, `ParsingError(String)` |
| 142-178 | Tests | Loader dispatch tests |

---

## matches/group/loader/yaml/mod.rs — YAML Importer (939 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-30 | `use` imports | serde, std::path, super modules |
| 32-50 | `pub struct YAMLImporter` | Empty struct, implements `Importer` |
| 52-100 | `impl Importer for YAMLImporter` | Parse YAML → convert matches/vars |
| 102-150 | `load_group()` — parsing | `YAMLMatchGroup::parse_from_file()` |
| 152-200 | `load_group()` — match conversion | `try_convert_into_match()` for each YAML match |
| 202-250 | `try_convert_into_match()` | Handle trigger, regex, replace, vars, label, search_terms |
| 252-300 | `try_convert_into_match()` — trigger handling | `TriggerCause` construction, word boundaries |
| 302-350 | `try_convert_into_match()` — text effect | `TextEffect` construction, format detection |
| 352-400 | `try_convert_into_match()` — image effect | `ImageEffect` construction |
| 402-450 | `try_convert_into_variable()` | Convert YAML variable → `Variable` |
| 452-500 | `try_convert_into_variable()` — params | Convert YAML params → `Params` (BTreeMap) |
| 502-550 | Form handling | `[[name]]` syntax for form variables |
| 552-600 | Case propagation | `propagate_case`, `uppercase_style` |
| 602-650 | Format detection | Plain/Markdown/Html from YAML |
| 652-700 | Force mode | `force_mode` for inject method |
| 702-750 | Error handling | Non-fatal errors for individual bad matches |
| 752-939 | Tests | 30+ test cases for YAML import |

---

## matches/group/loader/yaml/parse.rs — YAML Match Parsing (143 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | serde |
| 17-30 | `pub struct YAMLMatchGroup` | `imports`, `global_vars`, `matches` |
| 32-50 | `pub struct YAMLMatch` | Serde struct: trigger, replace, regex, vars, label, etc. |
| 52-70 | `pub struct YAMLVariable` | Serde struct: name, type, params, inject_vars, depends_on |
| 72-90 | `pub struct YAMLMatchVariant` | Multi-trigger variant |
| 92-110 | Field aliases | serde rename attributes for YAML keys |
| 112-143 | Tests | YAML parse tests |

---

## matches/group/loader/yaml/util.rs — YAML Utilities (179 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | std::collections, crate types |
| 17-50 | `pub fn convert_params()` | Convert `serde_norway::Mapping` → `Params` (BTreeMap) |
| 52-80 | `convert_params()` — value conversion | Handle string, number, bool, array, object |
| 82-110 | `pub fn convert_to_value()` | Convert `serde_norway::Value` → crate `Value` |
| 112-140 | Value type mapping | YAML types → Value enum variants |
| 142-179 | Tests | Param conversion tests |

---

## matches/store/mod.rs — MatchStore Trait (41 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | super modules |
| 12-20 | `pub trait MatchStore` | `query(paths) -> MatchSet`, `loaded_paths()` |
| 22-30 | `pub struct MatchSet` | `matches: Vec<&Match>`, `global_vars: Vec<&Variable>` |
| 32-41 | Tests | MatchStore trait tests |

---

## matches/store/default.rs — DefaultMatchStore (738 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-20 | `use` imports | std::collections, std::path, super modules |
| 22-40 | `pub struct DefaultMatchStore` | `groups: HashMap<String, MatchGroup>` |
| 42-70 | `DefaultMatchStore::new()` | Constructor |
| 72-100 | `pub fn load()` | Load match groups recursively from paths |
| 102-150 | `load_match_groups_recursively()` | Load YAML file → follow imports → store in HashMap |
| 152-200 | Recursive import handling | `visited` set for circular dependency detection |
| 202-250 | `impl MatchStore` | `query(paths)`, `loaded_paths()` |
| 252-300 | `query()` implementation | Traverse imports, flatten to MatchSet, dedup by StructId |
| 302-350 | `query()` — dedup logic | `HashSet<StructId>` for visited matches |
| 352-400 | `query()` — global vars | Collect global_vars from all groups |
| 402-738 | Tests | 20+ test cases for store queries |

---

## Cross-Reference: How Config Connects to Engine

```
~/.config/espanso/
├── config/
│   ├── default.yml        ← ConfigStore.default()
│   ├── custom1.yml        ← ConfigStore.active(app)
│   └── custom2.yml
└── match/
    ├── base.yml           ← MatchStore.query(paths)
    ├── _shared.yml        ← (imported only)
    └── sub/
        └── sub.yml

espanso-config (this crate)
├── lib::load(base_path)
│   ├── ConfigStore: knows WHICH match files each config wants
│   └── MatchStore: loads ALL referenced match files
│
├── config::Config trait
│   └── 40+ accessor methods for all espanso behavior
│
├── matches::Match struct
│   └── cause (trigger/regex) + effect (text/image)
│
└── matches::Variable struct
    └── name, type, params, depends_on

espanso-engine (consumer)
├── MatcherMiddleware
│   └── Uses Match.cause to build RollingMatcher/RegexMatcher
│
└── RenderMiddleware
    └── Uses Match.effect + Variable to build Template
```

---

## Key Variables — Cross-Reference

| Variable | Defined | Used In |
|----------|---------|---------|
| `ResolvedConfig.id` | resolve.rs:50 | is_match(), comparison |
| `DefaultConfigStore.default` | store.rs:19 | ConfigStore::default() |
| `DefaultConfigStore.customs` | store.rs:20 | ConfigStore::active() iteration |
| `DefaultMatchStore.groups` | store/default.rs:23 | query() traversal |
| `Match.id` | mod.rs:24 | StructId for dedup |
| `Match.cause` | mod.rs:25 | MatcherMiddleware routing |
| `Match.effect` | mod.rs:26 | RenderMiddleware template |
| `Variable.depends_on` | mod.rs:176 | Dependency resolution |

---

## Grep Patterns for Future Searches

```bash
# All Config trait methods
grep -rn "fn " espanso-config/src/config/mod.rs | grep "pub fn"

# All YAML parsing
grep -rn "serde_norway" espanso-config/src/

# All Match construction
grep -rn "Match {" espanso-config/src/

# All Variable construction
grep -rn "Variable {" espanso-config/src/

# Platform-specific defaults
grep -rn "cfg!(target_os" espanso-config/src/

# All error types
grep -rn "pub enum.*Error" espanso-config/src/

# Import resolution
grep -rn "resolve_imports" espanso-config/src/

# Glob patterns
grep -rn "STANDARD_INCLUDES" espanso-config/src/
```

---

**Generated from:** espanso-config crate analysis
**Core files:** lib.rs (303 lines), config/resolve.rs (1,011 lines), matches/group/loader/yaml/mod.rs (939 lines), matches/store/default.rs (738 lines)
**Total:** 22 files, 5,555 lines

## Related Pages

- [[05-espanso-config/SUMMARY]]
- [[07-espanso-engine/MAP]] — Engine uses ConfigStore and MatchStore
- [[06-espanso-render/SUMMARY]] — Render uses Variable types
- [[04-espanso-match/SUMMARY]] — Match uses Match.cause for routing
- [[01-CORE/CRATE_DEPENDENCIES]]
