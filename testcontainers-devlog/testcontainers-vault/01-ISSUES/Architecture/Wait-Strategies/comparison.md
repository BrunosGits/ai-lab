# Comparison: Wait Strategies

## Cross-Language Comparison

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Abstraction** | Interface | Enum | Abstract Base Class |
| **Implementations** | 8+ classes | 7 enum variants | 4 base classes |
| **Extensibility** | New class | New variant (breaking) | Subclass |
| **Composite** | CompositeWaitStrategy | Manual | CustomWaitStrategy |
| **Timeout** | Per-strategy | Duration variant | Custom |
| **Async Support** | Sync only | Native async | Sync |

## Detailed Comparison

### Extensibility

| Language | Mechanism | Pros | Cons |
|----------|-----------|------|------|
| Java | New class implementing WaitStrategy | Open/closed principle | More boilerplate |
| Rust | New enum variant | Exhaustive matching | Breaking change |
| Python | Subclass WaitStrategy | Simple | Dynamic typing |

### Composite Strategies

| Language | Mechanism |
|----------|-----------|
| Java | `CompositeWaitStrategy` with AND/OR logic |
| Rust | Manual combination in custom predicate |
| Python | `CustomWaitStrategy` with compound predicate |

### Async Support

| Language | Support |
|----------|---------|
| Java | Sync only (blocking calls) |
| Rust | Native async/await |
| Python | Sync (asyncio via run_in_executor) |

### Composite Strategy Example

**Java:**
```java
WaitStrategy composite = new CompositeWaitStrategy(
    CompositeWaitStrategy.Composition.AND,
    new LogMessageWaitStrategy("Ready"),
    new PortWaitStrategy(8080)
);
```

**Rust:**
```rust
let combined = WaitFor::Custom {
    f: Box::new(move || {
        check_log_message() && check_port(8080)
    }),
};
```

**Python:**
```python
combined = CustomWaitStrategy(
    lambda c: c.logs().find("Ready") != -1 and c.get_exposed_port(8080) is not None
)
```

## Key Differences

| Aspect | Java | Rust | Python |
|--------|------|------|--------|
| **Type Safety** | Interface + implementations | Exhaustive enum matching | ABC + dynamic |
| **Composite** | First-class | Manual | Via CustomWaitStrategy |
| **Async** | No | Yes | Via asyncio |
| **Timeout** | Per-strategy | Duration variant | Manual |
| **Testing** | JUnit per strategy | Unit test per variant | pytest per class |

## Key Takeaways

| Aspect | Best Practice |
|--------|---------------|
| **Java** | Use CompositeWaitStrategy for complex conditions |
| **Rust** | Prefer enum variants for exhaustive matching |
| **Python** | Subclass WaitStrategy for custom logic |

## Recommendations

1. **Java**: Use `CompositeWaitStrategy` for complex conditions
2. **Rust**: Add new variants carefully (breaking change)
3. **Python**: Use `CustomWaitStrategy` for complex logic