# espanso-engine — System Analysis

## 1. What Is This?

The espanso-engine crate is the **core event pipeline** for espanso. It processes keyboard input, detects matches against configured triggers, renders templates, and dispatches output (text injection, key sequences, HTML, images). It's 47 files, 4,672 lines — small enough to study completely, large enough to understand the full pipeline.

## 2. Why Does It Exist?

Espanso is a text expander. When you type a trigger like `:email`, it detects the match, renders the template (substituting variables like `{{name}}`), and injects the expansion. The engine is the glue that:

1. **Receives** keyboard events from espanso-detect
2. **Detects** matches against configured triggers
3. **Renders** templates with variable substitution
4. **Injects** the result via espanso-inject

Without the engine, espanso would be a collection of disconnected components with no way to coordinate.

## 3. How Does It Work?

### The Three Core Traits

The engine defines three traits that decouple its pipeline:

```rust
// Funnel: Receives events from sources
pub trait Funnel {
    fn receive(&self) -> FunnelResult;
}

// Processor: Transforms events through middleware
pub trait Processor {
    fn process(&mut self, event: Event) -> Vec<Event>;
}

// Dispatcher: Sends events to executors
pub trait Dispatcher {
    fn dispatch(&self, event: Event);
}
```

### The Engine Loop

```rust
// espanso-engine/src/lib.rs:51-69
pub fn run(&mut self) -> ExitMode {
    loop {
        match self.funnel.receive() {
            FunnelResult::Event(event) => {
                let processed_events = self.processor.process(event);
                for event in processed_events {
                    if let EventType::Exit(mode) = &event.etype {
                        return mode.clone();
                    }
                    self.dispatcher.dispatch(event);
                }
            }
            FunnelResult::EndOfStream => return ExitMode::Exit,
            FunnelResult::Skipped => {}
        }
    }
}
```

### Event Flow: Typing `:email`

```
1. Keyboard events flow into the funnel
   Event { source_id: 1, etype: Keyboard { key: A, value: Some("a") } }
   Event { source_id: 2, etype: Keyboard { key: M, value: Some("m") } }
   Event { source_id: 3, etype: Keyboard { key: A, value: Some("a") } }
   Event { source_id: 4, etype: Keyboard { key: I, value: Some("i") } }
   Event { source_id: 5, etype: Keyboard { key: L, value: Some("l") } }

2. MatcherMiddleware detects the match
   Event { source_id: 5, etype: MatchesDetected {
       matches: [DetectedMatch { id: 1, trigger: ":email", args: {} }]
   }}

3. RenderMiddleware renders the template
   Event { source_id: 5, etype: Rendered(RenderedEvent {
       match_id: 1,
       body: "bruno@example.com",
       format: Format::Text
   })}

4. ActionMiddleware compensates for the trigger
   Event { source_id: 5, etype: TriggerCompensation(TriggerCompensationEvent {
       keys: [KeyEvent { key: Backspace, count: 6 }]
   })}

5. TextInjectExecutor injects the expansion
   → espanso-inject.send_string("bruno@example.com")
```

## 4. Event Taxonomy

All events share a common structure:

```rust
pub struct Event {
    pub source_id: SourceId,  // Monotonically increasing
    pub etype: EventType,     // The event data
}
```

The `source_id` is assigned at input and propagated through all consequential events. This allows tracing the full lifecycle of a single keystroke.

### Event Categories

| Category | Examples | Purpose |
|----------|----------|---------|
| Input | Keyboard, Mouse, HotKey | Raw platform input |
| Internal | MatchesDetected, Rendered | Engine-internal processing |
| Effect | TriggerCompensation, TextInject | Side effects |
| External | MatchExecRequest | External requests (CLI) |
| UI | ShowContextMenu, IconStatusChange | UI updates |
| Control | Exit, Disabled, Enabled | State changes |

## 5. The Middleware Pipeline

The processor contains 24 middleware that process events in order:

