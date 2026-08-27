---
type: codebase
module: test
tags: [opensearch, testing]
---

# Test Framework

Base classes and utilities for testing OpenSearch.

Path: `test/framework/src/main/java/org/opensearch/test/`

## Base Classes

| Class | Use When |
|-------|----------|
| `OpenSearchTestCase` | Unit tests. No cluster, no network. Fast. |
| `OpenSearchIntegTestCase` | Integration tests. Spins up a local cluster. |
| `OpenSearchRestTestCase` | REST endpoint tests. Uses HTTP client. |
| `ClientYamlTestSuiteIT` | YAML-based REST integration tests. |

## Which One to Use

From [[00-contributing-guide]]:

- **Unit tests** (most common): Extend `OpenSearchTestCase`. Test a single class in isolation.
- **Integration tests**: Extend `OpenSearchIntegTestCase`. Need a running cluster.
- **REST tests**: Extend `OpenSearchRestTestCase`. Test HTTP endpoints.
- **YAML tests**: Use `ClientYamlTestSuiteIT`. Write tests in YAML format.

## Key Utilities

- `MockTransportService` — mock transport for testing
- `TestThreadPool` — thread pool for tests
- `IndexSettings` — test index settings
- `ESTestCase` — base for Elasticsearch-compatible tests

## Common Patterns

```java
// Unit test
public class MyTests extends OpenSearchTestCase {
    public void testSomething() {
        // no cluster needed
    }
}

// Integration test
public class MyIT extends OpenSearchIntegTestCase {
    public void testSomething() {
        // cluster is running
        client().prepareSearch("my-index").get();
    }
}
```

## Related

- [[00-overview]] — top-level layout
- [[00-contributing-guide]] — testing rules
- [[commands]] — how to run tests
