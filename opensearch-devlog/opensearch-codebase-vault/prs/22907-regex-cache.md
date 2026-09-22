---
type: pr
number: 22907
title: Cache compiled regex automatons across queries
status: draft
issue: 22494
ci: green (GH gradle-check pass, Jenkins SUCCESS, Validate, codecov, DCO)
review: posted — all 3 findings fixed by author, acknowledgement posted, track closed
base: main (3.9.0 / Lucene 10.5.1)
head: 107fdbf (zw/regexp-automaton-cache, 2026-09-20)
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

All green on head `107fdbf`: GH `gradle-check` pass (~60m), Jenkins `gradle-check/85159` SUCCESS (previous head `bb8b7d8` was UNSTABLE = flakes passed on retry; `a3566bab` FAILED on Jenkins 84790). `Validate`, `Code-Diff-Analyzer/Reviewer`, `codecov/patch`, `DCO` pass. `MERGEABLE`, state `OPEN`, `isDraft=true`, `REVIEW_REQUIRED`.

## Local Verification

Probed head `a3566bab` in worktree `/tmp/pr22907-failing` (deleted during VPS disk cleanup): 9 targeted shards all `BUILD SUCCESSFUL`; 3 gap probes reproduced pre-fix (NPE on `".*"`, `TooComplex` wrap with `"(.*a){20}"` limit 10). Re-verified `bb8b7d8` by code inspection (blocker lines identical, Lucene 10.5.1 on both heads) — re-run deemed unnecessary. Details in [[22494-regex-cache]].

Gaps found, all fixed by author in `bb8b7d8` → `107fdbf`:
- **HIGH** `ConstantKeywordFieldMapper` NPE on `".*"` → `ALL/null` (reproduced) → fixed via `switch (compiled.type)` (ALL→match-all, NONE→match-none, SINGLE→term compare, `runAutomaton` only in `default`)
- **MEDIUM** `RegexpAutomatonCache` wrapped `TooComplex` as `IllegalArgument` (reproduced) → fixed, now propagates `TooComplexToDeterminizeException` unwrapped
- **LOW** stats race `resize`/`setEnabled` → fixed via `snapshotStats()` + `LongAdder` accumulators

## Review Status

Review posted 2026-09-18 (all 3 findings + Jenkins UNSTABLE flake note), acknowledgement posted 2026-09-22 after author fixed everything in `107fdbf`. Track closed from our side; remaining: author undrafts + maintainer review.

## References

- [GitHub PR #22907](https://github.com/opensearch-project/OpenSearch/pull/22907)
- [[22494-regex-cache]]
- [Issue comment 2026-09-03](https://github.com/opensearch-project/OpenSearch/issues/22494#issuecomment-5521489666)
