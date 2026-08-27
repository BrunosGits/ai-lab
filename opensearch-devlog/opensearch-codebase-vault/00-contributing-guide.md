---
type: reference
tags: [opensearch, contributing, rules]
---

# Contributing Guide

Key rules extracted from [CONTRIBUTING.md](https://github.com/opensearch-project/OpenSearch/blob/main/CONTRIBUTING.md).

## Before You Start

1. **Open an issue first.** Even if you know the solution, write down the problem. It gives reviewers context and prevents duplicate work.
2. **Submit only your own work.** You'll sign a DCO (Developer Certificate of Origin) with every commit.

## DCO Sign-off

Every commit must include:

```
Signed-off-by: Your Name <your@email.com>
```

Use `git commit -s` to add this automatically. Your git user.name and user.email must be set correctly.

## Backwards Compatibility (BWC)

The first review cycle focuses on public-facing APIs. These must not break across major versions.

**Minimize BWC guarantees** for early PRs. If a feature is experimental or sandboxed, say so.

## Feature Flags

Features behind feature flags are more likely to be merged and backported. They add a layer of protection.

See [example PR #4959](https://github.com/opensearch-project/OpenSearch/pull/4959) for implementation.

## Java Tags

- `@opensearch.internal` — internal classes, subject to rapid changes
- `@opensearch.api` — public-facing API with BWC guarantees
- `@opensearch.experimental` — rapidly changing experimental code

## Sandbox

Significant core changes (search phases, codecs, specialized Lucene APIs) are more likely to merge if sandboxed. Sandbox is disabled by default, enabled with `-Dsandbox.enabled=true`.

## Testing

Use the right base class:

- [[testing-patterns]] for details

| Test Type | Base Class |
|-----------|-----------|
| Unit tests | `OpenSearchTestCase` |
| Integration/cluster tests | `OpenSearchIntegTestCase` |
| REST endpoint tests | `OpenSearchRestTestCase` |
| REST integration (YAML) | `ClientYamlTestSuiteIT` |

## Flaky Tests

If a test fails in CI but not locally:

1. Check if there's an existing issue for it
2. Run the test locally multiple times
3. If unrelated to your change, open a bug with `flaky-test` label
4. Comment on your PR referencing the issue

## Microbenchmarks

For critical path changes (GC, heap, direct memory, CPU), include a [microbenchmark](https://github.com/opensearch-project/OpenSearch/tree/main/benchmarks) with JFR or flamegraph results in the PR description.

## PR Tips

- Smaller PRs review faster
- Respond to comments promptly
- If you stop responding, the PR may be closed as abandoned
- Maintainers handle backporting after merge
