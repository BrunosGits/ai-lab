---
type: codebase
module: build
tags: [opensearch, build, gradle]
---

# Build System

OpenSearch uses Gradle. The build logic lives in `buildSrc/`.

## Key Files

| File | Purpose |
|------|---------|
| `build.gradle` | Root build configuration |
| `settings.gradle` | Project settings, module list |
| `gradle.properties` | Build properties |
| `gradlew` / `gradlew.bat` | Gradle wrapper scripts |
| `buildSrc/` | Custom Gradle plugins and tasks |

## Common Commands

From [[commands]]:

```bash
# Build the project
./gradlew build

# Run a single test class
./gradlew :server:test --tests "org.opensearch.package.ClassName"

# Run integration tests
./gradlew :qa:randomized-testing:integrationTest

# Run sandbox tests
./gradlew :sandbox:qa:analytics-engine-coordinator:internalClusterTest

# Generate coverage report
./gradlew jacocoTestReport
```

## How Modules Are Built

Each module has its own `build.gradle`. The root `settings.gradle` includes them. The `buildSrc/` directory contains custom plugins for:

- Plugin packaging
- Test configuration
- Version management
- BWC checks

## CI

The `gradle-check` job runs on Jenkins. It compiles, runs tests, and checks for regressions. The `check-result` GitHub Action aggregates CI status.

## Related

- [[00-overview]] — top-level layout
- [[commands]] — all useful commands
- [[testing-patterns]] — test configuration
