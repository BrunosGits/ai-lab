# Espanso Architecture

## The Event Pipeline

Espanso's core is an event loop that processes keyboard input through a pipeline:

```
┌─────────┐    ┌─────────┐    ┌─────────────┐    ┌──────────┐
│ DETECT  │───▶│ FUNNEL  │───▶│  PROCESSOR   │───▶│ DISPATCH │
│ (input) │    │ (merge) │    │ (22 middlewares) │    │ (8 executors) │
└─────────┘    └─────────┘    └─────────────┘    └──────────┘
                                      │
                                      ▼
                               ┌─────────────┐
                               │   INJECT    │
                               │ (output)    │
                               └─────────────┘
```

### The Engine Loop (`espanso-engine/src/lib.rs:51-69`)

```rust
pub fn run(&mut self) -> ExitMode {
    loop {
        match self.funnel.receive() {           // 1. Wait for event
            FunnelResult::Event(event) => {
                let processed_events = self.processor.process(event);  // 2. Process
                for event in processed_events {
                    if let EventType::Exit(mode) = &event.etype {
                        return mode.clone();    // 3. Exit if needed
                    }
                    self.dispatcher.dispatch(event);  // 4. Dispatch
                }
            }
            FunnelResult::EndOfStream => return ExitMode::Exit,
            FunnelResult::Skipped => {}          // Skip filtered events
        }
    }
}
```

**Three core traits:**
- `Funnel` — Receives events from sources (blocking select)
- `Processor` — Transforms events through middleware chain
- `Dispatcher` — Sends events to executors

## The Middleware Pipeline

The processor contains 22 middleware that process events in order:

```
Event Input
    │
    ▼
┌─────────────────────────────────────┐
│ 1.  EventsDiscardMiddleware         │ ← Filters discarded events
│ 2.  DisableMiddleware               │ ← Handles enable/disable
│ 3.  IconStatusMiddleware            │ ← Updates tray icon
│ 4.  AltCodeSynthesizerMiddleware    │ ← Alt code input handling
│ 5.  MatcherMiddleware               │ ← Detects matches (rolling matcher)
│ 6.  MatchExecRequestMiddleware      │ ← Resolves match exec requests
│ 7.  SuppressMiddleware              │ ← Suppresses when disabled
│ 8.  ContextMenuMiddleware           │ ← Context menu clicks
│ 9.  HotKeyMiddleware                │ ← Hotkey triggers
│ 10. MatchSelectMiddleware            │ ← Selects among multiple matches
│ 11. CauseCompensateMiddleware        │ ← Compensates for trigger deletion
│ 12. ConfigMiddleware                 │ ← Opens config folder
│ 13. MultiplexMiddleware              │ ← Multiplexes events
│ 14. StatsMiddleware                  │ ← Records statistics
│ 15. RenderMiddleware                 │ ← Renders match templates
│ 16. ImageResolverMiddleware          │ ← Resolves image paths
│ 17. CursorHintMiddleware             │ ← Cursor hint positioning
│ 18. ExitMiddleware                   │ ← Handles exit events
│ 19. UndoMiddleware                   │ ← Backspace undo
│ 20. ActionMiddleware                 │ ← Triggers compensation events
│ 21. SearchMiddleware                 │ ← Search bar integration
│ 22. MarkdownMiddleware               │ ← Markdown rendering
│ 23. NotificationMiddleware           │ ← Desktop notifications
│ 24. DelayForModifierReleaseMiddleware│ ← Waits for modifier release
└─────────────────────────────────────┘
    │
    ▼
Event Output (dispatched)
```

### Middleware Pattern (`espanso-engine/src/process/mod.rs:31-34`)

```rust
pub trait Middleware {
    fn name(&self) -> &'static str;
    fn next(&self, event: Event, dispatch: &mut dyn FnMut(Event)) -> Event;
}
```

Each middleware can:
1. **Transform** the event (return a different event)
2. **Pass through** (return the same event)
3. **Suppress** (return `EventType::NOOP`)
4. **Dispatch side effects** (call `dispatch()` with new events)

