# Area 25: Localization/Strings — Technical Reference

## 1. Architecture Overview

The localization system spans three layers:

1. **Language file loading** — `strings.lua` discovers, parses, and evaluates 24 language files from `Lua/languages/`.
2. **String table resolution** — A shadow-table metatable system provides read-only, key-validated access with `__random` support.
3. **UTF-8/CP437 transcoding** — Bidirectional conversion between modern UTF-8 and Theme Hospital's legacy Code Page 437 font encoding.
4. **Font rendering** — C++ FreeType integration (`th_gfx_font.cpp`) handles glyph caching, CJK support, and RTL text.

### Key Source Files

| File | Lines | Role |
|------|-------|------|
| `CorsixTH/Lua/strings.lua` | 688 | String loading, shadow tables, CP437 conversion |
| `CorsixTH/Lua/string_extensions.lua` | 149 | `TH.stringProxy` gsub/format/find/sub |
| `CorsixTH/Lua/languages/*.lua` | 24 files | Language definition files |
| `CorsixTH/Src/th_gfx_font.cpp` | — | FreeType glyph rendering |
| `CorsixTH/Src/th_gfx_font.h` | — | Font class declarations |

See [[MAP]] for the complete file:line index.

---

## 2. Strings Class Initialization

```lua
-- strings.lua:30-32
function Strings:Strings(app)
  self.app = app
end
```

The constructor stores the app reference. All real initialization happens in `Strings:init()`.

### 2.1 `Strings:init()` (lines 38-123)

This method performs a two-phase initialization:

**Phase 1: Chunk loading (lines 41-53)**

Loads every `.lua` file in `Lua/languages/` using `loadfile_envcall` — the chunk is stored but not executed:

```lua
self.language_chunks = {}
for file in lfs.dir(path) do
  if file:match("%.lua$") then
    local result, err = loadfile_envcall(path .. file)
    if not result then
      print("Error loading languages" .. pathsep .. file .. ":\n" .. tostring(err))
    else
      self.language_chunks[result] = "languages" .. pathsep .. file
    end
  end
end
```

**Phase 2: Language registration (lines 58-122)**

Each chunk is executed in a sandboxed environment with an infinite-table metatable. The `Language()` function inside each file registers the language name(s) and triggers an early-exit error:

```lua
Language = function(...)
  local names = {...}
  if names[1] ~= "original_strings" then
    self.languages[#self.languages + 1] = names[1]
    self.languages_english[names[1]] = names[2]
  end
  for _, name in pairs(names) do
    self.language_to_chunk[name:lower()] = chunk
    self.language_to_lang_code[name:lower()] = names[3]
  end
  self.chunk_to_names[chunk] = names
  error(good_error_marker)  -- abort evaluation after Language()
end
```

The `good_error_marker` is a fresh empty table used as a unique sentinel — its identity distinguishes it from real errors.

### 2.2 Registration Tables

After `init()`, the following lookup tables are populated:

| Table | Key | Value | Purpose |
|-------|-----|-------|---------|
| `languages` | — | array | Sorted list of display names |
| `languages_english` | display name | English name | Tooltip text |
| `language_to_chunk` | name (lowercase) | chunk function | Language file lookup |
| `chunk_to_font` | chunk | font declaration | Per-language font |
| `chunk_to_names` | chunk | names array | All aliases |
| `language_to_lang_code` | name (lowercase) | ISO code | Language code for i18n |
| `languages_with_arabic_numerals` | language | boolean | Numeral system flag |

---

## 3. String Loading and Inheritance

### 3.1 `Strings:load()` (lines 168-288)

The primary method for loading a complete language:

```lua
function Strings:load(language, no_restriction, no_inheritance)
  assert(language ~= "original_strings", "Original strings can not be loaded directly.")
```

**Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `language` | string | — | Language name (case-insensitive) |
| `no_restriction` | boolean | `false` | Allow missing string keys (debug) |
| `no_inheritance` | boolean | `false` | Disable non-original inheritance (debug) |

