# Java Commit Guidelines

## Commit Style

| Rule | Detail |
|------|--------|
| **Atomic** | Single logical change per commit |
| **Verified** | Tests pass after each commit |
| **Descriptive** | Clear message explaining the change |

## Pre-Commit Verification

```bash
./gradlew checkstyleMain checkstyleTest spotlessApply
./gradlew :testcontainers:test --tests '*RelevantTest*'
```

## Commit Message Format

- Reference issue: `Closes #9876`
- Describe the fix, not the implementation
- Keep subject line under 72 chars

## Branch Strategy

- Push to existing branch for PR updates
- Use descriptive branch names: `fix/9876-debug-logging`

## Related

- [Contributing Guide](https://java.testcontainers.org/contributing/)
- [PR Template](https://github.com/testcontainers/testcontainers-java/blob/main/.github/pull_request_template.md)