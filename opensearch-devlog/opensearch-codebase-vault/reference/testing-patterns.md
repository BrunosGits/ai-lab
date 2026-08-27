---
type: reference
tags: [opensearch, testing, patterns]
---

# Testing Patterns

Which test base class to use and how to write tests in OpenSearch.

## Base Classes

| Class | Use When | Cluster? | Speed |
|-------|----------|----------|-------|
| `OpenSearchTestCase` | Unit tests | No | Fast |
| `OpenSearchIntegTestCase` | Integration tests | Yes | Slow |
| `OpenSearchRestTestCase` | REST endpoint tests | Yes | Slow |
| `ClientYamlTestSuiteIT` | YAML REST tests | Yes | Slow |

## Unit Tests (Most Common)

```java
import org.opensearch.test.OpenSearchTestCase;

public class MyTests extends OpenSearchTestCase {
    public void testSomething() {
        // no cluster needed
        assertEquals(2, 1 + 1);
    }
    
    public void testWithMocking() {
        // can use mocks
        TransportService mock = mock(TransportService.class);
        when(mock.getLocalNode()).thenReturn(node);
    }
}
```

## Integration Tests

```java
import org.opensearch.test.OpenSearchIntegTestCase;

@ClusterScope(scope = Scope.SUITE, numDataNodes = 2)
public class MyIT extends OpenSearchIntegTestCase {
    public void testSearch() {
        // cluster is running with 2 data nodes
        client().prepareSearch("my-index")
            .setQuery(QueryBuilders.matchAllQuery())
            .get();
    }
}
```

## REST Tests

```java
import org.opensearch.test.rest.OpenSearchRestTestCase;

public class MyRestIT extends OpenSearchRestTestCase {
    public void testEndpoint() throws IOException {
        Request request = new Request("GET", "/my-index/_search");
        Response response = client().performRequest(request);
        assertEquals(200, response.getStatusLine().getStatusCode());
    }
}
```

## Common Patterns

### Randomized Testing

OpenSearch uses randomized testing. Don't use `java.util.Random` directly:

```java
// Bad
Random rand = new Random();
int value = rand.nextInt(100);

// Good
int value = randomInt(99);
String index = randomAlphaOfLength(10);
```

### Test Resources

Put test resources in `src/test/resources/`. They're loaded via classpath.

### Assertions

Use OpenSearch assertions, not JUnit:

```java
// Bad
assertTrue(a == b);

// Good
assertEquals(a, b);
assertNotNull(result);
assertTrue("error message", condition);
```

## Flaky Tests

From [[00-contributing-guide]]:

If a test fails in CI but not locally:

1. Check if there's an existing issue for it
2. Run the test locally multiple times
3. If unrelated to your change, open a bug with `flaky-test` label
4. Comment on your PR referencing the issue

## Related

- [[commands]] — how to run tests
- [[00-contributing-guide]] — testing rules
- [[test-framework]] — test framework codebase