**Returns:** `env` table (string tables), `speech_file` string or nil.

### 3.2 Shadow Table System (lines 125-164)

Every string table is actually empty — its data lives in a separate shadow table accessed via metatables:

```lua
local shadows = setmetatable({}, {__mode = "k"})  -- weak-keyed
```

The `strings_metatable` provides:

1. **`__index`**: Looks up keys in the shadow. Missing keys raise errors (unless `no_restriction`). The special key `__random` returns a random string from the table.
2. **`__newindex`**: Prevents writes — string tables are read-only.
3. **`__pairs` / `__ipairs`**: Delegate to the shadow table for iteration.

```lua
-- strings.lua:138-164
local strings_metatable = function(no_restriction) return {
  __index = function(t, key)
    t = shadows[t]
    local val = t[key]
    if val ~= nil then return val end
    if key ~= "__random" then
      if no_restriction then return nil end
      error("Non-existent string: " .. tostring(key), 2)
    end
    local candidates = {}
    for _, v in pairs(t) do
      candidates[#candidates + 1] = v
    end
    return candidates[math.random(1, #candidates)]
  end,
  __newindex = function(_, _, _)
    error("String tables are read-only", 2)
  end,
} end
```

### 3.3 Environment Metatable (lines 247-278)

During loading, the environment table uses a special metatable that:

1. Makes `Inherit`, `Language`, `Font`, etc. look like globals.
2. Recursively merges table assignments (line 270-276).
3. Applies encoding conversion on string assignments (line 265-266).

```lua
__newindex = function(t, k, v)
  local ty = type(v)
  if ty ~= "table" then
    if ty == "string" then
      v = encoding(v)  -- convert from file's encoding to UTF-8
    end
    shadows[t][k] = v
  else
    -- Merge table into t[k]
    t = t[k]
    for k2, v2 in pairs(v) do
      t[k2] = v2
    end
  end
end
```

### 3.4 Inheritance Chain

Language files use `Inherit("original_strings", 0)` to pull in the base Theme Hospital string table:

```lua
-- Inside e.g. english.lua:
Inherit("original_strings", 0)
```

The `Inherit` function (line 209-217) calls `_loadPrivate` on the named language, evaluating its chunk in the current environment. This means the original strings provide defaults that can be overridden by the inheriting language.

The `original_strings` language is special — it cannot be loaded directly (assertion at line 169) and is always available regardless of the `no_inheritance` flag (line 210).

---

## 4. String Lookup API

### 4.1 `_S` Global

The primary user-facing interface is the `_S` global (aliased to the env table returned by `load`). Usage:

```lua
_S.hospital_information.tutorial_text
_S.menu_file.quit
```

Missing keys raise errors (read-only, strict mode) unless `no_restriction` was set.

### 4.2 `__random` Support

Any string table supports `__random`:

```lua
local random_tip = _S.tips.__random  -- returns a random tip string
```

This is implemented in the `__index` metamethod (line 148-153).

### 4.3 Adviser Messages with Priority (`setupAdviserMessage`, lines 345-405)

The adviser system uses a priority-weighted message chain:

```lua
local prioTable = {
  _priority = 5,
  tutorial = { _priority = 11 },
  epidemic = { _priority = 6 },
  warnings = { _priority = 10 },
  praise = { _priority = 1 },
}
```

Messages are accessed via chained indexing with automatic priority resolution:

```lua
local msg = _S.adviser:setupAdviserMessage(_S)
local formatted = msg.tutorial.some_key:format(arg1, arg2)
-- Returns: { text = "...", priority = 11 }
```

The `formatFunc` (line 372-375) applies `string.format` and attaches the resolved priority.

### 4.4 `getLocalisedText` (lines 314-320)

Returns text in the current language, falling back to English:

```lua
function Strings:getLocalisedText(string, table)
  if string and not table then return string
  elseif table[self:getLangCode()] then return table[self:getLangCode()]
  elseif table.en then return table.en
  else return string
  end
end
```

