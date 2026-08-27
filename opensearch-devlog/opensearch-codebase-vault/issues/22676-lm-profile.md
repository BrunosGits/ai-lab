---
type: issue
number: 22676
title: LATE_MATERIALIZATION profile metrics
status: open
project: opensearch
root-cause: LATE_MATERIALIZATION stage had no profile output. Needed description, timing, and scatter/gather metrics.
key-files:
  - sandbox/plugins/analytics-engine/src/main/java/org/opensearch/analytics/queryplanner/QueryProfileBuilder.java
  - sandbox/plugins/analytics-engine/src/main/java/org/opensearch/analytics/queryplanner/stages/LateMaterializationStageExecution.java
tags: [opensearch, issue, analytics-engine, profiling, late-materialization]
---

# Issue #22676: LATE_MATERIALIZATION Profile Metrics

## Summary

The LATE_MATERIALIZATION stage in the analytics engine had no profile output. The PR added description, timing, and scatter/gather metrics to match SHARD_FRAGMENT and COORDINATOR_REDUCE.

## Root Cause

`QueryProfileBuilder` was missing a `describeTarget()` method for the LM stage, and `LateMaterializationStageExecution` wasn't collecting any metrics.

## Key Files

- `QueryProfileBuilder.java` — builds profile output for each stage
- `LateMaterializationStageExecution.java` — LM stage scatter/gather

## What Was Done

- Added `describeTarget()` to `QueryProfileBuilder` for the LM stage
- Added metrics collection in `LateMaterializationStageExecution`
- Fixed shard label to use `nodeId/indexName/shard[N]` format
- Deferred BWC guard for `profile` field to issue [#22822](https://github.com/opensearch-project/OpenSearch/issues/22822)
- Deferred static test flag as separate change
- CI now green

## Review Notes

- Shard label fix verified: both `QueryProfileBuilder.describeTarget` and `LateMaterializationStageExecution.scatterFetchAndStitch` use `nodeId/indexName/shard[N]` format
- BWC deferral to #22822 is reasonable for sandbox
- Static test flag deferred as separate change
- Ready to approve with confirmation comment

## References

- [GitHub PR](https://github.com/opensearch-project/OpenSearch/pull/22676)
- [Roadmap entry](../ROADMAP.md)
