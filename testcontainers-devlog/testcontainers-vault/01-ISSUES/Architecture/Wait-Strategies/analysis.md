# Analysis: Wait Strategies

## Problem Statement
How do testcontainers implementations handle container readiness detection across different wait strategies (log messages, port listening, HTTP endpoints, etc.)?

## Root Cause Analysis
Each implementation provides a different abstraction for wait strategies:
- **Java**: Interface-based with 8+ implementations
- **Rust**: Enum-based with 7 variants
- **Python**: Class hierarchy with 4 base implementations

All three delegate to Docker API for checking container state (logs, ports, HTTP endpoints).

---

## Implementation Approach

### Java: WaitStrategy Interface

**File:** `core/src/main/java/org/testcontainers/containers/WaitStrategy.java`

```java
public interface WaitStrategy {
    void waitUntilReady();
    default void withStartupTimeout(Duration startupTimeout) { ... }
}
```

**Implementations (8+):**

| Strategy | Class | Key Method | Description |
|----------|-------|------------|-------------|
| Log Message | `LogMessageWaitStrategy` | `waitUntilReady()` | Wait for stdout/stderr message |
| Port Listening | `PortWaitStrategy` | `waitUntilReady()` | Wait for TCP port |
| HTTP Endpoint | `HttpWaitStrategy` | `waitUntilReady()` | Wait for HTTP 200 |
| Host Port | `HostPortWaitStrategy` | `waitUntilReady()` | Wait for host port mapping |
| Timeout | `TimeoutWaitStrategy` | `waitUntilReady()` | Fixed duration |
| Exit Code | `ExitCodeWaitStrategy` | `waitUntilReady()` | Wait for exit code |
| Composite | `CompositeWaitStrategy` | `waitUntilReady()` | Multiple strategies (AND/OR) |
| One-Shot | `OneShotWaitStrategy` | `waitUntilReady()` | Single check |

**Implementation Pattern (LogMessageWaitStrategy):**
```java
public class LogMessageWaitStrategy implements WaitStrategy {
    private final String message;
    
    @Override
    public void waitUntilReady() {
        // Poll container logs until message appears
        while (!Thread.currentThread().isInterrupted()) {
            String logs = container.getLogs();
            if (logs.contains(message)) {
                return;
            }
            Thread.sleep(pollInterval);
        }
    }
}
```

---

### Rust: WaitFor Enum

**File:** `testcontainers/src/core/wait.rs`

```rust
pub enum WaitFor {
    /// Wait for a message on stdout
    StdoutMessage { message: String },
    /// Wait for a message on stderr
    StderrMessage { message: String },
    /// Wait for a port to be listening
    Port { port: u16 },
    /// Wait for HTTP endpoint
    Http { path: String },
    /// Custom async predicate
    Custom { f: Box<dyn Fn() -> bool + Send + Sync> },
    /// Wait for duration
    Duration { duration: Duration },
    /// Wait for exit code
    ExitCode { code: i32 },
}

impl WaitFor {
    pub async fn wait_until_ready(&self, container: &ContainerAsync) -> Result<(), TestcontainersError> {
        match self {
            WaitFor::StdoutMessage { message } => {
                // Poll stdout logs
            }
            WaitFor::Port { port } => {
                // Poll port
            }
            // ... other variants
        }
    }
}
```

**Variants (7):**
| Variant | Description |
|---------|-------------|
| `StdoutMessage` | Wait for message on stdout |
| `StderrMessage` | Wait for message on stderr |
| `Port` | Wait for TCP port |
| `Http` | Wait for HTTP 200 |
| `Custom` | Custom async predicate |
| `Duration` | Fixed wait time |
| `ExitCode` | Wait for exit code |

---

### Python: WaitStrategy Class Hierarchy

**File:** `src/testcontainers/core/wait_strategy.py`

```python
class WaitStrategy(ABC):
    @abstractmethod
    def wait_until_ready(self, container: "Container") -> None:
        """Wait until container is ready."""
        pass

class LogMessageWaitStrategy(WaitStrategy):
    def __init__(self, message: str, stream: str = "stdout"):
        self.message = message
        self.stream = stream
    
    def wait_until_ready(self, container: "Container") -> None:
        # Poll container logs until message appears
        pass

class PortWaitStrategy(WaitStrategy):
    def __init__(self, port: int):
        self.port = port
    
    def wait_until_ready(self, container: "Container") -> None:
        # Poll port connectivity
        pass

class HttpWaitStrategy(WaitStrategy):
    def __init__(self, path: str = "/", port: int = 80):
        self.path = path
        self.port = port
    
    def wait_until_ready(self, container: "Container") -> None:
        # Poll HTTP endpoint
        pass

class CustomWaitStrategy(WaitStrategy):
    def __init__(self, predicate: Callable[["Container"], bool]):
        self.predicate = predicate
    
    def wait_until_ready(self, container: "Container") -> None:
        while not self.predicate(container):
            time.sleep(0.1)
```

**Implementations (4 base + custom):**
| Strategy | Class | Description |
|----------|-------|-------------|
| Log Message | `LogMessageWaitStrategy` | Wait for stdout/stderr message |
| Port Listening | `PortWaitStrategy` | Wait for TCP port |
| HTTP Endpoint | `HttpWaitStrategy` | Wait for HTTP 200 |
| Custom | `CustomWaitStrategy` | Custom predicate |

---

## Code References

| Repo | File | Class/Function | Lines |
|------|------|----------------|-------|
| testcontainers-java | core/.../WaitStrategy.java | WaitStrategy interface | 1-50 |
| testcontainers-java | core/.../LogMessageWaitStrategy.java | LogMessageWaitStrategy | 1-80 |
| testcontainers-java | core/.../PortWaitStrategy.java | PortWaitStrategy | 1-100 |
| testcontainers-java | core/.../HttpWaitStrategy.java | HttpWaitStrategy | 1-150 |
| testcontainers-rs | core/wait.rs | WaitFor enum | 1-200 |
| testcontainers-python | core/wait_strategy.py | WaitStrategy class | 1-200 |

---

## Tests

| Repo | Test Command | Key Tests |
|------|--------------|-----------|
| Java | `./gradlew :testcontainers:test --tests '*WaitStrategy*'` | LogMessageWaitStrategyTest, PortWaitStrategyTest |
| Rust | `cargo test --features blocking --lib wait` | wait strategy tests |
| Python | `make core/tests` | wait strategy tests |

---

## Cross-Language Comparison

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Abstraction** | Interface | Enum | Abstract Base Class |
| **Implementations** | 8+ | 7 variants | 4 base + custom |
| **Extensibility** | New class | New variant | Subclass |
| **Composite** | CompositeWaitStrategy | Manual combination | Custom |
| **Timeout** | Built-in | Duration variant | Custom |
| **Exit Code** | ExitCodeWaitStrategy | ExitCode variant | Custom |

---

## Key Differences

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Extensibility** | New class implementation | New enum variant (breaking) | Subclass WaitStrategy |
| **Composite** | Built-in CompositeWaitStrategy | Manual combination | CustomWaitStrategy |
| **Async Support** | Sync only | Native async | Sync (asyncio optional) |
| **Timeout Handling** | Per-strategy startupTimeout | Duration variant | Custom |
| **Composite Logic** | AND/OR via CompositeWaitStrategy | Manual | Manual |