# Test Results: Python #1111 - Trino get_connection_url uses internal port

## Env
- VPS Debian 13, Python 3.13.5, uv 0.12.15, pytest 9.1.1 (venv from S5 uv sync)
- Branch fix/1111-trino-port off upstream/main

## TDD red (pre-fix, fix stashed)
Command: uv run --frozen pytest tests/community/trino/test_trino_url.py -q
Result: 1 FAILED (URL carried internal 8080 instead of mapped port)
Verdict: bug reproduced.

## Post-fix
Same command. Result: 1 passed.

## Lint
- ruff check (both files): All checks passed
- ruff format --check: clean, no reformat needed

## Not run (out of scope)
- tests/community/trino/test_trino.py: needs trinodb/trino image pull (heavy) + trino client lib; exercises a path that already used get_exposed_port directly, so unaffected by this change.

## Deep verification 2026-09-17 (docker restarted, trinodb/trino:451 pulled)
- tests/community/trino/test_trino.py (existing, real container + trino client): 1 passed in 22s.
- Exact issue repro via fixed get_connection_url(): URL trino://test@localhost:32772 (mapped port, not 8080); sqlalchemy select 1 returned [(1,)] - URL-CONNECT-OK.
- Ephemeral deps via uv run --with (trino, sqlalchemy); project files untouched.
- Cost: trino image 2.49GB, disk now 78pct / 8.5G free.

## Summary
One-line fix verified at contract level; lint clean; no regressions possible in paths that do not call get_connection_url.
