# PR Tracking: Java #9876 - Debug Logging Lazy Evaluation

## PR Information
- **Issue**: #9876
- **Repository**: testcontainers/testcontainers-java
- **PR Link**: https://github.com/testcontainers/testcontainers-java/pull/11982
- **Status**: Open
- **Created**: 2026-08-25
- **Merged**: 

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

## Related
- Issue: #9876
- Discussion: https://github.com/testcontainers/testcontainers-java/pull/11982