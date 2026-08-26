# Python Fix Best Practices

*Adapted from Java PR #11982 lessons - only strictly applicable items*

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Fix only what's requested** | No extra guards, no quality improvements beyond the issue scope |
| **Fix and leave** | Don't add improvements not requested in the issue/PR |
| **No scope creep** | Revert unrelated changes |

## Code Style

| Violation | Correct Approach |
|-----------|------------------|
| String concatenation in logging/debug | Use parameterized/structured logging |
| Missing type hints | Add type hints for new functions |

## Code Changes

| Violation | Correct Approach |
|-----------|------------------|
| Unrelated pyproject.toml/dependency changes | Revert unless issue requests |
| Extra guards not in issue | Only add what the issue requests |
| Unnecessary guards | Remove redundant checks |

## Formatting & Linting

| Requirement | Command |
|-------------|---------|
| Format/Lint check | `make lint` |

## Module Process

| Violation | Correct Approach |
|-----------|------------------|
| New module without issue | Create issue FIRST, then PR |

## Checklist for PR

- [ ] Only changes requested in the issue
- [ ] No quality improvements beyond the fix
- [ ] `make lint` passes
- [ ] `make core/tests` passes (or relevant module tests)
- [ ] New modules have issue first
- [ ] No unrelated changes