# PR Tracking: Rust #926 - Add org.testcontainers=true Label

## PR Information
- **Issue**: #926
- **Repository**: testcontainers/testcontainers-rs
- **PR Link**: https://github.com/testcontainers/testcontainers-rs/pull/969
- **Status**: Open (mergeable, awaiting maintainer review)
- **Created**: 2026-08-25
- **Merged**: 
- **Verified**: 2026-09-17
- **Live check 2026-09-17**: OPEN, MERGEABLE, merge blocked on review. 1 commit, 2 comments. Reviews: Codex COMMENTED, own follow-up COMMENTED. No upstream movement since 2026-08-31.

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

## Related
- Issue: #926
- Discussion: https://github.com/testcontainers/testcontainers-rs/pull/969