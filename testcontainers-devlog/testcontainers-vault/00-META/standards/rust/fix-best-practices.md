# Rust Fix Best Practices

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
| Missing braces on `if` | Always use braced blocks (clippy will catch) |

## Code Changes

| Violation | Correct Approach |
|-----------|------------------|
| Unrelated Cargo.toml/toolchain changes | Revert unless issue requests |
| Extra guards not in issue | Only add what the issue requests |
| Unnecessary guards | Remove redundant checks |

## Formatting & Linting

| Requirement | Command |
|-------------|---------|
| Format check | `cargo +nightly fmt --all -- --check` |
| Lint check | `cargo clippy` |

## Checklist for PR

- [ ] Only changes requested in the issue
- [ ] No quality improvements beyond the fix
- [ ] `cargo +nightly fmt --all -- --check` passes
- [ ] `cargo clippy` passes (no warnings)
- [ ] `cargo test --features blocking` passes
- [ ] No unrelated changes