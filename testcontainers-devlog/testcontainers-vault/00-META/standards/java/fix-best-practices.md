# Java Fix Best Practices

*Lessons learned from PR #11982 review feedback*

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Fix only what's requested** | No extra guards, no quality improvements beyond the issue scope |
| **Fix and leave** | Don't add improvements not requested in the issue/PR |
| **No scope creep** | Revert unrelated changes (e.g., toolchain versions) |

## Logging

| Violation | Correct Approach |
|-----------|------------------|
| String concatenation | Use SLF4J parameterized logging: `logger.debug("msg: {}", value)` |
| One-line `if` without braces | Always use braced blocks (Checkstyle `NeedBraces`) |

## Logger Configuration

| Issue | Correct Approach |
|-------|------------------|
| Logger name `"tc.genericcontainer"` | Use `"genericcontainer"` (avoids `tc.tc.` prefix) |
| Javadoc claims image-specific logger | Update to reflect shared logger: "Provide the shared logger for generic container lifecycle messages" |

## Code Changes

| Violation | Correct Approach |
|-----------|------------------|
| Unrelated toolchain changes | Revert (e.g., Java 21 → 17) |
| Extra guards not in issue | Only add what the issue requests |
| Unnecessary guard in `tryStart()` | Image already resolved, use directly with parameterized logging |

## Test Hygiene

| Issue | Correct Approach |
|-------|------------------|
| Test appender leak | Add `finally` block to detach `ListAppender` from shared logger |

## Checklist for PR

- [ ] Only changes requested in the issue
- [ ] No quality improvements beyond the fix
- [ ] SLF4J parameterized logging used
- [ ] Braced blocks for all `if` statements
- [ ] Parameterized logging used (not string concatenation)
- [ ] Logger name correct (no double prefix)
- [ ] Javadoc updated for changed methods
- [ ] Unrelated changes reverted
- [ ] Test appender cleanup in `finally` blocks
- [ ] `./gradlew checkstyleMain checkstyleTest spotlessApply` passes
- [ ] Tests pass: `./gradlew :testcontainers:test --tests '*GenericContainer*'`