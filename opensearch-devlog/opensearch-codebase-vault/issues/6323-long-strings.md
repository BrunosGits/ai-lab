---
type: issue
number: 6323
title: Long strings cut at 2000 characters
status: open
project: opensearch
root-cause: Some string serialization in the transport layer truncates strings at 2000 characters. This affects large field values and error messages.
key-files: []
tags: [opensearch, issue, transport, string-serialization]
---

# Issue #6323: Long Strings Cut at 2000 Characters

## Summary

When strings exceed 2000 characters, they get silently truncated. This affects field values, error messages, and any data that passes through the transport layer.

## Root Cause

The transport layer's string serialization has a 2000 character limit somewhere in the write/read path. The exact location needs investigation.

## What Was Done

- Investigated the issue
- Found references in ROADMAP.md
- No PR submitted yet

## Investigation Notes

- The truncation happens in the transport layer's string serialization
- Need to find the exact location in `StreamOutput.writeString()` or related methods
- May be related to how Netty buffers are managed

## References

- [GitHub Issue](https://github.com/opensearch-project/OpenSearch/issues/6323)
- [Roadmap entry](../ROADMAP.md)
