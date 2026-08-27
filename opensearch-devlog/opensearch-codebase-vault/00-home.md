---
type: home
tags: [opensearch, vault]
---

# OpenSearch Codebase Vault

A study vault for understanding the OpenSearch codebase, tracking issues, and managing contributions.

## Codebase Map

- [[00-overview]] — top-level directory layout
- [[server]] — core server module
- [[sandbox]] — experimental features (analytics engine, datafusion)
- [[modules]] — built-in modules (painless, ingest, reindex)
- [[client]] — REST high-level client
- [[test-framework]] — test base classes
- [[build-system]] — Gradle, buildSrc, how to build

## Architecture

- [[query-flow]] — how a search request travels through the code
- [[transport-layer]] — transport, streaming, wire format
- [[plugin-system]] — how plugins register and extend core
- [[indexing-flow]] — how documents get indexed

## Active Issues

- [[17561-codec-error]] — inaccurate codec error message (PR submitted)
- [[22706-flaky-test]] — flaky AnalyticsQueryTaskCleanupIT (PR submitted)
- [[22676-lm-profile]] — LATE_MATERIALIZATION profile metrics (reviewed)
- [[22654-monitor-mode]] — MONITOR mode workload group rejections (helped)
- [[6323-long-strings]] — long strings cut at 2000 characters (investigating)
- [[22494-regex-cache]] — cache compiled regex automatons (monitoring)

## Pull Requests

- [[22749-codec-error-message]] — fix codec error message (CI green, awaiting review)
- [[22750-flaky-test-fix]] — fix flaky test (CI green, awaiting review)

## Contributing

- [[00-contributing-guide]] — key rules from CONTRIBUTING.md
- [[testing-patterns]] — which test base class to use
- [[commands]] — useful gradle, git, gh commands
- [[labels]] — what labels mean on issues and PRs

## People

- [[maintainers]] — who to contact
- [[contributors]] — people we interacted with

## Templates

- [[issue-template]] — for new issue notes
- [[pr-template]] — for new PR notes
- [[session-template]] — for new session notes
