# Python Standards Quick Reference

## Commands

| Category | Command |
|----------|---------|
| Format/Lint | `make lint` |
| Test (core) | `make core/tests` |
| Test (module) | `make community/<module>/tests` |
| Install | `make install` |
| Package Manager | `uv` + Make |

## Commit Rules

| Rule | Detail |
|------|--------|
| Verify | Run tests after each commit |
| Discuss First | Recommended |

## Project Config

| Setting | Value |
|---------|-------|
| Package Manager | `uv` + Make |
| Docs | MkDocs + Material + codeinclude |
| Release | Automated (`release-please`) |

## Key Links

- [Contributing Guide](https://github.com/testcontainers/testcontainers-python/blob/main/docs/contributing.md)