---

## 5. CP437 / UTF-8 Transcoding

### 5.1 Why CP437?

Theme Hospital uses bitmap fonts encoded in Code Page 437. CorsixTH language files are written in UTF-8, so conversion is needed at load time.

### 5.2 `codepoints_to_cp437` (lines 413-456)

Maps Unicode codepoints to CP437 byte values. Notable entries:

```lua
[0xC7] = 0x80,  -- c-cedilla
[0xE9] = 0x82,  -- e-acute
[0xDF] = 0xE1,  -- eszett / sharp-S
```

### 5.3 `cp437_to_codepoints` (lines 458-505)

The reverse mapping, including Greek letters and mathematical symbols:

```lua
[0xE0] = 0x3B1,  -- alpha
[0xE3] = 0x3C0,  -- pi
[0xEC] = 0x221E, -- infinity
```

### 5.4 Combining Diacritical Marks (lines 550-617)

The `combine_diacritical_marks` table handles precomposed character composition:

```lua
combine_diacritical_marks = {
  a = {
    [0x300] = 0xE0,  -- grave
    [0x301] = 0xE1,  -- acute
    [0x302] = 0xE2,  -- circumflex
    [0x304] = 0xE4,  -- umlaut
    [0x305] = 0xE5,  -- ring
  },
  -- ... more base characters
}
```

During UTF-8 to CP437 conversion, a combining mark following a base character is merged into the precomposed form before mapping to CP437.

### 5.5 `utf8conv` / `cp437conv` (lines 532-658)

Two conversion functions:

- **`cp437conv(s)`** (line 546-548): Converts CP437 bytes to UTF-8 using a precomputed `gsub` pattern.
- **`utf8conv(s)`** (line 652-659): Converts UTF-8 to CP437, handling combining marks.

Both are applied at string assignment time based on the file's `Encoding()` declaration.

### 5.6 Case Conversion Fix (lines 661-688)

`string.upper` and `string.lower` are monkey-patched to handle CP437 characters:

```lua
local case_pattern = "\195[\128-\191]"  -- Unicode range [0xC0, 0xFF]
function string.upper(s)
  return orig_upper(s:gsub(case_pattern, lower_to_upper))
end
```

---

## 6. TH.stringProxy System

### 6.1 Purpose

`TH.stringProxy` wraps strings to preserve localization metadata through string operations. When a proxy string is formatted or concatenated, the result retains its proxy nature.

### 6.2 `string_extensions.lua` Methods

| Method | Lines | Description |
|--------|-------|-------------|
| `TH.stringProxy.gsub(str, patt, repl)` | 25-55 | Localized pattern replacement |
| `TH.stringProxy.format(str, ...)` | 119-128 | Localized formatting with `%1%`, `%2:tab%` syntax |
| `TH.stringProxy.find(str, ...)` | 131-134 | Unwrap and delegate to `string.find` |
| `TH.stringProxy.sub(str, ...)` | 137-145 | Localized substring extraction |

### 6.3 Custom Format Syntax (lines 57-103)

The `format_pattern` LPeg pattern supports:

| Syntax | Meaning |
|--------|---------|
| `%s` | String substitution (old-style) |
| `%d` | Number substitution (old-style) |
| `%%` | Literal percent sign |
| `%1%` through `%9%` | Positional substitution |
| `%1:tab%` | Index into string table `_S.tab` |

The new-style `%[num]:[tab]%` syntax (line 80-100) enables cross-language string references:

```lua
-- In a language file:
_S.disease_name = _S.expertise[1].name  -- references another string table
```

---

## 7. Language Files

### 7.1 Supported Languages (24 files)

