# PR Tracking: Rust #926 - Add org.testcontainers=true Label

## PR Information
- **Issue**: #926
- **Repository**: testcontainers/testcontainers-rs
- **PR Link**: https://github.com/testcontainers/testcontainers-rs/pull/969
- **Status**: Open
- **Created**: 2026-08-25
- **Merged**: 

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

## Related
- Issue: #926
- Discussion: https://github.com/testcontainers/testcontainers-rs/pull/969