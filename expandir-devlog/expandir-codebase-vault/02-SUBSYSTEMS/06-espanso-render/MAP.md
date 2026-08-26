# espanso-render — File:Line Index

Complete cross-reference for all code in the espanso-render crate (15 files, 3,870 lines).

---

## lib.rs — Public API

| Lines | Item | Description |
|-------|------|-------------|
| 1-20 | `use` imports | renderer, extension modules |
| 22-30 | `pub trait Renderer` | Single method: `render(&self, template, context, options) -> RenderResult` |
| 32-38 | `pub enum RenderResult` | `Success(String)`, `Aborted`, `Error(anyhow::Error)` |
| 40-48 | `pub struct Context<'a>` | `global_vars: Vec<&Variable>`, `templates: Vec<&Template>` |
| 50-55 | `pub struct RenderOptions` | `casing_style: CasingStyle` |
| 57-63 | `pub enum CasingStyle` | `None`, `Capitalize`, `CapitalizeWords`, `Uppercase` |
| 65-80 | `pub struct Template` | `ids: Vec<String>`, `body: String`, `vars: Vec<Variable>` |
| 82-100 | `pub struct Variable` | `name`, `var_type`, `inject_vars: bool`, `params: Params`, `depends_on: Vec<String>` |
| 102-108 | `pub type Params` | `HashMap<String, Value>` |
| 110-120 | `pub enum Value` | `Null`, `Bool`, `Number`, `String`, `Array`, `Object` — JSON-like |
| 122-128 | `pub enum Number` | `Integer(i64)`, `Float(f64)` |
| 130-133 | `pub trait Extension` | `name() -> &str` + `calculate(context, scope, params) -> ExtensionResult` |
| 135-138 | `pub type Scope<'a>` | `HashMap<&'a str, ExtensionOutput>` |
| 140-145 | `pub enum ExtensionOutput` | `Single(String)`, `Multiple(HashMap<String, String>)` |
| 147-152 | `pub enum ExtensionResult` | `Success(ExtensionOutput)`, `Aborted`, `Error(anyhow::Error)` |
| 154-160 | `pub fn create()` | Factory: takes extensions → DefaultRenderer |

---

## renderer/mod.rs — DefaultRenderer (950 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-30 | `use` imports | regex, resolve, util, crate types |
| 32-40 | `static VAR_REGEX` | `\{\{\s*((?P<name>\w+)(\.(?P<subname>(\w+)))?)\s*\}\}` — matches `{{var}}` and `{{var.field}}` |
| 42-45 | `static WORD_REGEX` | `(\w+)` — used by CapitalizeWords casing |
| 47-55 | `pub struct DefaultRenderer<'a>` | `extensions: HashMap<String, &dyn Extension>` |
| 57-80 | `DefaultRenderer::new()` | Builds extension hashmap from Vec |
| 82-110 | `impl Renderer for DefaultRenderer` | Main render pipeline |
| 112-130 | Step 1: Variable resolution | If body has no `{{var}}`, skip to casing |
| 132-155 | Step 2: Global variable aliasing | Replace `var_type == "global"` with actual global var |
| 157-185 | Step 3: Dependency resolution | `resolve_evaluation_order()` → topological sort |
| 187-250 | Step 4: Variable evaluation | For each variable: call extension, build scope |
| 252-280 | Step 4a: "match" type | Recursive self-render for template references |
| 282-310 | Step 4b: Extension lookup | Find extension by var_type, inject vars, call calculate() |
| 312-340 | Step 5: Body substitution | `render_variables()` — regex replace `{{var}}` with scope |
| 342-360 | Step 6: Unescape | `\{\{` → `{{`, `\}\}` → `}}` |
| 362-380 | Step 7: Casing | Apply Capitalize/CapitalizeWords/Uppercase |
| 382-400 | Error handling | MissingVariable, CircularDependency |
| 402-950 | Tests | 30+ unit tests covering all rendering scenarios |

---

## renderer/resolve.rs — Dependency Resolution (203 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | std::collections |
| 17-25 | `pub struct Node<'a>` | `name`, `variable: Option<&Variable>`, `dependencies: HashSet<&str>` |
| 27-60 | `pub fn resolve_evaluation_order()` | Topological sort with cycle detection |
| 62-100 | `generate_nodes()` | Builds dependency graph from variables |
| 102-130 | `generate_nodes()` — local variables | Each depends on previous (ordering) + vars in params |
| 132-150 | `generate_nodes()` — global variables | Referenced globals added as dependencies |
| 152-170 | `generate_nodes()` — body node | Depends on all local vars + globals in body |
| 172-195 | `resolve_dependencies()` | DFS with seen/resolved sets |
| 197-203 | Cycle detection | `RendererError::CircularDependency` on cycle |

---

