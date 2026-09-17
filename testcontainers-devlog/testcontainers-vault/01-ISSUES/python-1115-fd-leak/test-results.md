# Test Results: Python #1115 - fd leak in HttpWaitStrategy

## Env
- VPS Debian 13, Python 3.13.5, uv 0.12.15, pytest 9.1.1, ruff (repo-pinned via uv)
- Setup: uv sync --project /home/bruno/testcontainers-python --frozen

## TDD red (pre-fix)
Command: uv run --frozen pytest tests/core/test_wait_strategies.py -k always_closes_error or unexpected_status
Result: 2 FAILED (Expected close to be called once. Called 0 times - both params), 1 passed (behavioral)
Verdict: leak reproduced at contract level.

## Post-fix targeted
Same command. Result: 3 passed.

## Full suites
- tests/core/test_wait_strategies.py: 88 passed
- tests/core/test_labels.py: 9 passed (regression guard for label behavior)
- Combined run: 97 passed, 0 failed

## Lint
- ruff check (both changed files): All checks passed
- ruff format --check: clean after one auto-format (blank lines between methods in new test)

## Not run (out of scope)
- Docker-based integration tests (test_wait_strategies_integration.py): unit path fully covers the change; container path untouched.
- The literal issue MRE (typesense image): heavy pull avoided; live 127.0.0.1 503-server test covers the same urlopen-to-HTTPError path.

## Summary
Fix verified: contract test gates close() on both outcomes, behavior preserved, lint clean.
