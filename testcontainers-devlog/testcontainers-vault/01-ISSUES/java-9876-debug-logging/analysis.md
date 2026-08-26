# Issue Analysis: Java #9876 - Debug Logging Lazy Evaluation

## Issue Reference
- **Issue**: #9876
- **Repository**: testcontainers-java
- **Link**: https://github.com/testcontainers/testcontainers-java/issues/9876
- **Type**: Enhancement

## Problem Statement
When using custom ECR images, the `logger().debug()` calls in `GenericContainer.doStart()` and `tryStart()` trigger `getDockerImageName()` which resolves ECR credentials even when debug logging is disabled. This causes a 2-minute timeout (ConditionTimeoutException) because the ECR credentials are not configured.

Stack trace shows:
```
at org.testcontainers.containers.GenericContainer.getDockerImageName(GenericContainer.java:1362)
...
at org.testcontainers.images.RemoteDockerImage.resolve(RemoteDockerImage.java:105)
```

## Root Cause Analysis
1. The `logger()` method in `GenericContainer` calls `DockerLoggerFactory.getLogger(this.getDockerImageName())` which eagerly evaluates `getDockerImageName()`
2. The `getDockerImageName()` method triggers ECR credential resolution via `RemoteDockerImage.resolve()`
3. Even when debug logging is disabled, the method reference `{}` in `logger().debug("Starting container: {}", getDockerImageName())` evaluates the argument before the log level check
4. In SLF4J 1.7.x, method references with `{}` are evaluated eagerly (unlike SLF4J 2.x which supports lambdas)

## Proposed Solution
1. **Change `logger()` method** to use a constant logger name instead of calling `getDockerImageName()`:
   ```java
   return DockerLoggerFactory.getLogger("tc.genericcontainer");
   ```

2. **Use `isDebugEnabled()` guard** for debug logging calls that need the image name:
   ```java
   if (logger().isDebugEnabled()) {
       logger().debug("Starting container: " + getDockerImageName());
   }
   ```

## Files to Modify
- `core/src/main/java/org/testcontainers/containers/GenericContainer.java`
  - Line ~666: `logger()` method
  - Line ~328: `doStart()` debug call
  - Line ~371: `tryStart()` debug call

## Testing Strategy
1. Compile the core module: `./gradlew :testcontainers:compileJava`
2. Run GenericContainer tests: `./gradlew :testcontainers:test --tests '*GenericContainer*'`
3. Verify no compilation errors and tests pass

## Risks / Considerations
- SLF4J 1.7.x doesn't support lambda syntax for lazy logging
- The logger name changes from image-specific to generic "tc.genericcontainer"
- This is a minimal fix that avoids breaking changes
