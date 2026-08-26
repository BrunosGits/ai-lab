# espanso-engine — File:Line Index

Complete cross-reference for all code in the espanso-engine crate (47 files, 4,672 lines).

---

## lib.rs — Engine Core

| Lines | Function/Struct | Description |
|-------|----------------|-------------|
| 36-40 | `pub struct Engine<'a>` | Core engine: funnel + processor + dispatcher |
| 42-51 | `Engine::new()` | Constructor, takes trait object references |
| 53-69 | `Engine::run()` | Main loop: funnel.receive → process → dispatch |
| 57 | | `FunnelResult::Event(event)` — process the event |
| 58 | | `self.processor.process(event)` — run through middleware |
| 61-63 | | `EventType::Exit(mode)` — return early on exit |
| 65 | | `self.dispatcher.dispatch(event)` — send to executors |
| 67 | | `FunnelResult::EndOfStream` — return ExitMode::Exit |
| 69 | | `FunnelResult::Skipped` — no-op |

---

## event/mod.rs — Event System

| Lines | Item | Description |
|-------|------|-------------|
| 31-32 | `pub type SourceId = u32` | Monotonically increasing event ID |
| 34-37 | `pub struct Event` | `source_id` + `etype: EventType` |
| 39-44 | `Event::caused_by()` | Constructor that propagates source_id |
| 47-117 | `pub enum EventType` | All 40+ event types (see below) |
| 119-122 | `pub enum ExitMode` | Exit, ExitAllProcesses, RestartWorker |

### EventType Variants (Complete)

| Variant | Category | Description |
|---------|----------|-------------|
| `NOOP` | Control | No operation, interrupts middleware chain |
| `ExitRequested(ExitMode)` | Control | Graceful exit request |
| `Exit(ExitMode)` | Control | Exit command |
| `Heartbeat` | Control | Periodic heartbeat |
| **Input Events** | | |
| `Keyboard(KeyboardEvent)` | Input | Raw keyboard input |
| `Mouse(MouseEvent)` | Input | Raw mouse input |
| `HotKey(HotKeyEvent)` | Input | Hotkey triggered |
| `TrayIconClicked` | Input | Tray icon clicked |
| `ContextMenuClicked(ContextMenuClickedEvent)` | Input | Context menu item clicked |
| **External Events** | | |
| `MatchExecRequest(MatchExecRequestEvent)` | External | CLI match execution request |
| **Internal Events** | | |
| `MatchesDetected(MatchesDetectedEvent)` | Internal | Matcher found matches |
| `MatchSelected(MatchSelectedEvent)` | Internal | Match selected from candidates |
| `CauseCompensatedMatch(CauseCompensatedMatchEvent)` | Internal | Cause compensation applied |
| `RenderingRequested(RenderingRequestedEvent)` | Internal | Request to render match |
| `ImageRequested(ImageRequestedEvent)` | Internal | Request to resolve image |
| `Rendered(RenderedImageEvent)` | Internal | Render completed |
| `ImageResolved(ImageResolvedEvent)` | Internal | Image path resolved |
| `MatchInjected` | Internal | Injection completed |
| `DiscardPrevious(DiscardPreviousEvent)` | Internal | Discard previous events |
| `DiscardBetween(DiscardBetweenEvent)` | Internal | Discard events between |
| `Undo(UndoEvent)` | Internal | Undo last expansion |
| `RenderingError` | Internal | Render failed |
| `Disabled` | Control | Engine disabled |
| `Enabled` | Control | Engine enabled |
| `DisableRequest` | Control | Request disable |
| `EnableRequest` | Control | Request enable |
| `ToggleRequest` | Control | Request toggle |
| `SecureInputEnabled(SecureInputEnabledEvent)` | Internal | macOS secure input on |
| `SecureInputDisabled` | Internal | macOS secure input off |
| **Effect Events** | | |
| `TriggerCompensation(TriggerCompensationEvent)` | Effect | Compensate for deleted trigger |
| `CursorHintCompensation(CursorHintCompensationEvent)` | Effect | Position cursor hint |
| `KeySequenceInject(KeySequenceInjectRequest)` | Effect | Inject key sequence |
| `TextInject(TextInjectRequest)` | Effect | Inject text |
| `MarkdownInject(MarkdownInjectRequest)` | Effect | Inject markdown |
| `HtmlInject(HtmlInjectRequest)` | Effect | Inject HTML |
| `ImageInject(ImageInjectRequest)` | Effect | Inject image |
| **UI Events** | | |
| `ShowContextMenu(ShowContextMenuEvent)` | UI | Show context menu |
| `IconStatusChange(IconStatusChangeEvent)` | UI | Update tray icon |
| `DisplaySecureInputTroubleshoot` | UI | Show secure input dialog |
| `ShowConfigFolder` | UI | Open config folder |
| `ShowSearchBar` | UI | Open search bar |
| `ShowText(ShowTextEvent)` | UI | Show text window |
| `ShowLogs` | UI | Open log folder |
| `LaunchSecureInputAutoFix` | UI | Launch secure input fix |