### Event Queue

The processor maintains a `VecDeque<Event>` for internal dispatch:
- Middleware can dispatch events via the `dispatch` callback
- Dispatched events are queued and processed after the current event
- This allows middleware to generate new events without direct coupling

## The Dispatch Pattern

The dispatcher contains 8 executors that handle specific event types:

```
┌─────────────────────────────────────┐
│ 1. TextInjectExecutor               │ ← Text injection (event or clipboard)
│ 2. KeyInjectExecutor                │ ← Key sequence injection
│ 3. HtmlInjectExecutor               │ ← HTML injection
│ 4. ImageInjectExecutor              │ ← Image injection
│ 5. ContextMenuExecutor              │ ← Context menu display
│ 6. IconUpdateExecutor               │ ← Tray icon updates
│ 7. SecureInputExecutor              │ ← macOS secure input
│ 8. TextUIExecutor                   │ ← Text UI display
└─────────────────────────────────────┘
```

**First-match-wins:** Iterates executors, stops at first one that handles the event.

### Dispatcher Pattern (`espanso-engine/src/dispatch/mod.rs:28-31`)

```rust
pub trait Executor {
    fn execute(&self, event: &Event) -> bool;  // true = handled
}

pub trait Dispatcher {
    fn dispatch(&self, event: Event);
}
```

## The Funnel Pattern

The funnel merges events from multiple sources using `crossbeam::channel::Select`:

```rust
pub trait Source<'a> {
    fn register(&'a self, select: &mut Select<'a>) -> usize;
    fn receive(&'a self, op: SelectedOperation) -> Option<Event>;
}
```

Sources include:
- Keyboard detection (espanso-detect)
- Mouse detection
- IPC messages (from daemon)
- Tray icon events
- Timer events

## Event Taxonomy

All events share a common structure:

```rust
pub struct Event {
    pub source_id: SourceId,  // Monotonically increasing, propagated
    pub etype: EventType,
}
```

### Event Categories

| Category | Variants | Description |
|----------|----------|-------------|
| **Input** | Keyboard, Mouse, HotKey | Raw platform input |
| **Internal** | MatchesDetected, MatchSelected, RenderingRequested, Rendered | Engine-internal events |
| **Effect** | TriggerCompensation, CursorHintCompensation, TextInject, HtmlInject | Side effects |
| **External** | MatchExecRequest | External requests (CLI) |
| **UI** | ShowContextMenu, IconStatusChange, ShowText | UI updates |
| **Control** | Exit, Disabled, Enabled, DisableRequest, EnableRequest | State changes |

### source_id Propagation

The `source_id` is assigned at input and propagated through all consequential events:
- Keyboard event (source_id=5) → MatchesDetected (source_id=5) → Rendered (source_id=5)
- This allows tracing the full lifecycle of a single keystroke

## Platform Abstraction

Platform-specific code is isolated behind traits:

```rust
// Detection trait (espanso-detect)
pub trait Detect {
    fn receive(&self) -> Option<DetectEvent>;
}

// Injection trait (espanso-inject)
pub trait Inject {
    fn send_string(&self, s: &str) -> Result<()>;
    fn send_key(&self, key: &Key, modifiers: &[Key]) -> Result<()>;
}
```

Each platform provides an implementation:
- **macOS**: CGEvent, NSWorkspace, accessibility APIs
- **Windows**: Win32 hooks, SendInput, clipboard
- **Linux**: X11 XRecord, evdev, uinput, xdotool

## Daemon-Worker IPC Model

```
┌──────────────┐     IPC      ┌──────────────┐
│   Daemon     │◄────────────▶│   Worker     │
│ (privileged) │   (socket)   │ (unprivileged)│
└──────────────┘              └──────────────┘
```

- **Daemon**: Runs as service, manages lifecycle, elevated privileges
- **Worker**: Runs the engine, handles matches, lower privileges
- Communication via Unix sockets (macOS/Linux) or named pipes (Windows)
