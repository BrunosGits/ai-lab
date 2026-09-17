# PR Tracking: Python #1111 - Trino get_connection_url uses internal port

## PR Information
- **Issue**: #1111
- **Repository**: testcontainers/testcontainers-python
- **PR Link**: https://github.com/testcontainers/testcontainers-python/pull/1119
- **Status**: Open (mergeable, merge blocked - CI/review pending)
- **Live check 2026-09-17**: OPEN, MERGEABLE. 1 commit, 0 comments, 0 reviews. CI workflows trigger on PR but no checks reported yet - re-check next session.
- **Created**: 2026-09-17 (VPS date)
- **Merged**: 

## Changes Summary
- get_connection_url: self.port replaced with self.get_exposed_port(self.port)
- New mock-based regression test (no image / client lib needed)

## Testing
- [x] TDD red pre-fix
- [x] Post-fix 1 passed
- [x] ruff check + format clean

## Review Notes
- Branch fix/1111-trino-port pushed; PR #1119 opened 2026-09-17.

## Related
- Issue: #1111
