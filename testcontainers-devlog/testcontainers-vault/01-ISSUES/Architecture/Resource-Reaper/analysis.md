# Analysis: Resource Reaper (Ryuk)

## Problem Statement
How do testcontainers implementations handle automatic cleanup of containers and resources after tests complete?

## Root Cause Analysis
All three implementations rely on **Ryuk** (a sidecar container) for guaranteed cleanup, but with different integration patterns:
- **Java**: Dedicated `ResourceReaper` class manages Ryuk lifecycle
- **Rust**: Direct Ryuk integration via `ryuk` crate
- **Python**: `ryuk` Python package integration

---

## Implementation Approach

### Java: ResourceReaper Class

**File:** `core/src/main/java/org/testcontainers/lifecycle/ResourceReaper.java`

```java
public class ResourceReaper implements Closeable {
    private static final String RYUK_IMAGE = "testcontainers/ryuk:0.8.1";
    private static ResourceReaper instance;
    
    public static ResourceReaper getInstance() { ... }
    
    public void start() {
        // Start Ryuk container
        // Register shutdown hook
    }
    
    public void register(GenericContainer<?> container) {
        // Register container for cleanup
    }
    
    @Override
    public void close() {
        // Stop Ryuk, remove containers
    }
}
```

**Key Features:**
- Singleton pattern for reaper instance
- Starts Ryuk container on first use
- Registers shutdown hook for JVM exit
- Tracks all registered containers

---

### Rust: Ryuk Crate Integration

**File:** `testcontainers/src/core/client.rs` (DockerClient) + `ryuk` crate

```rust
// Ryuk integration via ryuk crate
use ryuk::Ryuk;

pub struct DockerClient {
    ryuk: Option<Ryuk>,
    // ...
}

impl DockerClient {
    pub async fn new() -> Result<Self> {
        let ryuk = Ryuk::new().await?;
        // ...
    }
    
    pub async fn register_for_cleanup(&self, container_id: &str) -> Result<()> {
        self.ryuk.as_ref().unwrap().register(container_id).await
    }
}
```

**Key Points:**
- Uses `ryuk` crate (external dependency)
- Automatic registration via runners
- Cleanup on process exit

---

### Python: ryuk Package Integration

**File:** `src/testcontainers/core/docker_client.py` + `testcontainers/ryuk.py`

```python
# testcontainers/ryuk.py
class Ryuk:
    def __init__(self, docker_client: DockerClient):
        self.docker_client = docker_client
        self.ryuk_container_id = None
    
    def start(self) -> None:
        # Start Ryuk container
        pass
    
    def register(self, container_id: str) -> None:
        # Register container for cleanup
        pass

# Global Ryuk instance
_ryuk_instance = None

def get_ryuk() -> Ryuk:
    global _ryuk_instance
    if _ryuk_instance is None:
        _ryuk_instance = Ryuk(get_docker_client())
        _ryuk_instance.start()
    return _ryuk_instance
```

---

## Cross-Language Comparison

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Implementation** | `ResourceReaper` class | `ryuk` crate | `ryuk` Python package |
| **Lifecycle** | Singleton + shutdown hook | Auto via runners | Global instance + context |
| **Registration** | Explicit `register()` | Auto via runners | Explicit `register()` |
| **Ryuk Image** | `testcontainers/ryuk:0.8.1` | Same | Same |
| **Disable** | `TESTCONTAINERS_RYUK_DISABLED` | Same | Same |
| **Custom Image** | `RYUK_CONTAINER_IMAGE` | Same | Same |

---

## Code References

| Repo | File | Class/Function |
|------|------|----------------|
| Java | core/.../ResourceReaper.java | ResourceReaper class |
| Rust | core/client.rs + ryuk crate | DockerClient + ryuk |
| Python | core/ryuk.py | Ryuk class |

---

## Key Differences

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Ownership** | Explicit singleton | Crate manages | Global instance |
| **Registration** | Explicit `register()` | Implicit | Explicit |
| **Cleanup Trigger** | JVM shutdown hook | Process exit | Context manager exit |
| **Ryuk Management** | Manual start/stop | Auto | Manual start |