## renderer/util.rs — Variable Utilities (208 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | regex, crate types |
| 17-35 | `pub fn get_body_variable_names()` | Extracts all `{{var}}` names from template body |
| 37-60 | `pub fn get_params_variable_names()` | Recursively extracts var names from Value strings |
| 62-100 | `pub fn render_variables()` | Regex-replace `{{var}}` and `{{var.field}}` with scope values |
| 102-120 | `render_variables()` — Single handling | Direct string replacement |
| 122-140 | `render_variables()` — Multiple handling | Look up subfield in HashMap |
| 142-155 | `pub fn unescape_variable_inections()` | `\{\{` → `{{`, `\}\}` → `}}` |
| 157-185 | `pub fn inject_variables_into_params()` | Clone params, replace `{{var}}` refs in string values |
| 187-208 | Tests | 10+ test cases |

---

## extension/mod.rs — Module Re-exports

| Lines | Item | Description |
|-------|------|-------------|
| 1-29 | Re-exports | date, shell, script, choice, clipboard, exec_util, random, echo, form, util |

---

## extension/date.rs — Date Extension (817 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-20 | `use` imports | chrono, chrono-tz, crate types |
| 22-30 | `pub trait LocaleProvider` | `locale() -> Option<String>` |
| 32-40 | `pub struct DefaultLocaleProvider` | Uses `sys-locale` crate |
| 42-50 | `pub struct DateExtension<'a>` | `locale_provider: &'a dyn LocaleProvider` |
| 52-80 | `DateExtension::new()` | Constructor |
| 82-120 | `impl Extension for DateExtension` | Main logic: get time, apply offset, convert timezone, format |
| 122-150 | Offset handling | Parse `offset` param (int seconds or string) |
| 152-180 | Timezone handling | Convert via `chrono-tz` if `tz` param provided |
| 182-250 | Format handling | Use `format_localized()` with locale-aware formatting |
| 252-300 | Locale table | Massive match statement: `"en-US"` → `chrono::Locale::English` |
| 302-817 | Locale entries | 300+ locale mappings (en-US, fr-FR, de-DE, ja-JP, etc.) |

---

## extension/shell.rs — Shell Extension (461 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-20 | `use` imports | std::process, crate types |
| 22-30 | `pub struct ShellExtension` | `config_path: PathBuf` |
| 32-50 | `ShellExtension::new()` | Constructor |
| 52-100 | `impl Extension for ShellExtension` | Main logic: spawn shell, inject env vars, capture output |
| 102-130 | Shell detection | Default shell per OS (bash/zsh/powershell) |
| 132-170 | macOS PATH handling | `determine_default_macos_shell()` + PATH inheritance |
| 172-200 | WSL handling | `WSLENV` variable passing |
| 202-230 | Windows handling | Avoid shell window (creation flags) |
| 232-260 | Environment injection | Scope → `ESPANSO_*` env vars + `CONFIG` path |
| 262-300 | Exit status checking | Error on non-zero exit |
| 302-350 | Shell string parsing | Split cmd string for shell invocation |
| 352-461 | Tests | 10+ test cases |

---

## extension/script.rs — Script Extension (338 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | std::process, crate types |
| 17-25 | `pub struct ScriptExtension` | `home_path`, `config_path`, `packages_path` |
| 27-45 | `ScriptExtension::new()` | Constructor |
| 47-90 | `impl Extension for ScriptExtension` | Main logic: execute args[0] with args[1..] |
| 92-120 | Placeholder replacement | `%HOME%`, `%CONFIG%`, `%PACKAGES%` in args |
| 122-150 | Environment injection | Same as shell: `ESPANSO_*` env vars |
| 152-180 | Error handling | `ignore_error` param, non-zero exit |
| 182-220 | Debug mode | Print command + output when `debug=true` |
| 222-338 | Tests | 10+ test cases |

---

## extension/clipboard.rs — Clipboard Extension (115 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | crate types |
| 12-18 | `pub trait ClipboardProvider` | `get_text() -> Result<String>` |
| 20-28 | `pub struct ClipboardExtension<'a>` | `provider: &'a dyn ClipboardProvider` |
| 30-40 | `ClipboardExtension::new()` | Constructor |
| 42-60 | `impl Extension` | Call provider, return Single(text) |
| 62-115 | Tests | 5+ test cases |

---

## extension/echo.rs — Echo Extension (98 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | crate types |
| 12-18 | `pub struct EchoExtension` | `alias: String` (default "echo") |
| 20-30 | `EchoExtension::new()` | Constructor |
| 32-45 | `impl Extension` | Return params["echo"] as-is |
| 47-98 | Tests | 5+ test cases |

---

## extension/random.rs — Random Extension (110 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | rand, crate types |
| 12-18 | `pub struct RandomExtension` | Empty struct |
| 20-28 | `impl Extension` | Pick random from `choices` array |
| 30-50 | Implementation | `rand::thread_rng().gen_range(0..choices.len())` |
| 52-110 | Tests | 5+ test cases |

