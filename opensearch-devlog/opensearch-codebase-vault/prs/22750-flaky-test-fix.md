---
type: pr
number: 22750
title: Fix flaky AnalyticsQueryTaskCleanupIT
status: open
issue: 22706
ci: rebased head MERGEABLE; Jenkins 84880 failed = env OOM, local IT 8/8 green
review: awaiting review; reporter pinned, maintainers pinged
head: 2129b28 (fix/22706-stream-exception-wire-form, on f4918fa96)
tags: [opensearch, pr, flaky-test, analytics-engine, transport]
---

# PR #22750: Fix Flaky AnalyticsQueryTaskCleanupIT

## Summary

One-line fix: changed the failure injector in `AnalyticsQueryTaskCleanupIT` from injecting a raw `TaskCancelledException` to injecting a `StreamException(StreamErrorCode.CANCELLED, "failure inject")`. On the streaming channel, raw `TaskCancelledException` gets silently swallowed. The receiver never sees the error, never cancels the stage, and the coordinator waits forever.

## Files Changed

- `sandbox/qa/analytics-engine-coordinator/src/internalClusterTest/java/org/opensearch/analytics/cancellation/AnalyticsQueryTaskCleanupIT.java` — line 582: `TaskCancelledException` → `StreamException(StreamErrorCode.CANCELLED, "failure inject")`

## CI Status

Split from codec fix, rebased onto `f4918fa96`, head `2129b28`, `MERGEABLE`. Jenkins `gradle-check/84880` on the rebased head FAILED — investigated: annotations generic, console 403, local repro shows env OOM (3.7G box killed the Rust native link), not a test failure.

## Local Verification

Full sandbox `internalClusterTest` for `AnalyticsQueryTaskCleanupIT` on `2129b28` (JDK 25, `-Dsandbox.enabled=true`, LTO-off Rust build): **8 tests, 0 failures, 0 errors**, incl. `testQtfFetchCancelTearsDownAndCleansUp`. Result posted on PR + issue.

## Review Status

Awaiting maintainer review. Reporter @rayshrey pinned on #22706; @opensearch-project/maintainers + @navneet1v pinged on the PR. Needs review + fresh gradle-check + merge.

## References

- [GitHub PR](https://github.com/opensearch-project/OpenSearch/pull/22750)
- [Issue #22706](https://github.com/opensearch-project/OpenSearch/issues/22706)
- [[22706-flaky-test]]
