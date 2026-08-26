# Rust Commit Guidelines

## Commit Style

| Rule | Detail |
|------|--------|
| **Atomic** | Single logical change per commit |
| **Squash if uncertain** | Prefer one clean commit over incomplete ones |
| **Verified** | Tests pass after each commit |

## Pre-Commit Verification

```bash
cargo +nightly fmt --all -- --check
cargo clippy
cargo test --features blocking
```

## Commit Message Format

- Follow [Chris Beams guide](https://chris.beams.io/posts/git-commit/)
- Reference issue: `Closes #926`
- Keep subject line under 72 chars

## Branch Strategy

- Push to existing branch for PR updates
- Use descriptive branch names: `fix/926-standard-label`

## Related

- [Contributing Guide](https://github.com/testcontainers/testcontainers-rs/blob/main/CONTRIBUTING.md)