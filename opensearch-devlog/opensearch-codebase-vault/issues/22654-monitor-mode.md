---
type: issue
number: 22654
title: MONITOR mode workload group rejections
status: open
project: opensearch
root-cause: INGEST_AND_QUERY mode rejects index requests without a workload group. MONITOR mode also rejects them, which is incorrect. MONITOR should only monitor, not block.
key-files: []
tags: [opensearch, issue, workload-groups, monitor-mode]
---

# Issue #22654: MONITOR Mode Workload Group Rejections

## Summary

When MONITOR mode is enabled, index requests without a workload group are rejected. This is incorrect. MONITOR mode should only observe and report, not block requests.

## Root Cause

The rejection logic in the workload group framework doesn't distinguish between INGEST_AND_QUERY mode (which should reject) and MONITOR mode (which should only observe).

## What Was Done

- Helped investigate the issue
- Found the relevant code paths
- Provided analysis to the reporter
- No PR submitted

## References

- [GitHub Issue](https://github.com/opensearch-project/OpenSearch/issues/22654)
- [Roadmap entry](../ROADMAP.md)
