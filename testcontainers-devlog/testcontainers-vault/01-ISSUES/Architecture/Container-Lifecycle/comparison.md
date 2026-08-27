# Comparison: Container Lifecycle

## Cross-Language Comparison

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Sync/Async** | Sync only | Async + Blocking | Sync (asyncio optional) |
| **Entry Point** | `GenericContainer.start()` | `GenericImage.start()` / `ContainerAsync.start()` | `Container.start()` |
| **Configuration** | `configure()` method | `ContainerRequest` builder | Fluent `with_*` methods |
| **Docker Client** | docker-java (singleton) | bollard (async) | docker-py (sync) |
| **Wait Strategy** | `WaitStrategy` interface | `WaitFor` enum | `WaitStrategy` class |
| **Cleanup** | `ResourceReaper` + Ryuk | Ryuk + Drop impl | Ryuk + `__exit__` |
| **Error Handling** | Checked exceptions | `Result<T, E>` | Exceptions |

## Detailed Comparison

### Container Creation Flow

| Step | Java | Rust | Python |
|------|------|------|--------|
| 1. Config | `configure()` | `ContainerRequest` builder | `Container.__init__` + `with_*` |
| 2. Create | `dockerClient.createContainer()` | `docker.create_container()` | `docker_client.create_container()` |
| 3. Start | `dockerClient.startContainer()` | `docker.start_container()` | `docker_client.start()` |
| 4. Wait | `waitStrategy.waitUntilReady()` | `WaitFor::wait_until_ready()` | `WaitStrategy.wait_until_ready()` |
| 5. Register | `ResourceReaper.register()` | Ryuk auto-register | `ryuk.register()` |

### Configuration Patterns

| Pattern | Java | Rust | Python |
|---------|------|------|--------|
| **Style** | Fluent builder | Builder pattern | Fluent builder |
| **Type Safety** | Generics + checked exceptions | Ownership + Result<T,E> | Type hints + exceptions |
| **Required Config** | Image name | Image name | Image name |
| **Optional Config** | Ports, env, volumes, cmd, etc. | Same | Same |

### Wait Strategy Integration

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Interface** | `WaitStrategy` | `WaitFor` enum | `WaitStrategy` class |
| **Injection** | `withWaitStrategy()` | `with_wait_for()` | `with_wait_strategy()` |
| **Execution** | `waitStrategy.waitUntilReady()` | `WaitFor::wait_until_ready()` | `wait_strategy.wait_until_ready()` |

### Cleanup & Resource Management

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Reaper** | `ResourceReaper` (singleton) | Ryuk (external) | Ryuk (external) |
| **Registration** | `ResourceReaper.register()` | Auto via runner | `ryuk.register()` |
| **Cleanup Trigger** | JVM shutdown | Process exit / Drop | Context manager / `__exit__` |
| **Ryuk Image** | `testcontainers/ryuk:0.8.1` | Same | Same |

## Code Structure Comparison

### Java: Inheritance-based
```java
public class GenericContainer<SELF extends GenericContainer<SELF>> implements Container<SELF> {
    // Fluent builder with SELF type
    public SELF withEnv(String key, String value) { ... }
    public SELF withExposedPorts(int... ports) { ... }
}
```

### Rust: Composition + Traits
```rust
pub struct GenericImage {
    name: String,
    tag: String,
    wait_for: Option<WaitFor>,
    env_vars: HashMap<String, String>,
}

impl Image for GenericImage {
    fn name(&self) -> &str { &self.name }
    fn tag(&self) -> &str { &self.tag }
    fn env_vars(&self) -> Vec<(String, String)> { ... }
}
```

### Python: Composition + Type Hints
```python
class Container:
    def __init__(self, image: str = "alpine:latest", **kwargs):
        self.image = image
        self.environment: Dict[str, str] = {}
        
    def with_env(self, key: str, value: str) -> "Container":
        self.environment[key] = value
        return self
```

## Key Takeaways

| Aspect | Winner | Reason |
|--------|--------|--------|
| **Type Safety** | Rust | Ownership model + Result<T,E> |
| **Async Support** | Rust | Native async/await |
| **Ecosystem** | Java | Mature, 60+ modules |
| **Simplicity** | Python | Less boilerplate |
| **Test Integration** | Java | JUnit 4/5 + Spock |
| **Release Automation** | Python | release-please |
| **Documentation** | Java | MkDocs + codeinclude |