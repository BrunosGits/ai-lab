---
type: issue
number: 22706
title: Flaky test AnalyticsQueryTaskCleanupIT
status: open
project: opensearch
root-cause: When a task was cancelled, the failure injector injected a raw TaskCancelledException. On the streaming channel this got silently swallowed. The receiver never got the error, never cancelled the stage, never sent a completion signal. The test waited forever.
key-files:
  - sandbox/qa/analytics-engine-coordinator/src/internalClusterTest/java/org/opensearch/analytics/cancellation/AnalyticsQueryTaskCleanupIT.java
  - sandbox/plugins/analytics-engine/src/main/java/org/opensearch/analytics/transport/AnalyticsTransportErrors.java
  - sandbox/plugins/analytics-engine/src/main/java/org/opensearch/analytics/stream/StreamException.java
tags: [opensearch, issue, flaky-test, analytics-engine, transport]
---

# Issue #22706: Flaky AnalyticsQueryTaskCleanupIT

## Summary

`AnalyticsQueryTaskCleanupIT` was randomly failing in CI. The test cancels a query and expects cleanup, but sometimes the cleanup never happens.

## Root Cause

The test's failure injector was injecting a raw `TaskCancelledException`. On a streaming channel, `TaskCancelledException` is not a recognized error type. The framework wraps unknown exceptions in `StreamException` for logging, but the original exception doesn't cross the wire. The receiver never sees the error, never cancels the stage, and the coordinator waits forever for a completion signal.

**Key insight**: The wire form of a cancellation error must be `StreamException` with `StreamErrorCode.CANCELLED`, not a raw `TaskCancelledException`.

## Key Files

- `AnalyticsQueryTaskCleanupIT.java` — the flaky test (line 582)
- `AnalyticsTransportErrors.java` — error conversion utilities
- `StreamException.java` — wire-form error class

## What Was Done

- Changed the failure injector from `TaskCancelledException` to `StreamException(StreamErrorCode.CANCELLED, "failure inject")`
- Verified that imports were already present (`StreamErrorCode` and `StreamException` both imported at lines 44-45)
- Verified constructor validity and expected behavior in test
- PR: [[22750-flaky-test-fix]]

## Related PRs

- [[22750-flaky-test-fix]]

## References

- [GitHub Issue](https://github.com/opensearch-project/OpenSearch/issues/22706)
- [Roadmap entry](../ROADMAP.md)
