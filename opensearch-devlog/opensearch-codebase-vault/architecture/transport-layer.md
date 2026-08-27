---
type: architecture
tags: [opensearch, transport, networking]
---

# Transport Layer

How nodes communicate with each other and how clients talk to nodes.

## Two Transport Systems

### 1. Standard Transport (server module)

Path: `server/src/main/java/org/opensearch/transport/`

- TCP-based, binary protocol
- Used for cluster internal communication
- Request/response model
- `TransportService` dispatches requests to handlers

### 2. Streaming Transport (sandbox)

Path: `sandbox/plugins/analytics-engine/`

- Arrow Flight / gRPC based
- Used for analytics query data transfer
- Streaming model (batches of record batches)
- `StreamTransportService` handles streaming connections

## Wire Format

### Standard Transport

Objects implement `Writeable` and serialize with `StreamOutput`/`StreamInput`:

```java
// Write
out.writeString(value);
out.writeLong(number);

// Read
this.value = in.readString();
this.number = in.readLong();
```

### Streaming Transport (Analytics)

Errors cross the wire as `StreamException` with a `StreamErrorCode`:

```java
// Production: wraps errors before sending
AnalyticsTransportErrors.toWireError(exception)

// Wire form
new StreamException(StreamErrorCode.CANCELLED, "message")

// Receiver: unwraps
AnalyticsTransportErrors.fromWireError(exception)
```

**Important**: Sending a raw `TaskCancelledException` on a streaming channel gets silently swallowed. Must use `StreamException`. This was the root cause of [[22706-flaky-test]].

## BWC Considerations

From [[00-contributing-guide]]:
- Wire format changes need version gates
- `FetchByRowIdsRequest` currently reads/writes `profile` without a version check (tracked in [#22822](https://github.com/opensearch-project/OpenSearch/issues/22822))
- Sandbox has no BWC guarantees currently

## Key Classes

| Class | Role |
|-------|------|
| `TransportService` | Routes requests to handlers |
| `TransportRequest` | Base class for requests |
| `TransportResponse` | Base class for responses |
| `StreamTransportService` | Streaming transport (analytics) |
| `StreamException` | Wire-form error for streaming |
| `StreamErrorCode` | Error classification enum |

## Related

- [[server]] — transport lives here
- [[sandbox]] — streaming transport for analytics
- [[query-flow]] — how queries use transport
- [[plugin-system]] — plugins register transport handlers
