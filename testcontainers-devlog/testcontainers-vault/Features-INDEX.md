# Features Index — Cross-Language Comparison

> Side-by-side comparison of core features across Java, Rust, and Python implementations.

---

## 1. Container Lifecycle

| Feature | Java | Rust | Python |
|---------|------|------|--------|
| **Entry Point** | `GenericContainer.start()` | `ContainerAsync.start()` / `Container.start()` | `Container.start()` |
| **Create Container** | `dockerClient.createContainer()` | `Docker::create_container()` (bollard) | `DockerClient.create_container()` |
| **Start Container** | `dockerClient.startContainer()` | `Docker::start_container()` | `DockerClient.start()` |
| **Stop Container** | `dockerClient.stopContainer()` | `Docker::stop_container()` | `DockerClient.stop()` |
| **Remove Container** | `dockerClient.removeContainer()` | `Docker::remove_container()` | `DockerClient.remove_container()` |
| **Wait Strategy** | `WaitStrategy.waitUntilReady()` | `WaitFor::wait_until_ready()` | `WaitStrategy.wait_until_ready()` |
| **Cleanup Registration** | `ResourceReaper.register()` | Ryuk auto-register | `Ryuk.register()` |

**Key Methods:**
- Java: `GenericContainer.start()` → `tryStart()` → `configure()` → `createContainer()` → `startContainer()` → `waitStrategy.waitUntilReady()`
- Rust: `GenericImage.start()` → `ContainerRequest::from()` → `AsyncRunner.start()` → `create_container()` → `start_container()` → `WaitFor::wait_until_ready()`
- Python: `Container.start()` → `DockerClient.create_container()` → `start()` → `WaitStrategy.wait_until_ready()`

---

## 2. Wait Strategies

| Strategy | Java | Rust | Python |
|----------|------|------|--------|
| **Log Message** | `LogMessageWaitStrategy` | `WaitFor::message_on_stdout()` | `LogMessageWaitStrategy` |
| **Port Listening** | `PortWaitStrategy` | `WaitFor::port()` | `PortWaitStrategy` |
| **HTTP Endpoint** | `HttpWaitStrategy` | `WaitFor::http()` | `HttpWaitStrategy` |
| **Custom Predicate** | Custom `WaitStrategy` | `WaitFor::custom(fn)` | Custom callable |
| **Duration** | `TimeoutWaitStrategy` | `WaitFor::duration()` | Custom |
| **Exit Code** | `ExitCodeWaitStrategy` | `WaitFor::exit_code()` | Custom |

**Interface/Trait:**
- Java: `WaitStrategy` interface with `waitUntilReady()`
- Rust: `WaitFor` enum with `wait_until_ready()` method
- Python: `WaitStrategy` base class with `wait_until_ready()` method

---

## 3. Networking & Port Mapping

| Feature | Java | Rust | Python |
|---------|------|------|--------|
| **Port Binding** | `withExposedPorts()`, `getMappedPort()` | `with_port()`, `get_host_port()` | `with_bind_ports()`, `get_exposed_port()` |
| **Network Creation** | `Network.newNetwork()` | `Network::new()` | `Network.create()` |
| **Network Attachment** | `withNetwork()` | `with_network()` | `with_network()` |
| **Host Access** | `getHost()` | `get_host()` | `get_container_host_ip()` |
| **Port Protocol** | `InternetProtocol.TCP/UDP` | `Tcp/Udp` enum | `Protocol.TCP/UDP` |

---

## 5. File & Volume Management

| Feature | Java | Rust | Python |
|---------|------|------|--------|
| **Bind Mounts** | `withFileSystemBind()`, `BindMode` | `Mount::bind()` | `Volume.bind()` |
| **Tmpfs** | `withTmpFs()` | `Mount::tmpfs()` | `Volume.tmpfs()` |
| **Copy to Container** | `copyFileToContainer()`, `copyToContainer()` | `copy_to_container()` | `copy_to_container()` |
| **Copy from Container** | `copyFileFromContainer()` | `copy_from_container()` | `copy_from_container()` |

---

## 6. Exec / Commands in Containers

| Feature | Java | Rust | Python |
|---------|------|------|--------|
| **Execute Command** | `ExecInContainerPattern.exec()` | `ContainerAsync::exec()` | `Container.exec()` |
| **Wait for Output** | `WaitFor::message_on_stdout()` | `WaitFor::message_on_stdout()` | `LogMessageWaitStrategy` |
| **Exit Code** | `WaitFor::exit_code()` | `WaitFor::exit_code()` | Custom |
| **Environment Variables** | `withEnv()` | `with_env_var()` | `with_env()` |

---

## 6. Logging

| Feature | Java | Rust | Python |
|---------|------|------|--------|
| **Log Consumer** | `LogConsumer` interface | `LogConsumer` trait | `log_consumers` list |
| **SLF4J Integration** | `Slf4jLogConsumer` | `tracing` crate integration | Standard `logging` module |
| **Follow Logs** | `LogConsumer.accept()` | `LogConsumer::accept()` | `log_consumers` callbacks |
| **Stdout/Stderr** | Separate consumers | Separate streams | Combined by default |

---

## 6. Resource Reaper (Ryuk)

| Feature | Java | Rust | Python |
|---------|------|------|--------|
| **Implementation** | `ResourceReaper` class | `ryuk` crate integration | `ryuk` integration |
| **Container Registration** | `ResourceReaper.register()` | Automatic via runner | `Ryuk.register()` |
| **Ryuk Image** | `testcontainers/ryuk:0.8.1` | `testcontainers/ryuk:0.8.1` | `testcontainers/ryuk:0.8.1` |
| **Disable Option** | `TESTCONTAINERS_RYUK_DISABLED` | `TESTCONTAINERS_RYUK_DISABLED` | `TESTCONTAINERS_RYUK_DISABLED` |
| **Custom Image** | `RYUK_CONTAINER_IMAGE` | `RYUK_CONTAINER_IMAGE` | `RYUK_CONTAINER_IMAGE` |

---

## 6. Reusable Containers

| Feature | Java | Rust | Python |
|---------|------|------|--------|
| **Enable Reuse** | `withReuse(true)` | `ReuseDirective::CurrentSession` | `reuse=True` |
| **Session ID** | Auto-generated | `ReuseDirective::CurrentSession` | Auto-generated |
| **Cleanup** | Manual or JVM shutdown | Drop impl / session end | Session end |

---

## 6. Test Framework Integration

| Feature | Java | Rust | Python |
|---------|------|------|--------|
| **JUnit 4** | `@Rule` / `@ClassRule` | N/A | N/A |
| **JUnit 5** | `@Container` / `@Testcontainers` | N/A | N/A |
| **Spock** | `@Shared` + `@AutoCleanup` | N/A | N/A |
| **pytest** | N/A | N/A | `pytest` fixtures |
| **tokio::test** | N/A | `#[tokio::test]` | N/A |

---

## Summary: Key Differences

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Sync/Async** | Sync only | Both (async + blocking) | Sync (async via asyncio) |
| **Wait Strategy** | Interface + implementations | Enum with variants | Class hierarchy |
| **Logging** | SLF4J 1.7 (no lambdas) | `tracing` / `log` crate | Standard `logging` module |
| **Async Support** | None (blocking only) | Native async/await | `asyncio` (optional) |
| **Resource Cleanup** | ResourceReaper + Ryuk | Ryuk + Drop impl | Ryuk + context managers |
| **Generics** | `GenericContainer<SELF>` | Generic `ContainerAsync` | Type hints + generics |