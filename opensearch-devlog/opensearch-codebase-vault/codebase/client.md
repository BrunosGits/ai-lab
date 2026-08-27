---
type: codebase
module: client
tags: [opensearch, client]
---

# Client Module

REST high-level client for interacting with OpenSearch.

Path: `client/`

## Key Packages

| Package | Purpose |
|---------|---------|
| `rest-high-level` | High-level REST client |
| `rest-high-level/src/test/` | Client tests (including security/PKI test certs) |

## Usage

The high-level REST client wraps the low-level REST client and provides Java methods for all API operations:

```java
RestHighLevelClient client = new RestHighLevelClient(
    RestClient.builder(new HttpHost("localhost", 9200))
);

SearchRequest request = new SearchRequest("my-index");
SearchResponse response = client.search(request, RequestOptions.DEFAULT);
```

## Notes

- The client is being replaced by the new Java client in `client/rest-client/`
- Test resources include PKI certs (ca.p12, ca.pem, .key files) which are test data, not real secrets
- The client module is in `client/rest-high-level/`

## Related

- [[00-overview]] — top-level layout
- [[transport-layer]] — how the client communicates with nodes
