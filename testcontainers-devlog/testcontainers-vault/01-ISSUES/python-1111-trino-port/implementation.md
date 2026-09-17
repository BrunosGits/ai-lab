# Implementation: Python #1111 - Trino get_connection_url uses internal port

## Branch
- Fork: BrunosGits/testcontainers-python, branch fix/1111-trino-port off upstream/main (LOCAL on VPS clone, not pushed yet)

## Changes Made

### 1. src/testcontainers/community/trino/__init__.py - get_connection_url
Before:
    return f"trino://{self.user}@{self.get_container_host_ip()}:{self.port}"
After:
    return f"trino://{self.user}@{self.get_container_host_ip()}:{self.get_exposed_port(self.port)}"

### 2. tests/community/trino/test_trino_url.py - new regression test
Instantiates TrinoContainer() without starting it (init needs no daemon), patches get_container_host_ip/get_exposed_port, asserts URL is trino://test@localhost:58092 and get_exposed_port was called with 8080. No trino client lib or image needed.

## Verification
- TDD red pre-fix (via git stash): FAILED with port 8080 in URL.
- Post-fix: 1 passed. ruff check + format clean on both files.

## Notes
- One-line fix exactly as the reporter suggested; mirrors _create_connection_url behavior in sibling modules.
- Existing docker-based test_trino.py untouched - it already bypasses get_connection_url.
