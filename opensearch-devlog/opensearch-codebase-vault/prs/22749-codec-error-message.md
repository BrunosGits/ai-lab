---
type: pr
number: 22749
title: Fix inaccurate codec error message
status: open
issue: 17561
ci: green (all checks passed)
review: awaiting review
tags: [opensearch, pr, codec, error-message]
---

# PR #22749: Fix Inaccurate Codec Error Message

## Summary

Fixed the error message in `EngineConfig.createCodecFactory()` to say "not supported for index version X" instead of "failed to find codec X". The codec exists, it just isn't registered for the index's version.

## Files Changed

- `server/src/main/java/org/opensearch/index/engine/EngineConfig.java` — updated error message
- `server/src/test/java/org/opensearch/index/engine/EngineConfigTests.java` — added unit tests

## CI Status

All checks passed including `gradle-check`. CI is green.

## Review Status

Awaiting maintainer review.

## References

- [GitHub PR](https://github.com/opensearch-project/OpenSearch/pull/22749)
- [Issue #17561](https://github.com/opensearch-project/OpenSearch/issues/17561)
- [[17561-codec-error]]
