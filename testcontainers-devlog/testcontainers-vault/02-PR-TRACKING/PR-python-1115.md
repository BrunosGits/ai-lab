# PR Tracking: Python #1115 - fd leak in HttpWaitStrategy

## PR Information
- **Issue**: #1115
- **Repository**: testcontainers/testcontainers-python
- **PR Link**: https://github.com/testcontainers/testcontainers-python/pull/1118
- **Status**: Open (mergeable, merge blocked - CI/review pending)
- **Live check 2026-09-17**: OPEN, MERGEABLE. 1 commit, 0 comments, 0 reviews. CI workflows (ci-core/ci-lint/pr-lint) trigger on PR but no checks reported yet - re-check next session.
- **Created**: 2026-09-17 (VPS date)
- **Merged**: 

## Changes Summary
- _handle_http_error: try/finally that closes HTTPError (fixes fd leak)
- 2 regression tests in TestHttpWaitStrategy (mock close assertion + live 503-server behavior)

## Testing
- [x] TDD red pre-fix (close called 0 times)
- [x] Post-fix 3/3 new tests pass
- [x] Full wait-strategy suite 88 passed + labels 9 passed
- [x] ruff check + format clean

## Review Notes
- Branch fix/1115-http-fd-leak pushed (a922578); PR #1118 opened 2026-09-17.
- Fork BrunosGits/testcontainers-python created; upstream remote configured.

## Related
- Issue: #1115
