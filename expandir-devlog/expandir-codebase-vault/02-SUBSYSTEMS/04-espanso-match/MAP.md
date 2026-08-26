# espanso-match — File:Line Index

Complete cross-reference for all code in the espanso-match crate (8 files, 1,553 lines).

---

## lib.rs — Crate Root

| Lines | Item | Description |
|-------|------|-------------|
| 1-7 | `use` imports | regex, rolling modules |
| 9-14 | `pub struct MatchResult<Id>` | Universal output: `id`, `trigger`, `left/right_separator`, `vars: HashMap<String, String>` |
| 16-20 | `MatchResult::new()` | Constructor |
| 22-27 | `pub trait Matcher<'a, State, Id>` | Core trait: `process(prev_state, event) -> (State, Vec<MatchResult<Id>>)` |
| 29-55 | Re-exports | `RollingMatcher`, `RollingMatch`, `RollingItem`, `StringMatchOptions`, `RegexMatcher`, `RegexMatch`, `Event`, `Key` |

---

## event.rs — Event Types

| Lines | Item | Description |
|-------|------|-------------|
| 1-8 | `pub enum Event` | `Key { key: Key, chars: Option<String> }`, `VirtualSeparator` |
| 10-50 | `pub enum Key` | 30+ key variants: Alt, Control, Meta, Shift, Enter, Tab, Space, ArrowDown/Left/Right/Up, Home, End, PageDown, PageUp, Escape, Backspace, F1-F20, Other |
| 52-81 | `Key` methods | `from_char()`, `to_char()`, `is_modifier()`, `is_printable()` |

---

## rolling/mod.rs — Rolling Match Pattern

| Lines | Item | Description |
|-------|------|-------------|
| 1-12 | `pub enum RollingItem` | `WordSeparator`, `Key(Key)`, `Char(String)`, `CharInsensitive(UniCase<String>)` |
| 14-20 | `pub struct RollingMatch<Id>` | `id: Id`, `items: Vec<RollingItem>` |
| 22-30 | `pub struct StringMatchOptions` | `case_insensitive: bool`, `left_word: bool`, `right_word: bool` |
| 32-80 | `RollingMatch::from_string()` | Converts string + options → RollingItem sequence |
| 82-100 | `RollingMatch::from_items()` | Direct constructor from RollingItem slice |
| 102-172 | `RollingMatch::from_string_multiword()` | Splits on whitespace, handles word boundaries per-word |

---

## rolling/matcher.rs — RollingMatcher

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `pub struct RollingMatcherOptions` | `char_word_separators: Vec<String>`, `key_word_separators: Vec<Key>` |
| 17-22 | `pub struct RollingMatcher<'a, Id>` | `root: &'a MatcherTreeNode<Id>`, `options: RollingMatcherOptions` |
| 24-40 | `RollingMatcher::new()` | Builds trie from matches, stores reference |
| 42-55 | `pub struct RollingMatcherState<'a, Id>` | `paths: Vec<RollingMatcherStatePath<'a, Id>>` |
| 57-65 | `pub struct RollingMatcherStatePath<'a, Id>` | `node: &'a MatcherTreeNode<Id>`, `events: Vec<(Event, IsWordSeparator)>` |
| 67-80 | `RollingMatcherState::default()` | Empty state (reset after match) |
| 82-130 | `impl Matcher` — `process()` | Core algorithm: extend paths + start new path from root |
| 132-155 | `process_inner()` | Logic: for each path, call `find_refs()`, evaluate results |
| 157-195 | `find_refs()` | Trie traversal: match char/key/word-separator edges |
| 197-210 | `find_refs()` — word separator handling | Implicit boundary at start of buffer |
| 212-230 | `find_refs()` — modifier handling | Skip modifier keys during matching |
| 232-255 | Match evaluation | If `Matches(ids)` → extract string, return match. If `Node(node)` → continue path |
| 257-280 | New path creation | Clone root, start new path for every incoming event |
| 282-352 | State management | Handle empty state (first event), accumulate paths, reset on match |

---

## rolling/tree.rs — Trie Structure

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `pub enum MatcherTreeRef<Id>` | `Matches(Vec<Id>)` (leaf), `Node(Box<MatcherTreeNode<Id>>)` (internal) |
| 17-25 | `pub struct MatcherTreeNode<Id>` | `word_separators: Option<MatcherTreeRef>`, `keys: Vec<(Key, MatcherTreeRef)>`, `chars: Vec<(String, MatcherTreeRef)>`, `chars_insensitive: Vec<(UniCase<String>, MatcherTreeRef)>` |
| 27-50 | `MatcherTreeNode::from_matches()` | Builds trie from RollingMatch slice |
| 52-100 | `insert_items_recursively()` | Inserts RollingItem sequence into trie, creating nodes as needed |
| 102-130 | `insert_items_recursively()` — WordSeparator | Follow/create word_separators edge |
| 132-160 | `insert_items_recursively()` — Char | Follow/create chars edge (case-sensitive) |
| 162-190 | `insert_items_recursively()` — CharInsensitive | Follow/create chars_insensitive edge (UniCase) |
| 192-220 | `insert_items_recursively()` — Key | Follow/create keys edge |
| 222-260 | `find_refs()` — char matching | Check chars + chars_insensitive edges |
| 262-290 | `find_refs()` — key matching | Check keys edge |
| 292-320 | `find_refs()` — word separator matching | Check word_separators edge |
| 322-353 | `find_refs()` — implicit word boundary | If no previous state, recursively explore word_separators child |

