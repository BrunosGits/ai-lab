---
type: codebase
tags: [opensearch, structure]
---

# OpenSearch Top-Level Overview

GitHub: [opensearch-project/OpenSearch](https://github.com/opensearch-project/OpenSearch)
License: Apache 2.0
Language: Java (with some Rust in sandbox backends)
Build: Gradle

## Directory Layout

```
OpenSearch/
├── server/                 ← core search engine (Java)
│   └── src/main/java/org/opensearch/
│       ├── action/         ← action framework (transport actions)
│       ├── cluster/        ← cluster state, coordination
│       ├── common/         ← common utilities
│       ├── index/          ← indexing, engines, shard management
│       ├── indices/        ← index operations
│       ├── search/         ← search phases, query execution
│       ├── transport/      ← transport layer, streaming
│       ├── tasks/          ← task framework
│       ├── threadpool/     ← thread pool management
│       └── ...
├── client/                 ← REST high-level client
├── modules/                ← built-in modules (25 modules)
├── sandbox/                ← experimental features
│   ├── plugins/            ← sandbox plugins (analytics, datafusion, etc.)
│   ├── qa/                 ← sandbox integration tests
│   └── libs/               ← sandbox shared libraries
├── plugins/                ← official plugins (repository-s3, etc.)
├── qa/                     ← integration test suites
├── test/                   ← test framework (base classes)
├── buildSrc/               ← Gradle build logic
├── libs/                   ← shared libraries
├── benchmarks/             ← JMH microbenchmarks
├── distribution/           ← packaging (tar, zip, docker)
├── docs/                   ← documentation
└── gradle/                 ← Gradle wrapper
```

## Key Entry Points

- **REST layer**: `server/src/main/java/org/opensearch/rest/` — handles HTTP requests
- **Transport layer**: `server/src/main/java/org/opensearch/transport/` — node-to-node communication
- **Action framework**: `server/src/main/java/org/opensearch/action/` — request/response handling
- **Search**: `server/src/main/java/org/opensearch/search/` — query execution
- **Index engine**: `server/src/main/java/org/opensearch/index/engine/` — Lucene integration

## Related

- [[server]] — deep dive into the server module
- [[sandbox]] — experimental features
- [[modules]] — built-in modules
- [[build-system]] — how to build
- [[query-flow]] — how a query travels through this code
