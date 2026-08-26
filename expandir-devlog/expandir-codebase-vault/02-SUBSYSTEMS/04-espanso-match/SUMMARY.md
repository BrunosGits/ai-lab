# espanso-match — System Analysis

## 1. What Is This?

The espanso-match crate provides pattern matching algorithms for detecting text triggers. When you type `:hello`, this crate is what recognizes the pattern and fires a match. It's 8 files, 1,553 lines — the smallest core crate, and one of the cleanest.

## 2. Why Does It Exist?

Espanso needs to detect when the user has typed a trigger string (like `:email` or `;btw`). This happens incrementally — each keystroke arrives one at a time, and the matcher must determine in real-time whether a match has been found.

Two matching strategies are needed:
1. **Rolling matcher** — Fast, trie-based, handles standard text triggers
2. **Regex matcher** — Slower, buffer-based, handles complex patterns with capture groups

## 3. How Does It Work?

### The Matcher Trait

Both matchers implement a single trait:

```rust
pub trait Matcher<'a, State, Id> {
    fn process(
        &'a self,
        prev_state: Option<&State>,
        event: Event,
    ) -> (State, Vec<MatchResult<Id>>);
}
```

This is **stateful and incremental**:
- Receives one event at a time
- Takes previous state, returns new state + matches
- State is an associated type (each matcher defines its own)
- Id is generic (caller decides what identifies a match)

### The RollingMatcher Algorithm

The rolling matcher uses a **trie (prefix tree)** for O(1) per-event matching.

**Pattern compilation:**
```
":hello" with left_word=true becomes:
[WordSeparator, Char(":"), Char("h"), Char("e"), Char("l"), Char("l"), Char("o")]
```

**Trie structure:**
```
root
  ':' → Node
          'h' → Node
                  'e' → Node
                          'l' → Node
                                  'l' → Node
                                          'o' → Matches([id])
```

**Runtime matching:**

For each incoming event:
1. **Extend existing paths:** Follow trie edges from current position
2. **Start new path from root:** Every event can begin a new match
3. **Evaluate:** If a leaf is reached → match found, reset state
4. **Accumulate:** If internal node → continue tracking path

The state tracks **multiple active paths** simultaneously (like an NFA):

```rust
struct RollingMatcherState<'a, Id> {
    paths: Vec<RollingMatcherStatePath<'a, Id>>,
}

struct RollingMatcherStatePath<'a, Id> {
    node: &'a MatcherTreeNode<Id>,        // Current trie position
    events: Vec<(Event, IsWordSeparator)>, // Accumulated events
}
```

**Word boundary handling:**

If the current event is a word separator (space, period, comma), the matcher follows the `word_separators` edge in the trie. Critically, if there's no previous state (first event), the matcher treats the current position as implicitly at a word boundary — it explores the root's `word_separators` child recursively. This means `left_word` patterns match even at the start of the buffer.

**Match found:**

When a leaf is reached, `extract_string_from_events()` rebuilds the trigger string from the accumulated event history, identifies left/right separators, and returns the `MatchResult`.

### The RegexMatcher Algorithm

The regex matcher is simpler — it buffers typed text and runs regex matching.

**State:**
```rust
struct RegexMatcherState {
    buffer: String,  // Accumulated typed text
}
```

**For each event:**
1. Append character to buffer
2. Trim if buffer exceeds `max_buffer_size` (default 30)
3. Screen with `RegexSet::is_match()` — fast check
4. If match: extract named captures into `vars`, reset buffer

**Key difference from RollingMatcher:**

| Aspect | RollingMatcher | RegexMatcher |
|--------|---------------|-------------|
| Performance | O(1) per event (trie lookup) | O(buffer_size) per event (regex) |
| Match capture | Only full trigger string | Named capture groups as `vars` |
| Word boundaries | Explicit `WordSeparator` items | Handled by regex syntax |
| State | Trie paths (multiple active) | String buffer |

### Why Two Matchers?

- **RollingMatcher** is used for standard text triggers (`:hello`, `;btw`). It's fast because the trie gives O(1) lookup per event.
- **RegexMatcher** is used for complex patterns with capture groups (e.g., `:email\((?P<name>.*?)\)`). It's slower but more flexible.

The engine's `MatcherMiddleware` uses both, routing each match config to the appropriate matcher based on its type.

## 4. Key Types

### MatchResult<Id>

```rust
pub struct MatchResult<Id> {
    pub id: Id,                          // Match identity
    pub trigger: String,                 // Full typed text
    pub left_separator: Option<String>,  // Word separator to the left
    pub right_separator: Option<String>, // Word separator to the right
    pub vars: HashMap<String, String>,   // Named captures (regex only)
}
```

The `vars` field is only populated by `RegexMatcher` — rolling matches don't produce named captures.

### RollingItem

