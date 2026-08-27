# Analysis: Networking

## Problem Statement
How do testcontainers implementations handle container networking, port mapping, and inter-container communication?

## Root Cause Analysis
All three implementations wrap Docker's networking APIs but with different abstractions:
- **Java**: Network class with builder pattern
- **Rust**: Network struct with builder methods
- **Python**: Network class with context manager

All delegate to Docker's network API (create, connect, disconnect).

---

## Implementation Approach

### Java: Network Class

**File:** `core/src/main/java/org/testcontainers/containers/Network.java`

```java
public class Network implements Closeable {
    private final String networkId;
    private final DockerClient dockerClient;
    
    public static Network newNetwork() {
        // Creates new bridge network
    }
    
    public static Network.SHARED newNetwork() {
        // Creates shared network
    }
}
```

**Key Methods:**
- `newNetwork()` — creates new bridge network
- `getId()` — returns network ID
- `close()` — removes network
- `getAlias()` — gets container alias in network

### Rust: Network Struct

**File:** `testcontainers/src/core/network.rs`

```rust
pub struct Network {
    id: String,
    docker: Arc<Docker>,
}

impl Network {
    pub async fn new(docker: &Docker) -> Result<Self, TestcontainersError> {
        // Creates new bridge network via bollard
    }
    
    pub async fn connect(&self, container: &ContainerAsync) -> Result<()> {
        // Connect container to network
    }
}
```

---

## Cross-Language Comparison

| Feature | Java | Rust | Python |
|---------|------|------|--------|
| **Network Creation** | `Network.newNetwork()` | `Network::new()` | `Network.create()` |
| **Network ID** | `getId()` | `id()` | `id` property |
| **Connect Container** | `container.withNetwork()` | `Network::connect()` | `container.with_network()` |
| **Aliases** | `getAlias()` | Not directly exposed | `network.aliases` |
| **Cleanup** | `Closeable` interface | Drop impl | Context manager |

---

## Code References

| Repo | File | Class/Function |
|------|------|----------------|
| Java | core/.../Network.java | Network class |
| Rust | core/network.rs | Network struct |
| Python | core/network.py | Network class |

---

## Key Differences

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Ownership** | Manual close() | Drop impl | Context manager |
| **Async** | Sync only | Async | Sync |
| **Aliases** | Explicit | Implicit | Explicit |
| **Default Network** | Bridge | Bridge | Bridge |