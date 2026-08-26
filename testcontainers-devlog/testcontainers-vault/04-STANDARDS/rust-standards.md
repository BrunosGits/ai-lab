# Rust Standards Quick Reference

## Commands

| Category | Command |
|----------|---------|
| Format | `cargo +nightly fmt --all -- --check` |
| Lint | `cargo clippy` |
| Test | `cargo test --features blocking` |
| Pre-commit | `cargo +nightly fmt --all -- --check && cargo clippy` |

## Commit Rules

| Rule | Detail |
|------|--------|
| Style | Atomic, squash if uncertain |
| Verify | Run tests after each commit |
| Discuss First | Recommended |

## Project Config

| Setting | Value |
|---------|-------|
| Toolchain | Rust stable + nightly (rustup) |
| Formatter | rustfmt (nightly) |
| Linter | clippy |

## Key Links

- [Contributing Guide](https://github.com/testcontainers/testcontainers-rs/blob/main/CONTRIBUTING.md)