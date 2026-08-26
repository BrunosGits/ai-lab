# Python New Module Process

## Strict: Issue First

**Raise an issue before any PR for new modules.**

1. Use [issue template](https://github.com/testcontainers/testcontainers-python/blob/main/.github/ISSUE_TEMPLATE/new-container.md)
2. Discuss use case and motivation with maintainers
3. Get maintainer guidance on dependencies and expectations
4. Then proceed with PR

## Module Requirements

| Requirement | Detail |
|-------------|--------|
| Examples | `docs/modules/<module>_example.py` |
| Documentation | `docs/modules/<module>.md` |
| Sphinx doc | `docs/community/<module>.rst` |
| Nav update | Add to `mkdocs.yml` sidebar |

## Community Modules

- Supported on best-effort basis
- Minor/patch only (no major version bumps)
- Broken by minor/patch? Check changelogs

## Release Process

- Automated via `release-please`
- Semantic versioning from commits
- PyPI via trusted publisher
- Auto-updates `pyproject.toml`, `CHANGELOG.md`

## Related

- [Contributing Guide](https://github.com/testcontainers/testcontainers-python/blob/main/docs/contributing.md)
- [Issue Template](https://github.com/testcontainers/testcontainers-python/blob/main/.github/ISSUE_TEMPLATE/new-container.md)