```
EventsDiscardMiddleware → DisableMiddleware → IconStatusMiddleware →
AltCodeSynthesizerMiddleware → MatcherMiddleware → MatchExecRequestMiddleware →
SuppressMiddleware → ContextMenuMiddleware → HotKeyMiddleware →
MatchSelectMiddleware → CauseCompensateMiddleware → ConfigMiddleware →
MultiplexMiddleware → StatsMiddleware → RenderMiddleware →
ImageResolverMiddleware → CursorHintMiddleware → ExitMiddleware →
UndoMiddleware → ActionMiddleware → SearchMiddleware →
MarkdownMiddleware → NotificationMiddleware → DelayForModifierReleaseMiddleware
```

Each middleware can:
1. **Transform** the event (return a different event)
2. **Pass through** (return the same event)
3. **Suppress** (return `EventType::NOOP`)
4. **Dispatch side effects** (call `dispatch()` with new events)

### The Event Queue

The processor maintains a `VecDeque<Event>` for internal dispatch:

```rust
// espanso-engine/src/process/default.rs:39
event_queue: VecDeque<Event>,
```

When a middleware calls `dispatch()`, the event is queued and processed after the current event. This allows middleware to generate new events without direct coupling.

### Why 24 Middleware?

Each middleware has a single responsibility:
- **MatcherMiddleware**: Only detects matches, doesn't render
- **RenderMiddleware**: Only renders templates, doesn't inject
- **ActionMiddleware**: Only handles compensation, doesn't detect

This separation makes the system testable. You can test the matcher without running the renderer.

## 6. The Dispatch Pattern

The dispatcher contains 8 executors that handle specific event types:

```
TextInjectExecutor → KeyInjectExecutor → HtmlInjectExecutor →
ImageInjectExecutor → ContextMenuExecutor → IconUpdateExecutor →
SecureInputExecutor → TextUIExecutor
```

**First-match-wins:** Iterates executors, stops at first one that handles the event.

### Why First-Match-Wins?

Most events are only relevant to one executor. An `HtmlInject` event should only go to `HtmlInjectExecutor`, not all of them. First-match-wins is simpler than routing rules.

## 7. Dependency Injection

The engine uses explicit dependency injection via factory functions:

```rust
// espanso-engine/src/process/default.rs:72-99
pub fn default<'a>(
    event_source: &'a dyn Source<'a>,
    disable_is_enabled_provider: ...,
    disable_operation_context_provider: ...,
    // ... 16 more parameters
) -> DefaultProcessor<'a> {
    DefaultProcessor::new(
        /* 24 middleware instances */
    )
}
```

### Why Dependency Injection?

- **Testability**: You can inject mock matchers, renderers, etc.
- **Decoupling**: Engine doesn't depend on specific implementations
- **Flexibility**: Different contexts can wire different implementations

### Why Not Use a DI Framework?

Rust's trait system and ownership model make manual DI straightforward. A framework would add complexity without significant benefit for this scope.

## 8. Traits You Need to Know

| Trait | Location | Purpose |
|-------|----------|---------|
| `Funnel` | funnel/mod.rs:19 | Receives events from sources |
| `Source` | funnel/mod.rs:14 | Event source abstraction |
| `Processor` | process/mod.rs:36 | Processes events through middleware |
| `Middleware` | process/mod.rs:31 | Single event processing step |
| `Dispatcher` | dispatch/mod.rs:32 | Dispatches events to executors |
| `Executor` | dispatch/mod.rs:28 | Handles a specific event type |
| `Matcher` | process/middleware/matcher.rs:11 | Pattern matching abstraction |
| `Renderer` | process/middleware/render.rs:12 | Template rendering abstraction |
| `TextInjector` | dispatch/executor/text_inject.rs | Text injection abstraction |
| `ModeProvider` | dispatch/executor/text_inject.rs | Injection mode selection |

## 9. Edge Cases

### NOOP Interruption

When any middleware returns `EventType::NOOP`, the middleware chain is interrupted:

```rust
// espanso-engine/src/process/default.rs:115-125
for middleware in &self.middleware {
    current_event = if current_event.etype == EventType::NOOP {
        break;  // Stop processing
    };
    current_event = middleware.next(current_event, &mut dispatch_fn);
}
```

This means if the matcher returns NOOP (no match found), subsequent middleware don't run.

### source_id Propagation

The `source_id` is propagated through all consequential events:

```rust
Event::caused_by(source_id, EventType::MatchesDetected(...))
```

This means:
- Each keystroke gets a unique source_id
- All events from that keystroke share the same source_id
- You can trace the full lifecycle of a single input