| Language | File | Code |
|----------|------|------|
| English | `english.lua` | `en` |
| Chinese (simplified) | `simplified_chinese.lua` | `zh(s)` |
| Chinese (traditional) | `traditional_chinese.lua` | `zh(t)` |
| Japanese | `japanese.lua` | `ja` |
| Korean | `korean.lua` | `kor` |
| Arabic | — | — |
| Brazilian Portuguese | `brazilian_portuguese.lua` | `pt_br` |
| Czech | `czech.lua` | `cs` |
| Danish | `danish.lua` | `da` |
| Dutch | `dutch.lua` | `nl` |
| Finnish | `finnish.lua` | `fi` |
| French | `french.lua` | `fr` |
| German | `german.lua` | `de` |
| Greek | `greek.lua` | `el` |
| Hungarian | `hungarian.lua` | `hu` |
| Italian | `italian.lua` | `it` |
| Norwegian | `norwegian.lua` | `nb` |
| Polish | `polish.lua` | `pl` |
| Portuguese | `iberic_portuguese.lua` | `pt` |
| Russian | `russian.lua` | `ru` |
| Spanish | `spanish.lua` | `es` |
| Swedish | `swedish.lua` | `sv` |
| Ukrainian | `ukrainian.lua` | `uk` |
| Developer | `developer.lua` | — |
| Original Strings | `original_strings.lua` | — |

### 7.2 Language File Structure

Every language file follows this pattern:

```lua
Encoding(utf8)  -- or cp437
Font("font_name.ttf")
Language("French", "Francais", "fr")
Inherit("original_strings", 0)

-- String overrides:
menu_file = {
  load = "Charger",
  save = "Sauvegarder",
  -- ...
}
```

### 7.3 Font Declarations

The `Font()` function (called before `Language()`) associates a font file with the language:

```lua
Font("GoNotoCJK.ttf")  -- for CJK languages
```

Fallback chain: CP437 bitmap → FreeType Unicode → GoNoto CJK.

---

## 8. RTL Text Handling

Arabic and Hebrew require right-to-left text rendering. The `IsArabicNumerals` function in language files:

```lua
IsArabicNumerals(true)  -- Use Eastern Arabic numerals (٠١٢٣٤٥٦٧٨٩)
```

This is stored in `self.languages_with_arabic_numerals` and checked via `Strings:isArabicNumerals()`.

RTL text rendering is handled in `th_gfx_font.cpp` using FreeType's bidirectional text support.

---

## 9. Font System (C++)

### 9.1 FreeType Integration

`th_gfx_font.cpp` uses FreeType for:

1. **Glyph rasterization** — Converts vector outlines to bitmaps.
2. **Glyph caching** — Avoids re-rasterization for frequently used characters.
3. **CJK support** — Large character sets require efficient lookup.
4. **Font fallback** — Multiple font files can be chained.

### 9.2 Font Loading

The font file path is determined by:

1. The `Font()` declaration in the language file.
2. The `unicode_font` config setting.
3. The built-in fallback fonts.

---

## 10. String Lookup Flow

Complete resolution path for `_S.menu_file.load`:

```
_S (env table)
  → __index metamethod (line 249)
    → shadows[env]["menu_file"] (returns nested table)
      → __index on menu_file (via strings_metatable)
        → shadows[menu_file]["load"] (returns string)
```

If the key is missing and `no_restriction` is false, an error is raised. If `__random` is requested, a random value from the table is returned.

---

## 11. Error Handling

| Condition | Behavior |
|-----------|----------|
| Language file fails to load | Prints error, continues with other files (line 48) |
| Language file fails to evaluate | Prints error if `good_install_folder` (line 118) |
| Unknown language selected | Falls back to English (line 331-337) |
| English not found | Raises fatal error (line 336) |
| Missing string key | Raises error (line 147) or returns nil (debug mode) |
| Invalid encoding declaration | Raises error (line 225) |

See [[CHECKLIST]] for pre-fix verification items.

---

## Related Pages

- [[MAP]] — File:line index for rapid navigation across all localization source files
- [[SCAFFOLD]] — Busted test templates for string loading and transcoding
- [[CHECKLIST]] — Pre-fix verification checklist with priority-ordered items
