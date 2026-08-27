---
type: pr
number: 22750
title: Fix flaky AnalyticsQueryTaskCleanupIT
status: open
issue: 22706
ci: green (all checks passed including gradle-check)
review: awaiting review
tags: [opensearch, pr, flaky-test, analytics-engine, transport]
---

# PR #22750: Fix Flaky AnalyticsQueryTaskCleanupIT

## Summary

One-line fix: changed the failure injector in `AnalyticsQueryTaskCleanupIT` from injecting a raw `TaskCancelledException` to injecting a `StreamException(StreamErrorCode.CANCELLED, "failure inject")`. On the streaming channel, raw `TaskCancelledException` gets silently swallowed. The receiver never sees the error, never cancels the stage, and the coordinator waits forever.

## Files Changed

- `sandbox/qa/analytics-engine-coordinator/src/internalClusterTest/java/org/opensearch/analytics/cancellation/AnalyticsQueryTaskCleanupIT.java` — line 582: `TaskCancelledException` → `StreamException(StreamErrorCode.CANCELLED, "failure inject")`

## CI Status

All checks passed including `gradle-check`. CI is green.

## Review Status

Awaiting maintainer review. Author @feriz00 gave green light on issue #22706.

## References

- [GitHub PR](https://github.com/opensearch-project/OpenSearch/pull/22750)
- [Issue #22706](https://github.com/opensearch-project/OpenSearch/issues/22706)
- [[22706-flaky-test]]
