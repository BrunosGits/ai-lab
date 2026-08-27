---
type: architecture
tags: [opensearch, search, query]
---

# Query Flow

How a search request travels through OpenSearch.

## Standard Search Path

```
Client → REST layer → ActionModule → TransportAction
  → SearchService → QueryPhase → FetchPhase
  → ShardSearch → IndexReader → Lucene
  → Response
```

### Step by Step

1. **REST layer** receives HTTP request (`/_search`)
2. **ActionModule** routes to the correct `TransportAction`
3. **SearchService** creates the search context
4. **QueryPhase** executes the query on each shard
5. **FetchPhase** retrieves the requested documents
6. **Results** are reduced at the coordinating node
7. **Response** is returned to the client

## Analytics Search Path (Sandbox)

```
Client → REST /_analytics/ppl → AnalyticsQueryAction
  → AnalyticsSearchService → StageExecution
  → Scatter/Gather → FetchByRowIds
  → DataFusion / Lucene backend
  → Response
```

### Key Differences

- Uses PPL (Piped Processing Language) instead of DSL
- Runs through the analytics engine, not the standard search service
- Uses streaming transport (Flight/Arrow) instead of regular transport
- Has stages: SHARD_FRAGMENT, COORDINATOR_REDUCE, LATE_MATERIALIZATION

## Key Classes

| Class | Role |
|-------|------|
| `SearchService` | Orchestrates search execution |
| `QueryPhase` | Executes the query |
| `FetchPhase` | Retrieves documents |
| `SearchContext` | Holds search state |
| `ShardSearchRequest` | Per-shard search request |
| `AnalyticsSearchService` | Analytics query execution (sandbox) |

## Related

- [[transport-layer]] — how requests move between nodes
- [[server]] — where these classes live
- [[sandbox]] — analytics engine specifics
- [[indexing-flow]] — how data gets in before queries come out
