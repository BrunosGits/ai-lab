# Implementation: Java #9876 - Debug Logging Lazy Evaluation

## Changes Made

### 1. Modified `logger()` method (line ~666)
**Before:**
```java
protected Logger logger() {
    return DockerLoggerFactory.getLogger(this.getDockerImageName());
}
```

**After:**
```java
protected Logger logger() {
    return DockerLoggerFactory.getLogger("tc.genericcontainer");
}
```

### 2. Modified `doStart()` debug call (line ~328)
**Before:**
```java
logger().debug("Starting container: {}", getDockerImageName());
```

**After:**
```java
if (logger().isDebugEnabled()) logger().debug("Starting container: " + getDockerImageName());
```

### 3. Modified `tryStart()` debug call (line ~371)
**Before:**
```java
String dockerImageName = getDockerImageName();
logger().debug("Starting container: {}", dockerImageName);
```

**After:**
```java
String dockerImageName = getDockerImageName();
if (logger().isDebugEnabled()) logger().debug("Starting container: " + dockerImageName);
```

## Verification

### Compilation
```bash
./gradlew --no-daemon :testcontainers:compileJava
```
Result: **BUILD SUCCESSFUL**

### Tests
```bash
./gradlew --no-daemon :testcontainers:test --tests '*GenericContainer*'
```
Result: **BUILD SUCCESSFUL** (all tests passed)

```bash
./gradlew --no-daemon :testcontainers:test --tests '*WaitStrategy*'
```
Result: **BUILD SUCCESSFUL** (all tests passed)

## Notes
- Used `isDebugEnabled()` guard pattern compatible with SLF4J 1.7.x
- Logger name changed from image-specific to generic "tc.genericcontainer"
- No breaking changes to public API
- Fix prevents ECR credential resolution when debug logging is disabled
