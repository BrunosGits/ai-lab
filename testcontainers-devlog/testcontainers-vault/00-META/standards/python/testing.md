# Python Testing

## Commands

| Test Scope | Command |
|------------|---------|
| Core tests | `make core/tests` |
| Module tests | `make community/<module>/tests` |
| All tests | `make test` (if available) |

## Package Manager

- Primary: `uv`
- Task runner: `make`
- Install: `make install` (sets up pre-commit)

## Test Organization

- Core tests in `tests/core/`
- Module tests in `tests/community/<module>/`
- Run specific module: `make community/<module>/tests`

## CI Requirements

- `make lint` passes
- Relevant tests pass

## Related

- [Contributing Guide](https://github.com/testcontainers/testcontainers-python/blob/main/docs/contributing.md)