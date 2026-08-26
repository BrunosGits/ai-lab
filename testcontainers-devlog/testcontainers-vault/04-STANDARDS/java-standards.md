# Java Standards Quick Reference

## Commands

| Category | Command |
|----------|---------|
| Format | `./gradlew spotlessApply` |
| Lint | `./gradlew checkstyleMain checkstyleTest` |
| Test (targeted) | `./gradlew :testcontainers:test --tests '*ClassName*'` |
| Test (full) | `./gradlew check` |
| Pre-commit | `./gradlew checkstyleMain checkstyleTest spotlessApply` |

## Commit Rules

| Rule | Detail |
|------|--------|
| Style | Atomic, easy to merge |
| Verify | Run tests after each commit |
| Discuss First | Required for big changes |

## Project Config

| Setting | Value |
|---------|-------|
| Toolchain | Java 17 (Gradle wrapper) |
| Incubating Period | 3 months for new modules |
| Formatter | Spotless (requires Node.js/npm) |

## Key Links

- [Contributing Guide](https://java.testcontainers.org/contributing/)
- [Documentation Guide](https://java.testcontainers.org/contributing_docs/)
- [PR Template](https://github.com/testcontainers/testcontainers-java/blob/main/.github/pull_request_template.md)