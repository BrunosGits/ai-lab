# espanso-render — System Analysis

## 1. What Is This?

The espanso-render crate is the template rendering engine for espanso. When a match is detected (like `:email`), this crate takes the template body (`{{name}} <{{name}}@example.com>`), evaluates variables (date, script, clipboard, etc.), substitutes them, and produces the final text. It's 15 files, 3,870 lines — medium complexity with 9 built-in extensions.

## 2. Why Does It Exist?

Espanso's power comes from template rendering — not just static text replacement, but dynamic content:
- `{{date}}` → current date
- `{{clipboard}}` → clipboard contents
- `{{shell(cmd="whoami")}}` → command output
- `{{form}}` → user input dialog

The render crate handles all of this through a clean extension system.

## 3. How Does It Work?

### The Rendering Pipeline

```
1. Template arrives: body="Hello {{name}}", vars=[{name, echo, {echo: "World"}}]
   │
2. Check if body contains {{var}} via VAR_REGEX
   │  If no variables → skip to step 8
   │
3. Resolve "global" type aliases
   │  Replace var_type == "global" with actual global variable
   │
4. Build dependency graph (topological sort)
   │  Variables evaluated in dependency order
   │  Circular dependencies detected → error
   │
5. Evaluate variables in order, building Scope
   │  For each Variable:
   │    a. If var_type == "match" → recursive render
   │    b. Else → look up extension, inject vars, call calculate()
   │
6. Substitute variables in body
   │  render_variables("Hello {{name}}", {name: "World"})
   │  → "Hello World"
   │
7. Unescape: \{\{ → {{ and \}\} → }}
   │
8. Apply casing style (None/Capitalize/CapitalizeWords/Uppercase)
   │
9. Return RenderResult::Success("Hello World")
```

### Dependency Resolution

Variables can reference each other:
```yaml
vars:
  - name: firstname
    type: echo
    params: { echo: "John" }
  - name: fullname
    type: echo
    params: { echo: "{{firstname}} {{lastname}}" }
  - name: lastname
    type: echo
    params: { echo: "Doe" }
```

The resolver builds a dependency graph:
- `firstname` depends on nothing
- `lastname` depends on nothing
- `fullname` depends on `firstname` and `lastname`

Topological sort ensures `firstname` and `lastname` are evaluated before `fullname`.

### Variable Injection

When `inject_vars: true` (the default), the renderer replaces `{{var}}` references in a variable's params before calling the extension:

```rust
// Before injection:
params = { echo: "{{firstname}} {{lastname}}" }

// After injection (scope = {firstname: "John", lastname: "Doe"}):
params = { echo: "John Doe" }
```

This is what makes inter-variable references work.

### Body Substitution

After all variables are evaluated, the body is processed:

```rust
// body = "Hello {{name}}, today is {{date}}"
// scope = {name: "World", date: "2026-08-25"}
render_variables(body, scope)
// → "Hello World, today is 2026-08-25"
```

The `VAR_REGEX` matches both `{{var}}` and `{{var.field}}` (for multi-value outputs like forms).

## 4. The Extension System

Nine built-in extensions:

### Date (817 lines — largest)
Formats dates with locale support. Params: `format` (strftime), `offset` (seconds), `tz` (timezone), `locale`.

```yaml
vars:
  - name: today
    type: date
    params:
      format: "%Y-%m-%d"
      tz: "America/New_York"
```

300+ locale mappings (en-US, fr-FR, de-DE, ja-JP, etc.). Uses `chrono` + `chrono-tz`.

### Shell (461 lines)
Executes shell commands. Params: `cmd` (string), `shell` (optional: bash/zsh/powershell/etc.), `trim` (default true).

```yaml
vars:
  - name: output
    type: shell
    params:
      cmd: "whoami"
```

Platform-specific: macOS auto-detects default shell and inherits PATH. Windows avoids shell window. WSL uses WSLENV.

### Script (338 lines)
Executes scripts with args array. Params: `args` (array), `trim` (default true).

```yaml
vars:
  - name: result
    type: script
    params:
      args: ["python3", "script.py", "%CONFIG%"]
```

Replaces `%HOME%`, `%CONFIG%`, `%PACKAGES%` placeholders in args.

### Clipboard (115 lines)
Reads clipboard contents. No params.

```yaml
vars:
  - name: clip
    type: clipboard
```

### Echo (98 lines)
Passthrough — returns the `echo` param as-is. Useful for static/computed strings.

```yaml
vars:
  - name: greeting
    type: echo
    params:
      echo: "Hello, World!"
```

### Random (110 lines)
Picks random from array. Params: `choices` (array).

```yaml
vars:
  - name: greeting
    type: random
    params:
      choices: ["Hello", "Hi", "Hey"]
```

