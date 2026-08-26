# Area 25: Localization/Strings — Pre-Fix Verification Checklist

## Critical

- [ ] **1.1** `Strings:load()` must never allow `"original_strings"` to be loaded directly — verify the assertion at line 169 is preserved (strings.lua:169)
- [ ] **1.2** Shadow tables use weak keys (`__mode = "k"`) — verify no strong references prevent garbage collection of abandoned string tables (strings.lua:131)
- [ ] **1.3** The `Language()` function uses `error(good_error_marker)` to abort — verify the sentinel is always a unique empty table, never reused (strings.lua:83, strings.lua:103)
- [ ] **1.4** `_loadPrivate` falls back to English when the selected language is missing — verify the fallback does not trigger infinite recursion if English is also missing (strings.lua:331-337)

## High

- [ ] **2.1** Encoding conversion: `utf8conv` and `cp437conv` are applied at assignment time — verify no double-conversion occurs when a file switches encodings mid-stream (strings.lua:220-227, strings.lua:264-266)
- [ ] **2.2** Combining diacritical marks: verify `utf8char` correctly merges base character + combining mark into a single CP437 byte (strings.lua:619-649)
- [ ] **2.3** `string.upper` and `string.lower` are monkey-patched — verify the patch does not affect non-CP437 strings or break Lua's standard library contract (strings.lua:680-688)
- [ ] **2.4** `TH.stringProxy.format` uses LPeg — verify the `format_pattern` handles all edge cases: `%%`, `%s`, `%d`, `%1%`, `%1:tab%` (string_extensions.lua:57-103)
- [ ] **2.5** `strings_metatable.__newindex` prevents writes — verify no code path bypasses this to modify loaded string tables after `load()` returns (strings.lua:155-157)
- [ ] **2.6** `__random` returns a random value — verify the candidate collection iterates the shadow table, not the empty proxy table (strings.lua:148-153)

## Medium

- [ ] **3.1** `Inherit("original_strings", 0)` is called in every language file — verify the `0` argument is correctly forwarded through `_loadPrivate` (strings.lua:209-217)
- [ ] **3.2** Font declarations must occur before `Language()` — verify the `Font` function checks this ordering (strings.lua:202-205)
- [ ] **3.3** `getLocalisedText` fallback chain: current language → English → default — verify no nil dereference when all three are missing (strings.lua:314-320)
- [ ] **3.4** `setupAdviserMessage` priority resolution — verify `_priority` is inherited correctly through nested table indexing (strings.lua:345-405)
- [ ] **3.5** Language file sorting: `table.sort(self.languages)` sorts alphabetically — verify this does not depend on file system ordering (strings.lua:122)
- [ ] **3.6** CP437 mapping tables: verify `codepoints_to_cp437` and `cp437_to_codepoints` are consistent — no codepoint maps to two different CP437 values (strings.lua:413-505)

## Low

- [ ] **4.1** `LoadStrings` returns an infinite table during init — verify this does not cause memory issues with large string files (strings.lua:114)
- [ ] **4.2** The `Encoding()` function only accepts `utf8` or `cp437` — verify no other encoding values are silently accepted (strings.lua:220-227)
- [ ] **4.3** `isArabicNumerals` lookup uses lowercase key — verify consistent case handling with language names (strings.lua:306-308)
- [ ] **4.4** `getLanguageNames` returns the full names array — verify the first element is the display name, second is English name, third is language code (strings.lua:296-299)


## Related Pages

- [[MAP]]
- [[SUMMARY]]
