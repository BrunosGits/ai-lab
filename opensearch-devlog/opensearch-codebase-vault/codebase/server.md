---
type: codebase
module: server
tags: [opensearch, server, core]
---

# Server Module

The core of OpenSearch. Everything runs here.

Path: `server/src/main/java/org/opensearch/`

## Key Packages

| Package | Purpose |
|---------|---------|
| `action/` | Action framework, transport actions, task management |
| `cluster/` | Cluster state, coordination, master election |
| `common/` | Utilities, settings, collections |
| `index/` | Indexing, engines, shard management, translog |
| `indices/` | Index operations (recovery, refresh, flush) |
| `search/` | Search phases, query execution, aggregations |
| `transport/` | Transport layer, streaming, wire format |
| `tasks/` | Task framework (long-running operations) |
| `threadpool/` | Thread pool management |
| `http/` | HTTP server, REST dispatch |
| `gateway/` | Persistent storage, index recovery |
| `discovery/` | Node discovery, cluster formation |
| `plugins/` | Plugin loading and lifecycle |
| `script/` | Script execution (painless, expression) |
| `monitor/` | Monitoring and telemetry |
| `repositories/` | Snapshot repositories |
| `snapshots/` | Snapshot and restore |

## Key Classes

- `OpenSearchServer` — main node lifecycle
- `IndicesService` — manages all indices on a node
- `SearchService` — executes search requests
- `TransportService` — handles node-to-node communication
- `ClusterService` — cluster state management
- `ActionModule` — registers all REST actions and transport actions

## How It Fits

The server module is the foundation. Everything else (modules, plugins, sandbox) extends it through the [[plugin-system]].

## Related

- [[00-overview]] — top-level layout
- [[transport-layer]] — transport deep dive
- [[query-flow]] — how queries travel through the server
- [[plugin-system]] — how plugins extend the server
