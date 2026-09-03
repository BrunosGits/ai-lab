---
type: issue
number: 22494
title: Cache compiled regex automatons
status: open
project: opensearch
root-cause: Regexp queries recompile automaton (RegExp.toAutomaton → Operations.determinize → CompiledAutomaton) on every execution, even for identical patterns. Lucene AutomatonQuery rebuilds CompiledAutomaton unconditionally. Measurable ~47% query CPU on repeated patterns in production.
key-files:
  - server/src/main/java/org/opensearch/common/lucene/search/RegexpAutomatonCache.java
  - server/src/main/java/org/opensearch/common/lucene/search/PrecompiledAutomatonQuery.java
  - server/src/main/java/org/opensearch/index/mapper/StringFieldType.java
  - server/src/main/java/org/opensearch/index/mapper/KeywordFieldMapper.java
  - server/src/main/java/org/opensearch/index/mapper/ConstantKeywordFieldMapper.java
  - server/src/main/java/org/opensearch/index/mapper/SemanticVersionFieldMapper.java
  - server/src/main/java/org/opensearch/index/query/RegexpQueryBuilder.java
  - server/src/main/java/org/opensearch/search/SearchService.java
  - server/src/main/java/org/opensearch/common/settings/ClusterSettings.java
tags: [opensearch, issue, regex, caching, performance, lucene]
---

# Issue #22494: Cache Compiled Regex Automatons

## Summary

Every `regexp` query pays full automaton compilation cost even when the same pattern was compiled moments earlier on the same node. Compilation depends only on `(pattern, syntaxFlags, matchFlags, determinizeWorkLimit)`, not on the index, so a process-wide cache maximizes sharing. Issue has a production-tested PoC on 2.19 (RegExp.toAutomaton ~47% CPU, p99 halved after cache) and now a PR targeting main (3.9.0 / Lucene 10.5.1).

## Root Cause

- `RegexpQuery`/`AutomatonQuery` constructors unconditionally call `new RegExp(...).toAutomaton(provider)` → `Operations.determinize(..., limit)` → `new CompiledAutomaton(automaton, false, true, isBinary)`. `compiled` is `protected final` with no overload accepting a pre-built `CompiledAutomaton`.
- No caching layer; repeated patterns across shards/indices recompute identical `CompiledAutomaton` objects.

## Author PR

- **PR #22907** by @ZiwenWan — `zw/regexp-automaton-cache`, head `4d6f6013` (2026-09-01), **draft**, `MERGEABLE`, all CI green (`gradle-check` pass, `Validate` pass, `codecov/patch` pass). Resolves #22494.
- Design: process-wide LRU over `Cache<K,V>` / `CacheBuilder`, RAM-bounded via `CompiledAutomaton.ramBytesUsed()` (not entry-count), keyed on `(pattern, syntaxFlags, matchFlags, determinizeWorkLimit)`, `AtomicReference<Cache>` swap for resize/disable, `LongAdder` accumulators monotonic across swaps, warm resize (LRU-first copy preserves hot entries). Off by default, two dynamic node-scoped settings.

### Components in PR

- `RegexpAutomatonCache` — singleton, `CACHE_ENABLED_SETTING` (`search.regexp.automaton_cache.enabled`, default `false`, dynamic), `CACHE_MAX_SIZE_SETTING` (`search.regexp.automaton_cache.max_size_bytes`, default `50mb`, dynamic), wired in `SearchService` via `addSettingsUpdateConsumer` and registered in `ClusterSettings`.
- `PrecompiledAutomatonQuery extends MultiTermQuery` — accepts pre-built `CompiledAutomaton`, needed because `AutomatonQuery` rebuilds unconditionally. Delegates `getTermsEnum` → `compiled.getTermsEnum(terms)`, `visit` → `compiled.visit`.
- 5 call sites updated: `StringFieldType.regexpQuery()`, `RegexpQueryBuilder.doToQuery()` (fallback when no `MappedFieldType`), `KeywordFieldMapper` (doc-values path, uses `rewriteForDocValue`), `ConstantKeywordFieldMapper` (single-value `MatchAll/NoDocs` path), `SemanticVersionFieldMapper`.
- Tests: `RegexpAutomatonCacheTests` (18 tests, concurrent load, eviction, metrics, resize, provider bypass).

## Local Verification (worktree /tmp/pr22907-review, Lucene 10.5.0)

Gaps reproduced without posting:

- **Gap 2 — ConstantKeyword NPE (HIGH, reproduced):** `".*"` → `type=ALL, runAutomaton=null`, `""` → `SINGLE/null`, `".*.*"` → `ALL/null` (vs `a*` → `NORMAL/non-null`). Current `ConstantKeywordFieldMapper.java:208` `compiled.runAutomaton.run(...)` NPEs when `type != NORMAL`. Previous code used `new ByteRunAutomaton(automaton)` which never nulled. Fix: `switch(compiled.type)` → `ALL→MatchAllDocs`, `NONE→MatchNoDocs`, `SINGLE→term.equals`, `NORMAL→runAutomaton.run`.

- **Gap 1 — Exception wrapping (MEDIUM, reproduced):** `"(.*a){20}"` with `limit=10` → direct Lucene throws `TooComplexToDeterminizeException`, cache throws `IllegalArgumentException` at `RegexpAutomatonCache.java:229` (`throw new IllegalArgumentException(cause.getMessage(), cause)`). Local probes `CacheGapsPrepareTests`: 3/6 failed as expected (`testTooComplexNotWrappedAsIllegalArgument`, `testTooComplexWithDisabledCacheThrowsSameType`, `testHighLimitCachedDoesNotMaskLowLimitTooComplex`). Breaks callers expecting `TooComplex` (`QueryStringQueryBuilderTests:800,809,832`, `TextFieldTypeTests:284`). Preserving original `TooComplex` keeps contract with non-cached `RegexpQuery` path.

- **Gap 3 — desterminize limit in key (verified correct):** `Key` includes `determinizeWorkLimit` (hash includes all four fields). Same pattern with `high=10000` vs `low=10` are distinct entries (`count=2, assertNotSame`), so cached high does not mask low-limit `TooComplex`. Correct per Javadoc, intentional hit-rate trade-off.

- **CompiledAutomaton flags (verified):** PR `new CompiledAutomaton(det, false, true, false)` matches `AutomatonQuery` `new CompiledAutomaton(automaton, false, true, isBinary)` where `isBinary=false` for text/keyword fields (javap verified: `iconst_0, iconst_1, iload_3`).

- **Settings wiring (verified):** `ClusterSettings.java:889` + `SearchService.java:598-606` both registered and consumer-wired. `CACHE_ENABLED_SETTING.isDynamic()` true. Gradlew `:server:compileTestJava` and standalone `javac` both success.

Local snippets kept at `/tmp/gap-snippets-*.java` (6 tests), compiled `BUILD SUCCESSFUL` in 19s, draft comment at `/tmp/draft-pr22907-comment.md` (61 lines, not posted).

## What Was Done (us)

- Monitored issue since 2026-08-13, mapped code paths, coordinated with author (issue comments 2026-08-13, 2026-09-01).
- Pulled PR #22907 head, verified Lucene flags via `javap` on `lucene-core-10.5.0.jar`, checked `ClusterSettings`/`SearchService` wiring, audited all 5 call sites and `PrecompiledAutomatonQuery` parity with `AutomatonQuery`.
- Ran 3 gap probes locally (trivial-pattern NPE, TooComplex wrapping, distinct-limit keys) via standalone `TestGaps.java` and `CacheGapsPrepareTests` (6 tests, 3 failed as expected pre-fix). Prepared fix snippets for all three gaps, draft comment not posted.

## Remaining For Author Before ready_for_review

- Fix NPE guard in `ConstantKeywordFieldMapper`
- Preserve `TooComplexToDeterminizeException` type in `RegexpAutomatonCache.getCompiledAutomaton`
- Optional: `synchronized` on `resize`/`setEnabled` for stats monotonicity (low priority, stats-only)
- No CHANGELOG needed since 3.6 (release notes moved); docs for new settings can follow as `documentation-website` PR.

## References

- [GitHub Issue #22494](https://github.com/opensearch-project/OpenSearch/issues/22494)
- [Issue comment 2026-09-03 — author confirms 5 call sites, wildcards scoped out](https://github.com/opensearch-project/OpenSearch/issues/22494#issuecomment-5521489666)
- [GitHub PR #22907](https://github.com/opensearch-project/OpenSearch/pull/22907)
- [Roadmap entry](../ROADMAP.md)
- Local: `/tmp/pr22907-review` worktree, `/tmp/gap-snippets-*`, `/tmp/draft-pr22907-comment.md`