---

## event/input.rs — Input Events

| Lines | Item | Description |
|-------|------|-------------|
| 1-135 | `KeyboardEvent` struct | `key: Key`, `value: Option<String>`, `status: Status` |
| | `MouseEvent` struct | `button: MouseButton`, `status: Status`, `x/y: i32` |
| | `HotKeyEvent` struct | `key: Key`, `modifiers: Vec<Key>` |
| | `ContextMenuClickedEvent` struct | `id: u32` |
| | `enum Key` | 60+ key variants (A-Z, F1-F12, arrows, modifiers, etc.) |
| | `enum Status` | Pressed, Released |
| | `enum MouseButton` | Left, Right, Middle |

---

## event/internal.rs — Internal Events

| Lines | Item | Description |
|-------|------|-------------|
| 1-108 | `DetectedMatch` struct | `id: i32`, `trigger: Option<String>`, `args: HashMap` |
| | `MatchesDetectedEvent` | `matches: Vec<DetectedMatch>`, `is_search: bool` |
| | `MatchSelectedEvent` | `match_id: i32`, `trigger: Option<String>` |
| | `CauseCompensatedMatchEvent` | `match_id: i32`, `trigger: String` |
| | `RenderingRequestedEvent` | `match_id`, `trigger`, `format`, `right_separator` |
| | `RenderedEvent` | `match_id`, `body: String`, `format` |
| | `ImageResolvedEvent` | `path: String` |
| | `DiscardPreviousEvent` | `char_count: usize` |
| | `DiscardBetweenEvent` | `start_id: SourceId`, `end_id: SourceId` |
| | `UndoEvent` | Empty struct |
| | `SecureInputEnabledEvent` | `app_name: Option<String>` |

---

## event/effect.rs — Effect Events

| Lines | Item | Description |
|-------|------|-------------|
| 1-70 | `TriggerCompensationEvent` | `keys: Vec<KeyEvent>` — keys to re-inject |
| | `CursorHintCompensationEvent` | `keys: Vec<KeyEvent>` — cursor positioning keys |
| | `TextInjectRequest` | `text: String`, `html: Option<String>`, `force_mode: Option<Mode>` |
| | `KeySequenceInjectRequest` | `keys: Vec<KeyEvent>` |
| | `MarkdownInjectRequest` | `markdown: String` |
| | `HtmlInjectRequest` | `html: String` |
| | `ImageInjectRequest` | `image_path: String` |

---

## event/external.rs — External Events

| Lines | Item | Description |
|-------|------|-------------|
| 1-30 | `MatchExecRequestEvent` | `matches: Vec<DetectedMatch>`, `is_search: bool` |

---

## event/ui.rs — UI Events

| Lines | Item | Description |
|-------|------|-------------|
| 1-60 | `ShowContextMenuEvent` | `items: Vec<ContextMenuItem>` |
| | `IconStatusChangeEvent` | `status: IconStatus` |
| | `ShowTextEvent` | `text: String`, `title: String` |
| | `ContextMenuItem` | `label: String`, `id: u32` |
| | `IconStatus` | Active, Disabled, Error |

---

## funnel/mod.rs — Funnel Traits

| Lines | Item | Description |
|-------|------|-------------|
| 14-17 | `pub trait Source<'a>` | `register()` + `receive()` — event source abstraction |
| 19-21 | `pub trait Funnel` | `receive() -> FunnelResult` — blocking event receive |
| 23-27 | `pub enum FunnelResult` | `Event(Event)`, `Skipped`, `EndOfStream` |
| 29-31 | `pub fn default()` | Factory for DefaultFunnel |

