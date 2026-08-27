---
type: issue
number: 17561
title: Inaccurate error message for unsupported codecs
status: open
project: opensearch
root-cause: When a codec isn't registered for an index version, the error message says "failed to find codec" even though the codec exists, it just isn't registered for that version.
key-files:
  - server/src/main/java/org/opensearch/index/engine/EngineConfig.java
  - server/src/test/java/org/opensearch/index/engine/EngineConfigTests.java
tags: [opensearch, issue, codec, error-message]
---

# Issue #17561: Inaccurate Error Message for Unsupported Codecs

## Summary

When opening an index with a codec not registered for that version, the error message says "failed to find codec X". The codec exists, it just isn't registered for the index's version. The message should clarify this.

## Root Cause

In `EngineConfig.createCodecFactory()`, when `CodecLoader` can't find a codec for the index version, it throws an exception. The error message doesn't distinguish between "codec doesn't exist" and "codec exists but isn't registered for this version."

## Key Files

- `EngineConfig.java` — where the codec is loaded and the error is thrown
- `EngineConfigTests.java` — unit tests for the codec loading logic

## What Was Done

- Fixed the error message to say "not supported for index version X" instead of "failed to find codec X"
- Added unit tests to verify the new message
- PR: [[22749-codec-error-message]]

## Related PRs

- [[22749-codec-error-message]]

## References

- [GitHub Issue](https://github.com/opensearch-project/OpenSearch/issues/17561)
- [Roadmap entry](../ROADMAP.md)
