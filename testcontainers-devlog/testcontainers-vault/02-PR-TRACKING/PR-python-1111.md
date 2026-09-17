# PR Tracking: Python #1111 - Trino get_connection_url uses internal port

## PR Information
- **Issue**: #1111
- **Repository**: testcontainers/testcontainers-python
- **PR Link**: (not opened yet)
- **Status**: Implemented + tested, unpushed
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
- Branch fix/1111-trino-port local on VPS clone; push + PR after #1118 discussion or on next sprint call.

## Related
- Issue: #1111
