# Area 25: Localization/Strings — File:Line Index

## Lua Source

### strings.lua (688 lines)

| Line(s) | Symbol / Block | Description |
|---------|---------------|-------------|
| 21-22 | Imports | `lfs`, `TH` |
| 25 | `class "Strings"` | Class declaration |
| 30-32 | `Strings:Strings()` | Constructor |
| 34-36 | `utf8conv` / `cp437conv` / `id` | Forward declarations |
| 38-123 | `Strings:init()` | Two-phase language initialization |
| 41-53 | Phase 1: chunk loading | `loadfile_envcall` for each `.lua` in languages/ |
| 58-122 | Phase 2: language registration | Executes each chunk, calls `Language()` |
| 74-78 | Infinite table metatable | Prevents errors on undefined globals |
| 83 | `good_error_marker` | Unique sentinel for early-exit |
| 88-103 | `Language()` function | Registers language names and chunk mappings |
| 105-114 | Other functions | `Font`, `Inherit` (noop), `SetSpeechFile`, etc. |
| 125-131 | `shadows` table | Weak-keyed shadow storage |
| 138-164 | `strings_metatable()` | Metatable factory for string tables |
| 139-153 | `__index` | Key lookup + `__random` support |
| 155-157 | `__newindex` | Read-only enforcement |
| 158-163 | `__pairs` / `__ipairs` | Iteration delegation |
| 168-288 | `Strings:load()` | Full language load with environment |
| 169 | Assertion | Prevents direct loading of `original_strings` |
| 172-243 | Environment setup | Functions table with `Inherit`, `Encoding`, etc. |
| 181-186 | `utf8()` function | Convert UTF-8 to file's encoding |
| 189-193 | `cp437()` function | Convert CP437 to file's encoding |
| 209-217 | `Inherit()` function | Load parent language into current env |
| 220-227 | `Encoding()` function | Set encoding for remainder of file |
| 230-233 | `LoadStrings()` | Load original game string table |
| 235-237 | `SetSpeechFile()` | Store speech file name |
| 238-240 | `IsArabicNumerals()` | Set Arabic numeral flag |
| 247-278 | Environment metatable | Global-like access + table merging |
| 260-276 | `__newindex` | Encoding conversion + table merge |
| 279-287 | Final metatable setup | Apply `strings_metatable` |
| 291-293 | `Strings:getFont()` | Get font declaration for a language |
| 296-299 | `Strings:getLanguageNames()` | Get names array for a language |
| 301-304 | `Strings:getLangCode()` | Get ISO language code |
| 306-308 | `Strings:isArabicNumerals()` | Check Arabic numeral flag |
| 314-320 | `Strings:getLocalisedText()` | Localized text with fallback |
| 325-327 | `Strings:checkLanguageExists()` | Validate language name |
| 329-343 | `Strings:_loadPrivate()` | Internal language file evaluation |
| 331-337 | English fallback | Falls back to English on missing language |
| 345-405 | `Strings:setupAdviserMessage()` | Priority-weighted message chain |
| 372-375 | `formatFunc` | String.format with priority attachment |
| 377-395 | `indexFunc` | Recursive indexing with priority resolution |
| 408-456 | `codepoints_to_cp437` | Unicode → CP437 mapping |
| 458-505 | `cp437_to_codepoints` | CP437 → Unicode mapping |
| 507-530 | `utf8encode()` | Codepoint to UTF-8 bytes |
| 532-548 | `cp437conv` | CP437 to UTF-8 via gsub |
| 550-617 | `combine_diacritical_marks` | Combining mark → precomposed mapping |
| 619-650 | `utf8char()` | Single UTF-8 char to CP437 |
| 652-659 | `utf8conv` | UTF-8 to CP437 via gsub |
| 661-688 | Case conversion patch | `string.upper` / `string.lower` override |

### string_extensions.lua (149 lines)

| Line(s) | Symbol | Description |
|---------|--------|-------------|
| 21-23 | Imports | `TH`, `lpeg`, `_unwrap` |
| 25-55 | `TH.stringProxy.gsub()` | Localized pattern replacement |
| 57-103 | `format_pattern` | LPeg pattern for format keywords |
| 63-78 | Old-style `%s`/`%d` | Positional format keywords |
| 80-100 | New-style `%[num]%`/`%[num]:[tab]%` | Named format keywords |
| 119-128 | `TH.stringProxy.format()` | Localized format function |
| 131-134 | `TH.stringProxy.find()` | Unwrap + delegate |
| 137-145 | `TH.stringProxy.sub()` | Localized substring |
| 147-149 | Permanent registration | Registers methods as permanents |

## Language Files (24 files in Lua/languages/)

| File | Language | Code |
|------|----------|------|
| `english.lua` | English | `en` |
| `simplified_chinese.lua` | Chinese (simplified) | `zh(s)` |
| `traditional_chinese.lua` | Chinese (traditional) | `zh(t)` |
| `japanese.lua` | Japanese | `ja` |
| `korean.lua` | Korean | `kor` |
| `brazilian_portuguese.lua` | Brazilian Portuguese | `pt_br` |
| `czech.lua` | Czech | `cs` |
| `danish.lua` | Danish | `da` |
| `dutch.lua` | Dutch | `nl` |
| `finnish.lua` | Finnish | `fi` |
| `french.lua` | French | `fr` |
| `german.lua` | German | `de` |
| `greek.lua` | Greek | `el` |
| `hungarian.lua` | Hungarian | `hu` |
| `italian.lua` | Italian | `it` |
| `norwegian.lua` | Norwegian | `nb` |
| `polish.lua` | Polish | `pl` |
| `iberic_portuguese.lua` | Portuguese | `pt` |
| `russian.lua` | Russian | `ru` |
| `spanish.lua` | Spanish | `es` |
| `swedish.lua` | Swedish | `sv` |
| `ukrainian.lua` | Ukrainian | `uk` |
| `developer.lua` | Developer | — |
| `original_strings.lua` | Original Strings | — |

## C++ Source

### th_gfx_font.h / th_gfx_font.cpp

| Area | Description |
|------|-------------|
| FreeType init | Library initialization and face loading |
| Glyph cache | LRU cache for rasterized glyphs |
| CJK support | Large character set handling |
| RTL rendering | Bidirectional text for Arabic/Hebrew |
| Font fallback | Chain of font files for missing glyphs |


## Related Pages

- [[CHECKLIST]]
- [[SUMMARY]]
