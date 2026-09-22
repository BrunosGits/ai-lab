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

- **PR #22907** by @ZiwenWan — `zw/regexp-automaton-cache`, head `107fdbf` (2026-09-20), **draft**, `MERGEABLE`, all CI green (GH `gradle-check` pass, Jenkins SUCCESS). Resolves #22494.
- Design: process-wide LRU over `Cache<K,V>` / `CacheBuilder`, RAM-bounded via `CompiledAutomaton.ramBytesUsed()` (not entry-count), keyed on `(pattern, syntaxFlags, matchFlags, determinizeWorkLimit)`, `AtomicReference<Cache>` swap for resize/disable, `LongAdder` accumulators monotonic across swaps, warm resize (LRU-first copy preserves hot entries). Off by default, two dynamic node-scoped settings.

### Components in PR

- `RegexpAutomatonCache` — singleton, `CACHE_ENABLED_SETTING` (`search.regexp.automaton_cache.enabled`, default `false`, dynamic), `CACHE_MAX_SIZE_SETTING` (`search.regexp.automaton_cache.max_size_bytes`, default `50mb`, dynamic), wired in `SearchService` via `addSettingsUpdateConsumer` and registered in `ClusterSettings`.
- `PrecompiledAutomatonQuery extends MultiTermQuery` — accepts pre-built `CompiledAutomaton`, needed because `AutomatonQuery` rebuilds unconditionally. Delegates `getTermsEnum` → `compiled.getTermsEnum(terms)`, `visit` → `compiled.visit`.
- 5 call sites updated: `StringFieldType.regexpQuery()`, `RegexpQueryBuilder.doToQuery()` (fallback when no `MappedFieldType`), `KeywordFieldMapper` (doc-values path, uses `rewriteForDocValue`), `ConstantKeywordFieldMapper` (single-value `MatchAll/NoDocs` path), `SemanticVersionFieldMapper`.
- Tests: `RegexpAutomatonCacheTests` (18 tests, concurrent load, eviction, metrics, resize, provider bypass).

## Local Verification (probed `a3566bab`, re-verified `bb8b7d8` by inspection)

Gaps found, all fixed by author in `bb8b7d8` → `107fdbf`:

- **Gap 2 — ConstantKeyword NPE (HIGH, reproduced, fixed):** `".*"` → `type=ALL, runAutomaton=null`. Fixed via `switch(compiled.type)` → `ALL→MatchAllDocs`, `NONE→MatchNoDocs`, `SINGLE→term.equals`, `runAutomaton.run` only in `default`.

- **Gap 1 — Exception wrapping (MEDIUM, reproduced, fixed):** `"(.*a){20}"` with `limit=10` → cache threw `IllegalArgumentException` instead of Lucene's `TooComplexToDeterminizeException`. Fixed: `TooComplex` now propagates unwrapped.

- **Gap 3 — determinize limit in key (verified correct):** `Key` includes `determinizeWorkLimit`; high-limit cached entries do not mask low-limit `TooComplex`. Correct per Javadoc.

- **CompiledAutomaton flags (verified):** PR `new CompiledAutomaton(det, false, true, false)` matches `AutomatonQuery` flags for text/keyword fields (`isBinary=false`).

- **Settings wiring (verified):** both settings registered in `ClusterSettings` and consumer-wired in `SearchService`, dynamic.

Local probe files (`/tmp/gap-snippets-*`, draft comment) deleted during VPS disk cleanup; findings live on in the posted review.

## What Was Done (us)

- Monitored issue since 2026-08-13, mapped code paths, coordinated with author (issue comments 2026-08-13, 2026-09-01).
- Pulled PR #22907 head, verified Lucene flags via `javap` on `lucene-core-10.5.0.jar`, checked `ClusterSettings`/`SearchService` wiring, audited all 5 call sites and `PrecompiledAutomatonQuery` parity with `AutomatonQuery`.
- Ran 3 gap probes locally plus 9 targeted test shards on `a3566bab` (all green); re-verified `bb8b7d8` by code inspection (blocker lines identical, Lucene 10.5.1 both heads). Posted full review 2026-09-18, acknowledgement 2026-09-22 after author fixed everything. Track closed from our side.

## Remaining For Author Before ready_for_review

All done (NPE switch, `TooComplex` passthrough, stats accumulators). Left: undraft + maintainer review. No CHANGELOG needed since 3.6; docs for new settings can follow as `documentation-website` PR.

## References

- [GitHub Issue #22494](https://github.com/opensearch-project/OpenSearch/issues/22494)
- [Issue comment 2026-09-03 — author confirms 5 call sites, wildcards scoped out](https://github.com/opensearch-project/OpenSearch/issues/22494#issuecomment-5521489666)
- [GitHub PR #22907](https://github.com/opensearch-project/OpenSearch/pull/22907)
- [Roadmap entry](../ROADMAP.md)
