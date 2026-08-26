# Issue Analysis: Rust #926 - Add org.testcontainers=true Label

## Issue Reference
- **Issue**: #926
- **Repository**: testcontainers-rs
- **Link**: https://github.com/testcontainers/testcontainers-rs/issues/926
- **Type**: Enhancement / Good First Issue

## Problem Statement
The Rust implementation only adds `org.testcontainers.managed-by=testcontainers` label to containers. Other language implementations (Java, Go) also add `org.testcontainers=true` for ecosystem consistency. This makes it harder to filter/clean up testcontainers across different language implementations using the standard label.

## Root Cause Analysis
1. In `ContainerRequest::from()` implementation, the default labels only include `org.testcontainers.managed-by=testcontainers`
2. The standard `org.testcontainers=true` label is not added by default
3. This inconsistency makes cross-language container management difficult

## Proposed Solution
Add `org.testcontainers=true` label to the default labels in `ContainerRequest::from()` implementation.

## Files to Modify
- `testcontainers/src/core/containers/request.rs` - `ContainerRequest::from()` method
- `testcontainers/src/runners/async_runner.rs` - Test `async_start_should_apply_expected_labels` needs update

## Testing Strategy
1. Format check: `cargo +nightly fmt --all -- --check`
2. Clippy: `cargo clippy`
3. Tests: `cargo test --features blocking`
4. Verify label is applied: Manual docker inspect
