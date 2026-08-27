---
type: architecture
tags: [opensearch, indexing, storage]
---

# Indexing Flow

How documents get from a REST request into the Lucene index.

## Indexing Path

```
Client → REST /_bulk or /{index}/_doc
  → ActionModule → BulkAction / IndexAction
  → TransportAction → BulkRequest / IndexRequest
  → DocumentMapper → ParsedDocument
  → IndexService → IndexingService
  → Engine → IndexWriter (Lucene)
  → Translog (WAL)
  → Refresh → Segment (visible to search)
```

## Key Steps

1. **Parse**: REST request parsed into `IndexRequest` or `BulkRequest`
2. **Map**: `DocumentMapper` converts JSON to `ParsedDocument`
3. **Validate**: Field types checked, mappings applied
4. **Write to engine**: `IndexingService` calls `Engine.index()`
5. **Lucene**: `IndexWriter.addDocument()` writes to an in-memory buffer
6. **Translog**: Write-ahead log for crash recovery
7. **Refresh**: Buffer flushed to a Lucene segment (visible to search)

## Key Classes

| Class | Role |
|-------|------|
| `IndexService` | Manages a single index |
| `IndexingService` | Handles indexing operations |
| `Engine` | Abstracts Lucene operations |
| `IndexWriter` | Lucene writer |
| `DocumentMapper` | JSON to document mapping |
| `Translog` | Write-ahead log |
| `MappingService` | Manages field mappings |

## Refresh

A refresh converts the in-memory buffer to a searchable segment. Default: every 1 second. This is why OpenSearch is "near real time" rather than "real time."

```java
// Manual refresh
client().admin().indices().prepareRefresh("my-index").get();
```

## Translog and Durability

The translog survives crashes. On recovery, the translog is replayed to restore uncommitted segments. The translog is flushed to disk on every `index` request (or on a time-based interval).

## Related

- [[query-flow]] — how indexed data gets searched
- [[server]] — where indexing classes live
- [[00-overview]] — top-level layout