---

## extension/choice.rs — Choice Extension (132 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | crate types |
| 12-18 | `pub trait ChoiceSelector` | `select(values: &[ChoicePair]) -> Option<String>` |
| 20-25 | `pub struct ChoicePair` | `id: String`, `label: String` |
| 27-35 | `pub struct ChoiceExtension<'a>` | `selector: &'a dyn ChoiceSelector` |
| 37-50 | `impl Extension` | Parse values, call selector, return selected id |
| 52-132 | Tests | 5+ test cases |

---

## extension/form.rs — Form Extension (84 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-10 | `use` imports | crate types |
| 12-18 | `pub trait FormProvider` | `display(layout, fields) -> Option<HashMap<String, String>>` |
| 20-28 | `pub struct FormExtension<'a>` | `provider: &'a dyn FormProvider` |
| 30-45 | `impl Extension` | Call provider, return Multiple(result) |
| 47-84 | Tests | 3+ test cases |

---

## extension/exec_util.rs — macOS Shell Detection (112 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | std::process, std::path |
| 17-40 | `pub fn determine_default_macos_shell()` | Run `dscl . -read ~/ UserShell`, parse output |
| 42-70 | `pub fn determine_path_env_variable_override()` | Spawn login shell, extract PATH |
| 72-90 | Shell support | bash, fish, nu, pwsh, sh, zsh |
| 92-112 | Tests | 3+ test cases |

---

## extension/util.rs — Shared Utilities (75 lines)

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `use` imports | std::collections, crate types |
| 17-40 | `pub fn convert_to_env_variables()` | Scope → `HashMap<String, String>` with `ESPANSO_` prefix |
| 42-55 | `pub fn set_command_flags()` | Windows: `CREATE_NO_WINDOW`. No-op on other OS. |
| 57-75 | Tests | 3+ test cases |

---

## Cross-Reference: How Render Connects to Engine

```
espanso-config
  └── Match { vars: Vec<Variable>, effect: TextEffect { body, format } }
        └── Variable { name, var_type, params, depends_on, inject_vars }

espanso-render (this crate)
  ├── Renderer trait
  │     └── DefaultRenderer
  │           ├── resolve_evaluation_order() — topological sort
  │           ├── Extension::calculate() — 9 built-in extensions
  │           └── render_variables() — regex replace {{var}}
  │
  └── Extensions
        ├── DateExtension — date formatting
        ├── ShellExtension — shell command execution
        ├── ScriptExtension — script execution
        ├── ClipboardExtension — clipboard read
        ├── EchoExtension — passthrough
        ├── RandomExtension — random choice
        ├── ChoiceExtension — interactive choice
        └── FormExtension — GUI form input

espanso-engine (consumer)
  └── RenderMiddleware
        └── Calls renderer.render(template, context, options)
              └── Returns RenderResult::Success(text)
```

---

## Key Variables — Cross-Reference

| Variable | Defined | Used In |
|----------|---------|---------|
| `DefaultRenderer.extensions` | mod.rs:48 | process() extension lookup |
| `VAR_REGEX` | mod.rs:32 | render_variables(), get_body_variable_names() |
| `Scope` | lib.rs:138 | Variable evaluation, body substitution |
| `Node.dependencies` | resolve.rs:20 | resolve_dependencies() DFS |
| `ExtensionOutput::Single` | lib.rs:142 | Most extensions |
| `ExtensionOutput::Multiple` | lib.rs:143 | FormExtension only |

---

## Grep Patterns for Future Searches

```bash
# All Extension implementations
grep -rn "impl Extension for" espanso-render/src/

# All trait definitions
grep -rn "pub trait" espanso-render/src/

# All extension constructors
grep -rn "fn new(" espanso-render/src/

# Variable regex usage
grep -rn "VAR_REGEX" espanso-render/src/

# Template rendering
grep -rn "render_variables" espanso-render/src/

# Dependency resolution
grep -rn "resolve_evaluation_order" espanso-render/src/

# Casing styles
grep -rn "CasingStyle" espanso-render/src/

# Platform-specific code
grep -rn "target_os\|cfg!" espanso-render/src/
```

---

**Generated from:** espanso-render crate analysis
**Core files:** lib.rs (138 lines), renderer/mod.rs (950 lines), renderer/resolve.rs (203 lines), renderer/util.rs (208 lines)
**Total:** 15 files, 3,870 lines

## Related Pages

- [[06-espanso-render/SUMMARY]]
- [[07-espanso-engine/MAP]] — RenderMiddleware uses this crate
- [[05-espanso-config/SUMMARY]] — Config provides templates and variables
- [[01-CORE/CRATE_DEPENDENCIES]]
