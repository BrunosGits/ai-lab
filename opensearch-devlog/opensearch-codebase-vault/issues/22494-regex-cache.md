---
type: issue
number: 22494
title: Cache compiled regex automatons
status: open
project: opensearch
root-cause: Regexp queries compile a new automaton on every execution. Caching compiled automatons could improve performance for repeated regex patterns.
key-files: []
tags: [opensearch, issue, regex, caching, performance]
---

# Issue #22494: Cache Compiled Regex Automatons

## Summary

When a regexp query is executed, the regex pattern is compiled into a Lucene automaton every time. For patterns that repeat across queries, this is wasteful. Caching compiled automatons could improve performance.

## Root Cause

The regexp query compilation doesn't have a cache. Each execution starts from scratch.

## What Was Done

- Monitored the issue
- Found references in ROADMAP.md
- No PR submitted

## Potential Approach

- Add an LRU cache for compiled automatons keyed by pattern string
- Cache size should be configurable
- Cache should be per-node, not per-index
- Need to consider memory pressure (automatons can be large)

## References

- [GitHub Issue](https://github.com/opensearch-project/OpenSearch/issues/22494)
- [Roadmap entry](../ROADMAP.md)
