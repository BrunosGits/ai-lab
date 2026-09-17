# Issue Analysis: Python #1115 - fd leak in HttpWaitStrategy

## Issue Reference
- **Issue**: #1115
- **Repository**: testcontainers/testcontainers-python
- **Link**: https://github.com/testcontainers/testcontainers-python/issues/1115
- **Type**: Bug (reported 2026-09-10, unassigned, 0 comments - no contention)

## Problem Statement
Using HttpWaitStrategy in DockerContainer.waiting_for against an endpoint that answers with an error status leaks a file descriptor: the underlying HTTPError is never closed. Under python -Werror::ResourceWarning the reporter saw "Implicitly cleaning up <HTTPError 503>" from tempfile.__del__.

## Root Cause Analysis
1. _try_http_request (wait_strategies.py) calls urlopen inside a with-block, but urlopen RAISES HTTPError for error statuses - the with-block never owns it.
2. The except (URLError, HTTPError) arm forwards the error to _handle_http_error, which reads error.code and returns - without ever closing the error object.
3. HTTPError wraps the response body fp (tempfile-backed - HTTPError.close resolves to _TemporaryFileWrapper.close on 3.13), so each failed poll holds an fd until GC.
4. Verified on VPS: a Mock(spec=HTTPError) passed through the handler shows close called 0 times pre-fix.

## Proposed Solution
Wrap _handle_http_error body in try/finally; in finally, if isinstance(error, HTTPError): error.close(). No API change, logging preserved (debug line runs before close).

## Files to Modify
- src/testcontainers/core/wait_strategies.py - _handle_http_error (~L428)
- tests/core/test_wait_strategies.py - TestHttpWaitStrategy: 2 regression tests

## Testing Strategy
1. TDD: mock-based close assertion (parametrized 503/200) must FAIL pre-fix.
2. Live behavioral test: local 503 server, _try_http_request returns False for 200-expectation, True for 503-expectation.
3. Full tests/core/test_wait_strategies.py + test_labels.py green; ruff check + format clean.
4. No docker needed for the unit path; no heavy image pulls.

## Risks / Considerations
- close() guarded by isinstance: plain URLError path untouched.
- str(error) in the debug log runs before close - no use-after-close.
- The ResourceWarning itself only surfaces on 3.14+; the mock test gates the contract on all versions.
