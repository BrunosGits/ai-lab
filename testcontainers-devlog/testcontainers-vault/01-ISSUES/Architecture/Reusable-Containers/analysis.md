# Analysis: Reusable Containers

## Problem Statement
How do testcontainers implementations support reusing containers across test runs to improve test execution speed?

## Root Cause Analysis
Reusable containers allow containers to persist across test runs, avoiding the overhead of container startup/teardown. Each implementation has a different approach:
- **Java**: `withReuse(true)` with explicit configuration
- **Rust**: `ReuseDirective` enum with session-based reuse
- **Python**: `reuse=True` parameter

---

## Implementation Approach

### Java: withReuse(true)

**File:** `core/src/main/java/org/testcontainers/containers/GenericContainer.java`

```java
public SELF withReuse(boolean reuse) {
    this.reuse = reuse;
    return self;
}

// In start():
if (reuse) {
    // Check for existing reusable container
    // Reuse if compatible, otherwise create new
}
```

**Key Points:**
- `withReuse(true)` enables reuse
- Containers persist across test runs
- Compatibility check based on configuration hash
- Requires explicit cleanup or JVM shutdown

---

### Rust: ReuseDirective

**File:** `testcontainers/src/core/image.rs` + `testcontainers/src/core/containers/request.rs`

```rust
pub enum ReuseDirective {
    /// Never reuse containers
    Never,
    /// Reuse within current test session
    CurrentSession,
    /// Reuse across sessions (persistent)
    Always,
}

impl ContainerRequest {
    pub fn with_reuse(mut self, directive: ReuseDirective) -> Self {
        self.reuse = directive;
        self
    }
}
```

**Key Points:**
- `ReuseDirective` enum with three variants
- `CurrentSession` reuses within test session
- `Always` persists across sessions
- Session tracked via `session_id()`

---

### Python: reuse=True

**File:** `src/testcontainers/core/container.py`

```python
class Container:
    def __init__(self, image: str = "alpine:latest", reuse: bool = False, **kwargs):
        self.reuse = reuse
        # ...
    
    def start(self) -> "Container":
        if self.reuse:
            # Check for existing container with same config
            existing = self._find_reusable_container()
            if existing:
                self._container_id = existing
                return self
        # ... normal start
```

---

## Cross-Language Comparison

| Feature | Java | Rust | Python |
|--------|------|------|--------|
| **Enable** | `withReuse(true)` | `with_reuse(ReuseDirective::CurrentSession)` | `reuse=True` |
| **Granularity** | Boolean | Enum (Never/Session/Always) | Boolean |
| **Session Tracking** | JVM lifecycle | `session_id()` | Process lifetime |
| **Configuration Hash** | Auto-computed | Auto-computed | Auto-computed |
| **Cleanup** | JVM shutdown | Session end | Process exit |

---

## Code References

| Repo | File | Class/Function |
|------|------|----------------|
| Java | core/.../GenericContainer.java | `withReuse()`, `start()` |
| Rust | core/image.rs + core/containers/request.rs | `ReuseDirective`, `with_reuse()` |
| Python | core/container.py | `Container.__init__`, `start()` |

---

## Key Differences

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **API Style** | Boolean flag | Enum directive | Boolean param |
| **Granularity** | All-or-nothing | Three levels | Boolean |
| **Session Scope** | JVM lifetime | Explicit session | Process lifetime |
| **Config Matching** | Hash-based | Hash-based | Hash-based |

---

## Key Takeaways

| Aspect | Recommendation |
|--------|----------------|
| **Java** | Use for integration test suites |
| **Rust** | Use `CurrentSession` for test suites |
| **Python** | Use `reuse=True` for pytest fixtures |