---

## rolling/util.rs — String Reconstruction

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `pub fn extract_string_from_events()` | Rebuilds trigger string from event history |
| 17-40 | String building | Iterate events, append chars to build trigger |
| 42-65 | Separator detection | First word-separator event = left_separator, last = right_separator |
| 67-100 | Return | `(trigger_string, left_separator, right_separator)` |
| 102-223 | Tests | 10+ test cases for string extraction |

---

## regex/mod.rs — RegexMatcher

| Lines | Item | Description |
|-------|------|-------------|
| 1-15 | `pub struct RegexMatch<Id>` | `id: Id`, `regex: String` |
| 17-25 | `pub struct RegexMatcherOptions` | `max_buffer_size: usize` (default 30) |
| 27-45 | `pub struct RegexMatcher<Id>` | `ids: Vec<Id>`, `regex_set: RegexSet`, `regexes: Vec<Regex>`, `max_buffer_size: usize` |
| 47-80 | `RegexMatcher::new()` | Compile regexes, build RegexSet, skip invalid |
| 82-90 | `pub struct RegexMatcherState` | `buffer: String` |
| 92-100 | `RegexMatcherState::default()` | Empty buffer (reset after match) |
| 102-180 | `impl Matcher` — `process()` | Buffer chars, trim if oversized, screen with RegexSet, extract captures |
| 182-200 | Buffer management | Append chars, trim front if exceeds max_buffer_size |
| 202-220 | RegexSet screening | `regex_set.is_match(&buffer)` — fast check |
| 222-250 | Capture extraction | For each matching regex, run `captures()`, extract named groups into `vars` |
| 252-267 | Match result building | Build `MatchResult` with trigger string + captured vars |

---

## util.rs — Test Helper

| Lines | Item | Description |
|-------|------|-------------|
| 1-49 | `pub fn get_matches_after_str()` | Feeds a string char-by-char to any Matcher, returns matches. Test utility. |

---

## Cross-Reference: How Matchers Connect to Engine

```
espanso-config
  └── MatchGroup { matches: Vec<Match> }
        └── Each Match has: trigger string, case_insensitive, left/right_word

espanso-match (this crate)
  ├── RollingMatch::from_string(id, trigger, options)
  │     └── RollingMatcher::new(&matches, options)
  │           └── MatcherTreeNode::from_matches() — builds trie
  │                 └── process(event) — incremental matching
  │
  └── RegexMatch::new(id, regex)
        └── RegexMatcher::new(&matches, options)
              └── process(event) — buffer-based matching

espanso-engine (consumer)
  └── MatcherMiddleware
        ├── Uses RollingMatcher for standard triggers
        └── Uses RegexMatcher for regex triggers
```

---

## Key Variables — Cross-Reference

| Variable | Defined | Used In |
|----------|---------|---------|
| `RollingMatcher.root` | matcher.rs:18 | process(), find_refs() |
| `RollingMatcherState.paths` | matcher.rs:43 | process_inner(), new path creation |
| `RollingMatcherStatePath.node` | matcher.rs:58 | find_refs() trie traversal |
| `RollingMatcherStatePath.events` | matcher.rs:59 | extract_string_from_events() |
| `RegexMatcher.buffer` | mod.rs:89 | process() accumulation |
| `RegexMatcher.regex_set` | mod.rs:38 | is_match() screening |
| `MatcherTreeNode.chars` | tree.rs:20 | find_refs() char matching |
| `MatcherTreeNode.keys` | tree.rs:19 | find_refs() key matching |
| `MatcherTreeNode.word_separators` | tree.rs:18 | find_refs() word boundary |

---

## Grep Patterns for Future Searches

```bash
# All Matcher implementations
grep -rn "impl Matcher for" espanso-match/src/

# All MatchResult construction
grep -rn "MatchResult" espanso-match/src/

# Trie node operations
grep -rn "MatcherTreeNode" espanso-match/src/

# RollingItem usage
grep -rn "RollingItem" espanso-match/src/

# RegexSet usage
grep -rn "RegexSet" espanso-match/src/

# Word separator handling
grep -rn "word_separator\|WordSeparator" espanso-match/src/

# Case insensitive matching
grep -rn "UniCase\|case_insensitive" espanso-match/src/
```

---

**Generated from:** espanso-match crate analysis
**Core files:** lib.rs (56 lines), rolling/matcher.rs (352 lines), rolling/tree.rs (353 lines), regex/mod.rs (267 lines)
**Total:** 8 files, 1,553 lines

## Related Pages

- [[04-espanso-match/SUMMARY]]
- [[07-espanso-engine/MAP]] — MatcherMiddleware uses this crate
- [[01-CORE/CRATE_DEPENDENCIES]]
