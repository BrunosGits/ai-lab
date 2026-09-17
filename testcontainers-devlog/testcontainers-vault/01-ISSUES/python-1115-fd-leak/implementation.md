# Implementation: Python #1115 - fd leak in HttpWaitStrategy

## Branch
- Fork: BrunosGits/testcontainers-python, branch fix/1115-http-fd-leak (LOCAL on VPS clone, not pushed yet - PR is S6)
- Base: upstream main @ 8d81011

## Changes Made

### 1. src/testcontainers/core/wait_strategies.py - _handle_http_error
Before: read error.code, return True/False, never close.
After: same logic wrapped in try/finally; finally closes the error when it is an HTTPError:

    try:
        if isinstance(error, HTTPError) and (...):
            return True
        logger.debug(...)
        return False
    finally:
        if isinstance(error, HTTPError):
            error.close()

### 2. tests/core/test_wait_strategies.py - TestHttpWaitStrategy
- test_handle_http_error_always_closes_error (parametrized 503/200): Mock(spec=HTTPError) through the handler, asserts return value AND error.close called once.
- test_try_http_request_unexpected_status: live 127.0.0.1 server answering 503; asserts _try_http_request is False when expecting 200, True when expecting 503.
- Imports added: threading, http.server (BaseHTTPRequestHandler, HTTPServer), urllib.error.HTTPError. ruff format applied.

## Verification
- TDD red pre-fix: both close assertions failed (Called 0 times); behavioral test passed (logic was fine, only cleanup missing).
- Post-fix: 3/3 new tests pass; full file 88 passed; test_labels.py 9 passed; ruff check + format clean.

## Notes
- Chose try/finally + close() over the with/nullcontext sketch in the issue: equivalent, fewer imports, keeps the debug log readable.
- Plain URLError (no fp) path unchanged.
