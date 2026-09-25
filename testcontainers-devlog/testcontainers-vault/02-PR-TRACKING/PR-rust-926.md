# PR Tracking: Rust #926 - Add org.testcontainers=true Label

## PR Information
- **Issue**: #926
- **Repository**: testcontainers/testcontainers-rs
- **PR Link**: https://github.com/testcontainers/testcontainers-rs/pull/969
- **Status**: Open (mergeable, awaiting maintainer review)
- **Created**: 2026-08-25
- **Merged**: 
- **Verified**: 2026-09-17
- **Live check 2026-09-25**: OPEN, MERGEABLE. CI retriggered via empty commit `ee93c27`; fresh run #1711 in `action_required` (fork approval gate). Approval ask posted; waiting on maintainer to approve CI + review.

## Changes Summary
- Added `org.testcontainers=true` label to default labels in `ContainerRequest::from()`
- Updated test `async_start_should_apply_expected_labels` to expect new label
- Achieves ecosystem consistency with Java/Go implementations

## Testing
- [x] Format check passed (`cargo +nightly fmt --all -- --check`)
- [x] Clippy passed (`cargo clippy`)
- [x] All relevant tests passed (`cargo test --features blocking` - 85 passed, 1 pre-existing failure)
- [x] Specific label test passed (`cargo test --lib async_start_should_apply_expected_labels`)

## Review Notes
- Minimal change for ecosystem consistency
- Preserves existing `org.testcontainers.managed-by=testcontainers` label
- No breaking changes
- 1 commit; local Cargo.toml drift (unused serde_yaml) reverted 2026-09-17 -- diff vs main is exactly the 2-file change

## CI Failure Review (2026-09-25)

- CI run #1698 (2026-08-26) failed with "workflow file issue": 0 jobs, no logs. Workflow file byte-identical to `main`; diff touches only 2 Rust files — not a test failure.
- 4-model fixer panel (laguna-s21, nemotron, spark, glm47-flash; qwen38 provider down): unanimous — platform-side, likely GitHub Actions incident window Aug-26 15:11-18:01 UTC. Release Drafter failing identically is the strongest proof.
- Panel caveat: retrigger lands in the fork approval gate, so maintainer approval (not retriggering) is the real unblock.
- Empty commit `ee93c27` pushed 2026-09-25 → fresh run #1711 went straight to `action_required`, confirming the transient theory.
- Approval ask posted: https://github.com/testcontainers/testcontainers-rs/pull/969#issuecomment-5825394979

## Related
- Issue: #926
- Discussion: https://github.com/testcontainers/testcontainers-rs/pull/969