---

## funnel/default.rs — DefaultFunnel

| Lines | Item | Description |
|-------|------|-------------|
| 14-18 | `DefaultFunnel<'a>` struct | `sources: &[&dyn Source]` |
| 20-25 | `DefaultFunnel::new()` | Constructor |
| 27-43 | `impl Funnel for DefaultFunnel` | crossbeam Select: register all → select → receive |
| 33-36 | | `Select::new()` + register all sources |
| 38-39 | | `select.select()` — blocking wait for first source |
| 41-42 | | Get source by index, call `receive(op)` |

---

## process/mod.rs — Processor Traits

| Lines | Item | Description |
|-------|------|-------------|
| 31-34 | `pub trait Middleware` | `name()` + `next(event, dispatch) -> Event` |
| 36-38 | `pub trait Processor` | `process(event) -> Vec<Event>` |
| 40-70 | Re-exports | 20+ dependency injection entities |
| 72-99 | `pub fn default()` | Factory with 19 parameters (dependency injection) |

---

## process/default.rs — DefaultProcessor

| Lines | Item | Description |
|-------|------|-------------|
| 38-41 | `DefaultProcessor<'a>` struct | `event_queue: VecDeque<Event>`, `middleware: Vec<Box<dyn Middleware>>` |
| 44-100 | `DefaultProcessor::new()` | Creates 24 middleware in specific order |
| 102-133 | `process_one()` | Core: pop event → run through middleware chain → return result |
| 108-112 | | `dispatch` closure — queues side-effect events |
| 115-125 | | Middleware chain iteration with NOOP interruption |
| 127-130 | | Drain `current_queue` into `event_queue` |
| 135-143 | `impl Processor::process()` | Queue event, drain queue, return all processed events |

### Middleware Order (in DefaultProcessor::new)

| Index | Middleware | Purpose |
|-------|-----------|---------|
| 0 | EventsDiscardMiddleware | Filter discarded events |
| 1 | DisableMiddleware | Handle enable/disable |
| 2 | IconStatusMiddleware | Update tray icon |
| 3 | AltCodeSynthesizerMiddleware | Alt code input |
| 4 | MatcherMiddleware | Detect matches |
| 5 | MatchExecRequestMiddleware | Resolve exec requests |
| 6 | SuppressMiddleware | Suppress when disabled |
| 7 | ContextMenuMiddleware | Context menu clicks |
| 8 | HotKeyMiddleware | Hotkey triggers |
| 9 | MatchSelectMiddleware | Select among matches |
| 10 | CauseCompensateMiddleware | Trigger compensation |
| 11 | ConfigMiddleware | Open config folder |
| 12 | MultiplexMiddleware | Event multiplexing |
| 13 | StatsMiddleware | Statistics recording |
| 14 | RenderMiddleware | Template rendering |
| 15 | ImageResolverMiddleware | Image path resolution |
| 16 | CursorHintMiddleware | Cursor positioning |
| 17 | ExitMiddleware | Exit handling |
| 18 | UndoMiddleware | Backspace undo |
| 19 | ActionMiddleware | Trigger compensation events |
| 20 | SearchMiddleware | Search bar integration |
| 21 | MarkdownMiddleware | Markdown rendering |
| 22 | NotificationMiddleware | Desktop notifications |
| 23 | DelayForModifierReleaseMiddleware | Modifier release delay |

---

## process/middleware/matcher.rs — MatcherMiddleware