```rust
pub enum RollingItem {
    WordSeparator,                      // A word boundary
    Key(Key),                           // A specific keyboard key
    Char(String),                       // Case-sensitive character
    CharInsensitive(UniCase<String>),   // Case-insensitive character
}
```

A pattern like `"hello"` with `case_insensitive=true` becomes:
```
[CharInsensitive("h"), CharInsensitive("e"), CharInsensitive("l"), CharInsensitive("l"), CharInsensitive("o")]
```

### MatcherTreeNode<Id>

```rust
pub struct MatcherTreeNode<Id> {
    pub word_separators: Option<MatcherTreeRef<Id>>,
    pub keys: Vec<(Key, MatcherTreeRef<Id>)>,
    pub chars: Vec<(String, MatcherTreeRef<Id>)>,
    pub chars_insensitive: Vec<(UniCase<String>, MatcherTreeRef<Id>)>,
}

pub enum MatcherTreeRef<Id> {
    Matches(Vec<Id>),               // Leaf: these IDs match here
    Node(Box<MatcherTreeNode<Id>>), // Internal: more characters needed
}
```

Multiple patterns that end at the same node accumulate their IDs in the `Matches(Vec<Id>)` vector.

## 5. Edge Cases

### Implicit Word Boundary at Start

If `left_word=true` and the buffer is empty, the matcher still matches. It does this by recursively exploring the root's `word_separators` child when there's no previous state. This is critical — without it, `:hello` wouldn't match at the start of input.

### Modifier Keys

Modifier keys (Ctrl, Alt, Meta, Shift) are skipped during matching. The `is_event_of_interest()` function filters them out, so pressing Ctrl doesn't interfere with pattern matching.

### Backspace Handling

When a backspace is received, the matcher pops the last state from the history. This allows "undoing" typed characters without resetting the entire match state.

### Multiple Active Paths

The rolling matcher tracks multiple paths simultaneously. Typing `"my"` with patterns `"hi"`, `"hey"`, `"my"`, `"myself"` produces:

```
After 'm': path for 'm' → Node
After 'y': path for 'm' → 'y' → Matches([my])
           path for 'm' → 'y' → Node (for "myself")
```

Both paths are tracked until one matches or is invalidated.

### Buffer Overflow (Regex)

The regex matcher trims the buffer when it exceeds `max_buffer_size`. This prevents unbounded memory growth but means very long buffers may lose早期 characters. The default of 30 is generous for most patterns.

## 6. Key Patterns

### Trie-Based Matching

The rolling matcher's trie is compiled once at construction time. Runtime matching is just pointer chasing through the trie — no string comparison needed. This makes it O(1) per event regardless of the number of patterns.

### State Machine

Both matchers are state machines. The state captures the full history needed to continue matching. This makes them:
- **Resumable:** Can pause and continue without losing context
- **Resettable:** Match found → reset to empty state
- **Testable:** Feed events, check state after each

### Generic Id

The `Id` type parameter means the matcher doesn't know or care what identifies a match. The engine passes in integer IDs from config, but the matcher itself is generic.

## 7. Risk Assessment for Changes

| Area | Risk | Why |
|------|------|-----|
| Trie structure (tree.rs) | HIGH | Core data structure, bugs break all matching |
| RollingMatcher process() | HIGH | Complex multi-path tracking |
| Word boundary handling | HIGH | Subtle edge cases, implicit boundaries |
| RegexMatcher buffer | LOW | Simple string accumulation |
| extract_string_from_events | MEDIUM | String reconstruction must be accurate |
| RollingMatch::from_string | LOW | Pattern compilation, straightforward |

## 8. What Was Studied

- **Files:** All 8 files in espanso-match/src/
- **Key Files:** lib.rs, event.rs, rolling/mod.rs, rolling/matcher.rs, rolling/tree.rs, rolling/util.rs, regex/mod.rs, util.rs
- **Patterns:** Trie-based matching, state machines, incremental processing, generic types, word boundary handling
- **Missing:** Nothing — this crate is fully studied
- **Coverage:** 100%

## 9. Evidence

- `espanso-match/src/lib.rs` — MatchResult and Matcher trait (56 lines)
- `espanso-match/src/event.rs` — Event and Key enums (81 lines)
- `espanso-match/src/rolling/mod.rs` — RollingMatch pattern (172 lines)
- `espanso-match/src/rolling/matcher.rs` — RollingMatcher implementation (352 lines)
- `espanso-match/src/rolling/tree.rs` — Trie structure (353 lines)
- `espanso-match/src/rolling/util.rs` — String reconstruction (223 lines)
- `espanso-match/src/regex/mod.rs` — RegexMatcher implementation (267 lines)
- `espanso-match/src/util.rs` — Test helper (49 lines)

## Related Pages

- [[04-espanso-match/MAP]]
- [[07-espanso-engine/MAP]] — MatcherMiddleware uses this crate
- [[05-espanso-config/SUMMARY]] — Config provides match patterns
- [[01-CORE/CRATE_DEPENDENCIES]]
