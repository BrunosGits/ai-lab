---
type: pr
number: 22676
title: Emit physical_plan and data_node_metrics for LATE_MATERIALIZATION profile
status: merged
issue: 22676
ci: green (all checks passed)
review: approved & merged by mch2
tags: [opensearch, pr, analytics-engine, profiling, late-materialization]
---

# PR #22676: Emit physical_plan and data_node_metrics for LATE_MATERIALIZATION profile

## Summary

When `profile=true`, the LATE_MATERIALIZATION stage now emits `physical_plan` and `data_node_metrics` per shard, matching the diagnostics available for SHARD_FRAGMENT and COORDINATOR_REDUCE stages.

## Files Changed

- `sandbox/plugins/analytics-engine/src/main/java/org/opensearch/analytics/exec/action/FetchByRowIdsRequest.java` — added `profile` wire field (with version guard)
- `sandbox/plugins/analytics-engine/src/main/java/org/opensearch/analytics/exec/stage/LateMaterializationStageExecution.java` — dispatch fetch-by-row-ids with profile flag, collect per-shard metrics
- `sandbox/plugins/analytics-engine/src/main/java/org/opensearch/analytics/exec/profile/QueryProfileBuilder.java` — build per-shard TaskProfile from shardMetrics map (sorted by shard label)
- `sandbox/qa/analytics-engine-rest/src/test/java/org/opensearch/analytics/qa/LateMaterializationProfileIT.java` — integration test verifying profile output

## CI Status

All checks passed. Merged by mch2 on 2026-08-31.

## Review Contributions

- Identified wire BWC guard violation (missing version check on new `profile` boolean)
- Found static test provisioning flag anti-pattern
- Flagged shard label uniqueness risk (nodeId + shardId only, no index name)

## References

- [GitHub PR](https://github.com/opensearch-project/OpenSearch/pull/22676)
- [[22676-lm-profile-metrics]]