| Lines | Item | Description |
|-------|------|-------------|
| 11-15 | `pub trait Matcher<'a, State>` | `process(prev_state, event) -> (State, Vec<MatchResult>)` |
| 18-23 | `MatcherEvent` enum | `Key { key, chars }`, `VirtualSeparator` |
| 25-31 | `MatchResult` struct | `id: i32`, `trigger`, `left/right_separator`, `args` |
| 33-35 | `MatcherMiddlewareConfigProvider` | `max_history_size() -> usize` |
| 37-42 | `ModifierStateProvider` | `get_modifier_state() -> ModifierState` |
| 44-48 | `ModifierState` | `is_ctrl_down`, `is_alt_down`, `is_meta_down` |
| 50-57 | `MatcherMiddleware<'a, State>` struct | `matchers`, `matcher_states: RefCell<VecDeque>`, `max_history_size` |
| 59-75 | `MatcherMiddleware::new()` | Constructor with matcher references |
| 77-130 | `impl Middleware` | Core logic: filter events → run matchers → emit MatchesDetected |
| 88-95 | | Backspace handling: pop last state |
| 97-104 | | Skip events during modifier press |
| 106-112 | | Invalidate on arrow keys, mouse, escape |
| 114-128 | | Run all matchers, collect results, emit MatchesDetected |
| 132-155 | `is_event_of_interest()` | Filter: only pressed keys, skip modifiers |
| 157-165 | `convert_to_matcher_event()` | Convert EventType to MatcherEvent |
| 167-180 | `is_invalidating_event()` | Arrow keys, mouse clear matcher state |
| 182-195 | `should_skip_key_event_due_to_modifier_press()` | Platform-specific modifier handling |

---

## process/middleware/render.rs — RenderMiddleware

| Lines | Item | Description |
|-------|------|-------------|
| 12-17 | `pub trait Renderer<'a>` | `render(match_id, trigger, args) -> Result<String>` |
| 19-30 | `RendererError` enum | RenderingError, NotFound, Aborted |
| 32-36 | `RenderMiddleware<'a>` struct | `renderer: &'a dyn Renderer` |
| 38-42 | `RenderMiddleware::new()` | Constructor |
| 44-72 | `impl Middleware` | Handle RenderingRequested → call renderer → emit Rendered |
| 50-60 | | Success path: render, append right_separator, emit Rendered |
| 61-71 | | Error path: Aborted → NOOP, other → error message + RenderingError |

---

## process/middleware/alt_code_synthesizer.rs — AltCodeSynthesizerMiddleware

| Lines | Item | Description |
|-------|------|-------------|
| 1-675 | AltCodeSynthesizerMiddleware | Largest middleware (675 lines) |
| | `AltCodeSynthEnabledProvider` trait | `is_enabled() -> bool` |
| | State machine | Tracks Alt key sequences for Windows alt code input |
| | Numpad handling | Converts Alt+Numpad sequences to characters |

---

## dispatch/mod.rs — Dispatcher Traits

| Lines | Item | Description |
|-------|------|-------------|
| 28-30 | `pub trait Executor` | `execute(&self, event: &Event) -> bool` |
| 32-34 | `pub trait Dispatcher` | `dispatch(&self, event: Event)` |
| 36-60 | Re-exports | 10 dependency injection entities |
| 62-68 | `pub fn default()` | Factory with 10 parameters |

---

## dispatch/default.rs — DefaultDispatcher

| Lines | Item | Description |
|-------|------|-------------|
| 14-18 | `DefaultDispatcher<'a>` struct | `executors: Vec<Box<dyn Executor>>` |
| 20-60 | `DefaultDispatcher::new()` | Creates 8 executors |
| 62-70 | `impl Dispatcher` | Iterate executors, stop at first match |
| 65-68 | | `executor.execute(&event)` → break if true |

### Executors (in order)

| Index | Executor | Handles EventType |
|-------|----------|-------------------|
| 0 | TextInjectExecutor | TextInject, MarkdownInject |
| 1 | KeyInjectExecutor | KeySequenceInject |
| 2 | HtmlInjectExecutor | HtmlInject |
| 3 | ImageInjectExecutor | ImageInject |
| 4 | ContextMenuExecutor | ShowContextMenu |
| 5 | IconUpdateExecutor | IconStatusChange |
| 6 | SecureInputExecutor | DisplaySecureInputTroubleshoot, LaunchSecureInputAutoFix |
| 7 | TextUIExecutor | ShowText |

---

## dispatch/executor/text_inject.rs — TextInjectExecutor

| Lines | Item | Description |
|-------|------|-------------|
| 1-115 | `TextInjectExecutor` struct | Handles text injection with mode selection |
| | `pub trait TextInjector` | `send_string(&self, text: &str) -> Result<()>` |
| | `pub trait ModeProvider` | `mode() -> Mode` |
| | `enum Mode` | Event (keyboard), Clipboard |
| | Logic | If Clipboard mode → clipboard_injector, else → event_injector |

