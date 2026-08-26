# Rust Formatting & Linting

## Commands

| Check | Command |
|-------|---------|
| Format check | `cargo +nightly fmt --all -- --check` |
| Apply format | `cargo +nightly fmt --all` |
| Lint | `cargo clippy` |
| Test | `cargo test --features blocking` |

## Toolchain

| Tool | Version |
|------|---------|
| Rust | Stable (rustup) |
| Formatter | rustfmt (nightly) |
| Linter | clippy |
| cargo-hack | Recommended |

## CI Requirements

All must pass:
- `cargo +nightly fmt --all -- --check`
- `cargo clippy`
- `cargo test --features blocking`

## Related

- [Contributing Guide](https://github.com/testcontainers/testcontainers-rs/blob/main/CONTRIBUTING.md)