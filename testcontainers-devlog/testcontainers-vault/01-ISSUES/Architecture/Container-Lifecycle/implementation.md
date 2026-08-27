# Implementation: Container Lifecycle

## Java Implementation

### GenericContainer.start()
```java
// core/src/main/java/org/testcontainers/containers/GenericContainer.java:320
public SELF start() {
    if (this.started) {
        return self();
    }
    tryStart();
    this.started = true;
    return self();
}
```

### GenericContainer.tryStart()
```java
// core/src/main/java/org/testcontainers/containers/GenericContainer.java:360
private void tryStart() {
    if (this.waitStrategy != DEFAULT_WAIT_STRATEGY) {
        this.containerDef.setWaitStrategy(this.waitStrategy);
    }
    configure();
    
    if (logger().isDebugEnabled()) {
        logger().debug("Starting container: {}", getDockerImageName());
    }
    
    AtomicInteger attempt = new AtomicInteger(0);
    Unreliables.retryUntilSuccess(
        startupAttempts,
        () -> {
            if (logger().isDebugEnabled()) {
                logger().debug(
                    "Trying to start container: {} (attempt {}/{})",
                    getDockerImageName(),
                    attempt.incrementAndGet(),
                    startupAttempts
                );
            }
            tryStart();
            return true;
        }
    );
}
```

### GenericContainer.tryStart() (actual container creation)
```java
private void tryStart() {
    try {
        String dockerImageName = getDockerImageName();
        if (logger().isDebugEnabled()) {
            logger().debug("Starting container: {}", dockerImageName);
        }
        
        Instant startedAt = Instant.now();
        logger().info("Creating container for image: {}", dockerImageName);
        CreateContainerCmd createCommand = dockerClient.createContainerCmd(dockerImageName);
        applyConfiguration(createCommand);
        
        createCommand.getLabels().putAll(DockerClientFactory.DEFAULT_LABELS);
        
        boolean reused = false;
        // ... reuse logic ...
        
        String containerId = createCommand.exec().getId();
        this.containerId = containerId;
        
        dockerClient.startContainerCmd(containerId).exec();
        
        // Wait strategy
        waitStrategy.waitUntilReady();
        
        // Register with reaper
        resourceReaper.register(this);
        
    } catch (Exception e) {
        throw new ContainerLaunchException("Container startup failed for image " + getDockerImageName(), e);
    }
}
```

---

## Rust Implementation

### GenericImage::start()
```rust
// testcontainers/src/images/image.rs
pub fn start(self) -> ContainerAsync {
    let request = ContainerRequest::from(self);
    AsyncRunner::start(request)
}
```

### AsyncRunner::start()
```rust
// testcontainers/src/runners/async_runner.rs
pub async fn start(request: ContainerRequest) -> Result<ContainerAsync, TestcontainersError> {
    let id = Self::create_container(&request).await?;
    
    let mut container = ContainerAsync {
        id,
        docker: request.docker.clone(),
        // ... other fields
    };
    
    container.start().await?;
    
    // Wait strategy
    let ready_conditions = container.ready_conditions();
    container.block_until_ready(ready_conditions).await?;
    
    // Register with Ryuk
    if let Some(ryuk) = &container.ryuk {
        ryuk.register(&container.id).await?;
    }
    
    Ok(container)
}
```

### ContainerAsync::start()
```rust
// testcontainers/src/core/containers/async_container.rs
pub async fn start(&mut self) -> Result<(), TestcontainersError> {
    let create_cmd = self.build_create_command();
    let container = self.docker.create_container(create_cmd).await?;
    self.id = container.id.clone();
    
    self.docker.start_container(&self.id).await?;
    
    Ok(())
}
```

---

## Python Implementation

### Container.start()
```python
# src/testcontainers/core/container.py
def start(self) -> "Container":
    if self._container_id is not None:
        return self
    
    self._docker_client = get_docker_client()
    
    # Create container
    self._container_id = self._docker_client.create_container(
        image=self.image,
        command=self.command,
        environment=self.environment,
        ports=self.ports,
        volumes=self.volumes,
        # ... other config
    )
    
    # Start container
    self._docker_client.start(self._container_id)
    
    # Wait strategy
    self._wait_strategy.wait_until_ready(self)
    
    # Register with Ryuk
    if not self.testcontainers_config.ryuk_disabled:
        ryuk = get_ryuk()
        ryuk.register(self._container_id)
    
    return self
```

---

## Key Differences Summary

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Method Chain** | start() → tryStart() → configure() → create → start | start() → create_container() → start() → wait | start() → create_container() → start() |
| **Configuration** | configure() method | ContainerRequest builder | with_* methods |
| **Wait Integration** | waitStrategy.waitUntilReady() | WaitFor::wait_until_ready() | WaitStrategy.wait_until_ready() |
| **Cleanup** | ResourceReaper.register() | Ryuk registration | Ryuk registration |