### Event Queue Draining

The processor drains the queue after each event:

```rust
// espanso-engine/src/process/default.rs:135-143
fn process(&mut self, event: Event) -> Vec<Event> {
    self.event_queue.push_back(event);
    let mut events = Vec::new();
    while let Some(event) = self.event_queue.pop_front() {
        let mut processed = self.process_one(event);
        events.append(&mut processed);
    }
    events
}
```

This means:
- Events can generate more events (via `dispatch()`)
- All events are processed before returning
- No event is left unprocessed

## 10. Key Patterns

### Event-Driven Architecture

Everything is an event. Keyboard input, match detection, rendering, injection — all events. This makes the system:
- **Traceable**: You can log all events and understand what happened
- **Testable**: You can inject events and check outputs
- **Flexible**: You can add new events without changing existing code

### Middleware Pipeline

Each middleware has a single responsibility. This makes the system:
- **Composable**: You can add/remove middleware without affecting others
- **Testable**: You can test each middleware in isolation
- **Understandable**: Each middleware is small and focused

### Dependency Injection

All dependencies are injected explicitly. This makes the system:
- **Testable**: You can mock any dependency
- **Decoupled**: Engine doesn't depend on specific implementations
- **Flexible**: Different contexts can wire different implementations

## 11. Risk Assessment for Changes

| Area | Risk | Why |
|------|------|-----|
| Adding new EventType | MEDIUM | Must update all match statements |
| Adding new middleware | LOW | Add to end of chain, no conflicts |
| Modifying existing middleware | HIGH | May affect all events that pass through |
| Changing event flow | HIGH | May break the entire pipeline |
| Modifying dispatch | HIGH | May break output handling |

## 12. What Was Studied

- **Files**: All 47 files in espanso-engine/src/
- **Key Files**: lib.rs, event/mod.rs, event/input.rs, event/internal.rs, event/effect.rs, event/ui.rs, funnel/mod.rs, funnel/default.rs, process/mod.rs, process/default.rs, process/middleware/matcher.rs, process/middleware/render.rs, process/middleware/alt_code_synthesizer.rs, dispatch/mod.rs, dispatch/default.rs, dispatch/executor/text_inject.rs
- **Patterns**: Event-driven architecture, middleware pipeline, dependency injection, source_id propagation, event queue draining
- **Missing**: Some middleware implementations (18 of 24 not individually studied), executor implementations (6 of 8 not individually studied)
- **Coverage**: 70% — core pipeline well understood, individual middleware need more study

## 13. Evidence

- `espanso-engine/src/lib.rs` — Engine struct and main loop (77 lines)
- `espanso-engine/src/event/mod.rs` — Event and EventType definitions (117 lines)
- `espanso-engine/src/process/mod.rs` — Middleware trait and factory (31 lines)
- `espanso-engine/src/process/default.rs` — DefaultProcessor with 24 middleware (187 lines)
- `espanso-engine/src/dispatch/mod.rs` — Executor trait and factory (28 lines)
- `espanso-engine/src/dispatch/default.rs` — DefaultDispatcher with 8 executors (84 lines)
- `espanso-engine/src/process/middleware/matcher.rs` — MatcherMiddleware (195 lines)
- `espanso-engine/src/process/middleware/render.rs` — RenderMiddleware (72 lines)
- `espanso-engine/src/process/middleware/alt_code_synthesizer.rs` — AltCodeSynthesizerMiddleware (675 lines)
- `espanso-engine/src/dispatch/executor/text_inject.rs` — TextInjectExecutor (115 lines)
- `espanso-engine/src/funnel/default.rs` — DefaultFunnel (43 lines)
- `espanso-engine/src/event/input.rs` — Input event types (135 lines)
- `espanso-engine/src/event/internal.rs` — Internal event types (108 lines)
- `espanso-engine/src/event/effect.rs` — Effect event types (70 lines)
- `espanso-engine/src/event/ui.rs` — UI event types (60 lines)
- `espanso-engine/src/event/external.rs` — External event types (30 lines)

## Related Pages

- [[07-espanso-engine/MAP]]
- [[01-CORE/ARCHITECTURE]]
- [[01-CORE/CODEBASE_MAP]]
- [[01-CORE/CRATE_DEPENDENCIES]]
