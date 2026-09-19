# Session Log: 2026-09-17 (deep verification)

## What ran
- Restarted docker (was stopped for bare-OS sweep); daemon 29.7.2 healthy.
- #1118 branch: test_wait_strategies_integration.py 4 passed (hello-world, alpine, compose).
- #1111 branch: pulled trinodb/trino:451 (2.49GB); existing test_trino.py 1 passed in 22s.
- Exact #1111 repro through fixed get_connection_url(): trino://test@localhost:32772, select 1 -> [(1,)].
- Quoting detour: shell transport strips bare double quotes; printf with backslash-quote verified byte-exact via od before use.

## Result
- Both Python fixes proven end-to-end against real containers, not just mocks.
- Vault test-results updated for both issues. Disk 78pct after trino pull.

## Next
- Review-watch on all 4 PRs; re-check Python CI checks appearing.