---

## Key Variables — Cross-Reference

| Variable | Defined | Used In |
|----------|---------|---------|
| `Engine.funnel` | lib.rs:37 | lib.rs:57 |
| `Engine.processor` | lib.rs:38 | lib.rs:58 |
| `Engine.dispatcher` | lib.rs:39 | lib.rs:65 |
| `Event.source_id` | event/mod.rs:35 | All events, propagated |
| `Event.etype` | event/mod.rs:36 | All middleware, dispatchers |
| `DefaultProcessor.middleware` | process/default.rs:40 | process_one() chain |
| `DefaultProcessor.event_queue` | process/default.rs:39 | process() queue management |
| `DefaultDispatcher.executors` | dispatch/default.rs:17 | dispatch() iteration |

---

## Call Graph: Full Event Lifecycle

```
1. DETECT (espanso-detect)
   └── Keyboard event → Event { source_id: N, etype: Keyboard(...) }

2. FUNNEL (espanso-engine/funnel)
   └── crossbeam Select → FunnelResult::Event(event)

3. PROCESS (espanso-engine/process)
   ├── 0. EventsDiscardMiddleware → filter discarded
   ├── 1. DisableMiddleware → check enabled state
   ├── 2. IconStatusMiddleware → update icon
   ├── 3. AltCodeSynthesizerMiddleware → alt code handling
   ├── 4. MatcherMiddleware → detect matches → emit MatchesDetected
   ├── 5. MatchExecRequestMiddleware → resolve exec
   ├── 6. SuppressMiddleware → suppress when disabled
   ├── 7. ContextMenuMiddleware → context menu
   ├── 8. HotKeyMiddleware → hotkey triggers
   ├── 9. MatchSelectMiddleware → select match
   ├── 10. CauseCompensateMiddleware → trigger compensation
   ├── 11. ConfigMiddleware → open config
   ├── 12. MultiplexMiddleware → multiplex
   ├── 13. StatsMiddleware → record stats
   ├── 14. RenderMiddleware → render template → emit Rendered
   ├── 15. ImageResolverMiddleware → resolve image
   ├── 16. CursorHintMiddleware → cursor hint
   ├── 17. ExitMiddleware → exit handling
   ├── 18. UndoMiddleware → backspace undo
   ├── 19. ActionMiddleware → trigger compensation
   ├── 20. SearchMiddleware → search bar
   ├── 21. MarkdownMiddleware → markdown
   ├── 22. NotificationMiddleware → notifications
   └── 23. DelayForModifierReleaseMiddleware → modifier delay

4. DISPATCH (espanso-engine/dispatch)
   ├── TextInjectExecutor → text injection
   ├── KeyInjectExecutor → key injection
   ├── HtmlInjectExecutor → HTML injection
   ├── ImageInjectExecutor → image injection
   ├── ContextMenuExecutor → context menu
   ├── IconUpdateExecutor → icon update
   ├── SecureInputExecutor → secure input
   └── TextUIExecutor → text UI

5. INJECT (espanso-inject)
   └── Platform-specific injection (CGEvent/SendInput/evdev)
```

---

## Grep Patterns for Future Searches

```bash
# All middleware implementations
grep -rn "impl Middleware for" espanso-engine/src/

# All executor implementations
grep -rn "impl Executor for" espanso-engine/src/

# All EventType matches
grep -rn "EventType::" espanso-engine/src/

# All middleware names
grep -rn "fn name(&self)" espanso-engine/src/

# All trait definitions
grep -rn "pub trait" espanso-engine/src/

# All factory functions
grep -rn "pub fn default" espanso-engine/src/

# Crossbeam usage
grep -rn "crossbeam" espanso-engine/src/
```

---

**Generated from:** espanso-engine crate analysis
**Core files:** lib.rs (77 lines), event/mod.rs (117 lines), process/default.rs (187 lines), dispatch/default.rs (84 lines)
**Total:** 47 files, 4,672 lines

## Related Pages

- [[07-espanso-engine/SUMMARY]]
- [[01-CORE/ARCHITECTURE]]
- [[01-CORE/CRATE_DEPENDENCIES]]
