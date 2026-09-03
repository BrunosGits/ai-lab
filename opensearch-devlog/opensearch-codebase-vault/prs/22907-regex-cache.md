---
type: pr
number: 22907
title: Cache compiled regex automatons across queries
status: draft
issue: 22494
ci: green (gradle-check pass, Validate pass, codecov/patch pass, DCO pass)
review: draft — local verification done, not posted
base: main (3.9.0 / Lucene 10.5.1)
head: 4d6f6013 (zw/regexp-automaton-cache, 2026-09-01)
tags: [opensearch, pr, regex, cache, performance, lucene]
---

# PR #22907: Cache Compiled Regex Automatons Across Queries

## Summary

Process-wide LRU cache for `CompiledAutomaton` objects keyed on `(pattern, syntaxFlags, matchFlags, determinizeWorkLimit)`. See [[22494-regex-cache]] for full root cause and PoC results (RegExp.toAutomaton ~47% CPU, p99 halved, hit rate 99.75-99.9% at 3K RPS).

## Files Changed (17, +862/-111)

- `server/src/main/java/org/opensearch/common/lucene/search/RegexpAutomatonCache.java` (new, 309 lines) — `CACHE_ENABLED_SETTING` (`search.regexp.automaton_cache.enabled`, default `false`, dynamic, node-scoped), `CACHE_MAX_SIZE_SETTING` (`search.regexp.automaton_cache.max_size_bytes`, default `50mb`, dynamic), `AtomicReference<Cache>`, `LongAdder` accumulators, warm resize.
- `server/src/main/java/org/opensearch/common/lucene/search/PrecompiledAutomatonQuery.java` (new, 99 lines) — `MultiTermQuery` wrapper for pre-built `CompiledAutomaton`.
- `server/src/main/java/org/opensearch/common/settings/ClusterSettings.java` — registers both settings.
- `server/src/main/java/org/opensearch/search/SearchService.java` — init from `Settings` + `addSettingsUpdateConsumer` for both.
- `server/src/main/java/org/opensearch/index/mapper/StringFieldType.java` — `regexpQuery` via `PrecompiledAutomatonQuery`.
- `server/src/main/java/org/opensearch/index/mapper/KeywordFieldMapper.java` — doc-values path, `rewriteForDocValue` cast.
- `server/src/main/java/org/opensearch/index/mapper/ConstantKeywordFieldMapper.java` — single-value path (see gap below).
- `server/src/main/java/org/opensearch/index/mapper/SemanticVersionFieldMapper.java` — same pattern as StringFieldType.
- `server/src/main/java/org/opensearch/index/query/RegexpQueryBuilder.java` — fallback path when no `MappedFieldType`.
- Tests: `server/src/test/java/org/opensearch/common/lucene/search/RegexpAutomatonCacheTests.java` (18 tests) + 5 mapper/builder tests.

## CI Status

All green on head `4d6f6013`: `gradle-check` pass (61m), `Validate` pass, `Code-Diff-Analyzer/Reviewer` pass, `codecov/patch` pass, `DCO` pass. `MERGEABLE`, state `OPEN`, `isDraft=true`, no review requests.

## Local Verification

Worktree `/tmp/pr22907-review`, Lucene 10.5.0 jar `javap` checks, 3 gap probes via `TestGaps.java` + `CacheGapsPrepareTests.java` (6 tests, 3 expected failures pre-fix, compile `BUILD SUCCESSFUL` in 19s). Details in [[22494-regex-cache]].

Gaps found:
- **HIGH** `ConstantKeywordFieldMapper.java:208` NPE on `".*"` → `ALL/null` (reproduced)
- **MEDIUM** `RegexpAutomatonCache.java:229` wraps `TooComplex` as `IllegalArgument` (reproduced with `"(.*a){20}"` limit 10)
- **LOW** stats race `resize`/`setEnabled` (snapshot+swap)

Fix snippets in `/tmp/gap-snippets-*.java`, draft comment at `/tmp/draft-pr22907-comment.md` (61 lines, not posted).

## Review Status

Draft, author iterating. Our review planned but not posted per user request. When author marks `ready_for_review`, post the two blocker comments.

## References

- [GitHub PR #22907](https://github.com/opensearch-project/OpenSearch/pull/22907)
- [[22494-regex-cache]]
- [Issue comment 2026-09-03](https://github.com/opensearch-project/OpenSearch/issues/22494#issuecomment-5521489666)
