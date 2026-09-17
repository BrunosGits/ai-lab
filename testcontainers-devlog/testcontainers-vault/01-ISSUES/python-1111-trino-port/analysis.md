# Issue Analysis: Python #1111 - Trino get_connection_url uses internal port

## Issue Reference
- **Issue**: #1111
- **Repository**: testcontainers/testcontainers-python
- **Link**: https://github.com/testcontainers/testcontainers-python/issues/1111
- **Type**: Bug (reported 2026-08-27, unassigned, 0 comments - no contention)

## Problem Statement
TrinoContainer.get_connection_url() builds trino://{user}@{host}:{self.port} with self.port fixed at 8080 in __init__. Docker maps that to a random host port, so the returned URL can never connect.

## Root Cause Analysis
1. src/testcontainers/community/trino/__init__.py: get_connection_url interpolates self.port directly.
2. self.port is never resolved through get_exposed_port() - unlike CockroachDB/CrateDB, which route via _create_connection_url() that resolves the mapped port.
3. Isolated miss in the Trino module: the existing test (tests/community/trino/test_trino.py) works around it by calling get_exposed_port itself.

## Proposed Solution
One line, matching the issue suggestion and sibling modules:

    self.get_exposed_port(self.port) instead of self.port

## Files to Modify
- src/testcontainers/community/trino/__init__.py - get_connection_url
- tests/community/trino/test_trino_url.py - new mock-based regression test (no trino package / image needed)

## Testing Strategy
1. TDD: new test must FAIL pre-fix (URL carries 8080).
2. Post-fix: new test passes; ruff check + format clean.
3. Existing test_trino.py needs trinodb/trino image + trino client lib - out of scope for VPS verification; left untouched (already uses get_exposed_port directly, unaffected).

## Risks / Considerations
- get_exposed_port requires a started container at runtime - same precondition as the neighboring get_container_host_ip() call; no new constraint.
- No API change: same method, now returning a usable URL.
