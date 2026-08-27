---
type: codebase
module: modules
tags: [opensearch, modules]
---

# Core Modules

Built-in modules that ship with OpenSearch. Located in `modules/`.

Path: `modules/`

## Module List

| Module | Purpose |
|--------|---------|
| `lang-painless` | Painless scripting language |
| `lang-expression` | Expression scripting language |
| `lang-mustache` | Mustache templating |
| `reindex` | Reindex API |
| `ingest-common` | Common ingest processors |
| `ingest-geoip` | GeoIP ingest processor |
| `ingest-user-agent` | User agent ingest processor |
| `analysis-common` | Common analysis plugins |
| `mapper-extras` | Extra field mappers |
| `parent-join` | Parent-child relationships |
| `percolator` | Percolate queries |
| `rank-eval` | Rank evaluation |
| `aggs-matrix-stats` | Matrix aggregation stats |
| `cache-common` | Common caching |
| `concurrency-limit` | Concurrency limiting |
| `geo` | Geo utilities |
| `search-pipeline-common` | Search pipeline common code |
| `transport-netty4` | Netty4 transport |
| `transport-grpc` | gRPC transport |
| `repository-url` | URL-based snapshot repository |
| `store-subdirectory` | Subdirectory store |
| `systemd` | Systemd integration |
| `opensearch-dashboards` | Dashboards compatibility |
| `autotagging-commons` | Auto-tagging |
| `build.gradle` | Module build configuration |

## How Modules Differ from Plugins

Modules are bundled with OpenSearch. Plugins are installed separately. Modules can use internal APIs that plugins cannot.

## Related

- [[00-overview]] — top-level layout
- [[plugin-system]] — how modules and plugins register
- [[sandbox]] — experimental modules
