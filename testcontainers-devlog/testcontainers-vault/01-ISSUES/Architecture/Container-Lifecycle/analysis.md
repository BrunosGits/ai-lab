# Analysis: Container Lifecycle

## Problem Statement
How do testcontainers create, start, manage, and clean up Docker containers across Java, Rust, and Python implementations?

## Root Cause Analysis
All three implementations wrap Docker Engine API but with different architectural patterns:
- **Java**: Synchronous, single-threaded, uses docker-java library
- **Rust**: Async-first with tokio, bollard for Docker API, both async/blocking APIs
- **Python**: Synchronous wrapper around docker-py, supports asyncio via asyncio.to_thread

## Implementation Approach

### Java: GenericContainer.start()
**File:** `core/src/main/java/org/testcontainers/containers/GenericContainer.java`
**Key Methods:**
- `start()` (line 320) → calls `tryStart()`
- `tryStart()` (line 360) → resolves image, configures, creates container
- `configure()` (line 430) → ports, env, mounts, labels
- `dockerClient.createContainer()` → `dockerClient.startContainer()`
- `waitStrategy.waitUntilReady()` → readiness polling
- `ResourceReaper.register()` → cleanup registration

**Key Lines:** 320-380 (start/tryStart), 360-420 (tryStart), 430-550 (configure)

### Rust: GenericImage::start() → AsyncRunner::start()
**File:** `testcontainers/src/images/image.rs` (GenericImage), `testcontainers/src/runners/async_runner.rs`
**Key Methods:**
- `GenericImage::start()` (line 150) → `ContainerRequest::from()` → `AsyncRunner::start()`
- `AsyncRunner::start()` → `create_container()` → `start_container()` → `WaitFor::wait_until_ready()`
- `ContainerAsync::start()` → creates container, applies wait strategy

**Key Files:** `images/image.rs`, `runners/async_runner.rs`, `core/containers/async_container.rs`

### Python: Container.start()
**File:** `src/testcontainers/core/container.py`
**Key Methods:**
- `Container.start()` (line ~150) → `DockerClient.create_container()` → `start()` → `WaitStrategy.wait_until_ready()`
- `DockerClient.create_container()` → wraps docker-py `create_container()`
- `DockerClient.start()` → wraps docker-py `start()`

**Key Files:** `core/container.py`, `core/docker_client.py`, `core/wait_strategy.py`

---

## Code References

| Repo | File | Class/Function | Lines | Commit |
|------|------|----------------|-------|--------|
| testcontainers-java | core/.../GenericContainer.java | GenericContainer.start() | 320-380 | main |
| testcontainers-java | core/.../GenericContainer.java | GenericContainer.tryStart() | 360-420 | main |
| testcontainers-java | core/.../GenericContainer.java | GenericContainer.configure() | 430-550 | main |
| testcontainers-rs | images/image.rs | GenericImage.start() | 150-180 | main |
| testcontainers-rs | runners/async_runner.rs | AsyncRunner.start() | 50-120 | main |
| testcontainers-rs | runners/async_runner.rs | AsyncRunner.create_container() | 200-300 | main |
| testcontainers-python | core/container.py | Container.start() | 150-250 | main |
| testcontainers-python | core/docker_client.py | DockerClient.create_container() | 50-120 | main |
| testcontainers-python | core/wait_strategy.py | WaitStrategy.wait_until_ready() | various | main |

---

## Tests

| Repo | Test Command | Key Tests |
|------|--------------|-----------|
| Java | `./gradlew :testcontainers:test --tests '*GenericContainer*'` | GenericContainerRuleTest, GenericContainerTest |
| Rust | `cargo test --features blocking --lib` | runners::async_runner::tests, runners::sync_runner::tests |
| Python | `make core/tests` | test_container_lifecycle, test_generic_container |

---

## Cross-Language Comparison

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Sync/Async** | Sync only | Async + Blocking | Sync (asyncio optional) |
| **Entry Point** | `GenericContainer.start()` | `GenericImage.start()` | `Container.start()` |
| **Container Config** | `configure()` method | `ContainerRequest` builder | `Container.__init__` + `with_*` methods |
| **Docker Client** | docker-java (singleton) | bollard (async) | docker-py (sync) |
| **Wait Strategy** | `WaitStrategy` interface | `WaitFor` enum | `WaitStrategy` class |
| **Cleanup** | ResourceReaper + Ryuk | Ryuk + Drop impl | Ryuk + `__exit__` |
| **Error Handling** | Checked exceptions | `Result<T, E>` | Exceptions |
| **Generics** | `GenericContainer<SELF extends GenericContainer<SELF>>` | Generic `ContainerAsync` | Type hints |

---

## Key Differences

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Concurrency** | Blocking only | Native async/await | Blocking (asyncio optional) |
| **Type Safety** | Generics + checked exceptions | Ownership + Result<T,E> | Type hints + exceptions |
| **Wait Strategy** | 8+ implementations | 7 enum variants | 4 base classes |
| **Configuration** | Fluent builder pattern | Builder pattern | Fluent builder |
| **Test Framework** | JUnit 4/5, Spock | tokio::test | pytest |
| **Release** | Manual Gradle | Manual Cargo | Automated release-please |