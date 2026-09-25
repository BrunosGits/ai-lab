# PR Tracking: Java #9876 - Debug Logging Lazy Evaluation

## PR Information
- **Issue**: #9876
- **Repository**: testcontainers/testcontainers-java
- **PR Link**: https://github.com/testcontainers/testcontainers-java/pull/11982
- **Status**: Open (mergeable, awaiting maintainer review)
- **Created**: 2026-08-25
- **Merged**: 
- **Verified**: 2026-09-17
- **Live check 2026-09-25**: OPEN, MERGEABLE. 4 fresh runs (head `02d76ab`) all in `action_required` (fork approval gate). Approval ask posted to @kiview; waiting on maintainer to approve CI + review.

## Changes Summary
- Modified `GenericContainer.logger()` to use constant logger name "tc.genericcontainer"
- Added `isDebugEnabled()` guards in `doStart()` and `tryStart()` methods
- Prevents ECR credential resolution when debug logging is disabled

## Testing
- [x] Format check (spotlessApply - skipped due to npm issues, manual formatting verified)
- [x] All tests passed (`./gradlew :testcontainers:test --tests '*GenericContainer*'`)
- [x] WaitStrategy tests pass
- [x] Compilation successful

## Review Notes
- SLF4J 1.7.x doesn't support lambda syntax, used `isDebugEnabled()` guard pattern
- Logger name changed from image-specific to generic
- No breaking changes to public API
- 2 commits (initial fix + review-feedback follow-up); CodeRabbit + Codex bot reviews; reviewer requested: kiview
- Final logger name "genericcontainer" (tc.tc prefix fixed per review); local fork re-aligned to origin/fix/9876-debug-logging on 2026-09-17

## CI Failure Review (2026-09-25)

- 4 runs on old head `310ef8b` (2026-08-26: CI, Rootless, Wormhole, Release Drafter) all failed with "workflow file issue": 0 jobs, no logs. Diff touches only `GenericContainer.java` + test — not test failures.
- Same 4-model fixer panel verdict as Rust PR: platform-side (Aug-26 Actions incident window), Release Drafter failing identically is the proof.
- Current head `02d76ab` runs never failed — they sit in `action_required` awaiting maintainer approval.
- Approval ask posted to @kiview: https://github.com/testcontainers/testcontainers-java/pull/11982#issuecomment-5825394984

## Related
- Issue: #9876
- Discussion: https://github.com/testcontainers/testcontainers-java/pull/11982