### Choice (132 lines)
Interactive choice selector. Params: `values` (newline-separated string or array of {id, label}).

```yaml
vars:
  - name: lang
    type: choice
    params:
      values: |
        python
        rust
        go
```

Returns selected value via injected `ChoiceSelector` (GUI-dependent).

### Form (84 lines)
GUI form input. Params: `layout` (string), `fields` (optional object).

```yaml
vars:
  - name: form
    type: form
    params:
      layout: |
        Hello {{name}}, how are you?
```

Returns `ExtensionOutput::Multiple(HashMap)` — multiple field values accessible as `{{form.field_name}}`.

## 5. Edge Cases

### Missing Variable

If a variable referenced in the body is not in scope, `render_variables()` returns `RendererError::MissingVariable`. This is a hard error — the render fails.

### Circular Dependency

If variable A depends on B and B depends on A, `resolve_dependencies()` detects the cycle and returns `RendererError::CircularDependency`. The render fails with a clear error message.

### Aborted Extension

If an extension returns `ExtensionResult::Aborted`, the entire render is aborted. This is used by interactive extensions (choice, form) when the user cancels.

### Escaping

Users can produce literal `{{` in output by writing `\{\{` in templates. The `unescape_variable_inections()` function handles this.

### Multiple Output Values

The `form` extension returns `ExtensionOutput::Multiple(HashMap)`. Templates can reference specific fields with `{{form.field_name}}`. Other extensions return `ExtensionOutput::Single(String)`.

## 6. Key Patterns

### Dependency Injection

All extensions accept trait objects (`ClipboardProvider`, `ChoiceSelector`, `FormProvider`, `LocaleProvider`). This makes the render crate testable — you can inject mock providers.

### Lazy Evaluation

Variables are evaluated on-demand, not eagerly. The topological sort ensures dependencies are resolved before dependents, but variables not referenced in the body or by other variables are never evaluated.

### Regex-Based Substitution

The `VAR_REGEX` pattern handles both `{{var}}` and `{{var.field}}` in a single regex. The `subname` capture group enables multi-value access for form outputs.

### Extension Registry

Extensions are registered by name in a `HashMap<String, &dyn Extension>`. The `var_type` field in config maps to the extension name. Unknown types produce an error.

## 7. Risk Assessment for Changes

| Area | Risk | Why |
|------|------|-----|
| renderer/mod.rs | HIGH | Core pipeline, all rendering passes through here |
| resolve.rs | MEDIUM | Dependency resolution, cycle detection |
| renderer/util.rs | MEDIUM | Variable substitution, regex handling |
| extension/shell.rs | MEDIUM | Shell execution, platform-specific |
| extension/date.rs | LOW | Locale table, isolated |
| extension/script.rs | LOW | Script execution, isolated |
| Other extensions | LOW | Simple, isolated |

## 8. What Was Studied

- **Files:** All 15 files in espanso-render/src/
- **Key Files:** lib.rs, renderer/mod.rs, renderer/resolve.rs, renderer/util.rs, extension/shell.rs, extension/date.rs, extension/script.rs
- **Patterns:** Dependency injection, topological sort, regex substitution, lazy evaluation, extension registry
- **Missing:** Nothing — this crate is fully studied
- **Coverage:** 100%

## 9. Evidence

- `espanso-render/src/lib.rs` — Core types and traits (138 lines)
- `espanso-render/src/renderer/mod.rs` — DefaultRenderer (950 lines)
- `espanso-render/src/renderer/resolve.rs` — Dependency resolution (203 lines)
- `espanso-render/src/renderer/util.rs` — Variable utilities (208 lines)
- `espanso-render/src/extension/date.rs` — Date extension (817 lines)
- `espanso-render/src/extension/shell.rs` — Shell extension (461 lines)
- `espanso-render/src/extension/script.rs` — Script extension (338 lines)
- `espanso-render/src/extension/clipboard.rs` — Clipboard extension (115 lines)
- `espanso-render/src/extension/echo.rs` — Echo extension (98 lines)
- `espanso-render/src/extension/random.rs` — Random extension (110 lines)
- `espanso-render/src/extension/choice.rs` — Choice extension (132 lines)
- `espanso-render/src/extension/form.rs` — Form extension (84 lines)
- `espanso-render/src/extension/exec_util.rs` — macOS shell detection (112 lines)
- `espanso-render/src/extension/util.rs` — Shared utilities (75 lines)
- `espanso-render/src/extension/mod.rs` — Module re-exports (29 lines)

## Related Pages

- [[06-espanso-render/MAP]]
- [[07-espanso-engine/MAP]] — RenderMiddleware uses this crate
- [[05-espanso-config/SUMMARY]] — Config provides templates and variables
- [[01-CORE/CRATE_DEPENDENCIES]]
