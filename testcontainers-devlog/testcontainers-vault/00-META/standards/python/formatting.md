# Python Formatting & Linting

## Commands

| Check | Command |
|-------|---------|
| Format/Lint | `make lint` |
| Install deps | `make install` |

## Toolchain

| Tool | Version |
|------|---------|
| Package Manager | `uv` |
| Task Runner | `make` |
| Formatter/Linter | `pre-commit` / `ruff` |

## CI Requirements

- `make lint` must pass
- `make core/tests` must pass (or relevant module tests)

## Related

- [Contributing Guide](https://github.com/testcontainers/testcontainers-python/blob/main/docs/contributing.md)