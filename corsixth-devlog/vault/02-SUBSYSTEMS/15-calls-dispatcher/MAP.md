# CallsDispatcher File:Line Index

## calls_dispatcher.lua (567 lines)

### Class Definition & Initialization
| Line | Method / Section | Description |
|------|------------------|-------------|
| 25   | `class "CallsDispatcher"` | Class declaration |
| 27-28 | Local reference | `local CallsDispatcher = _G["CallsDispatcher"]` |
| 30   | `debug_enabled = false` | Debug flag |
| 32-37 | `CallsDispatcher:CallsDispatcher(world)` | Constructor — initializes call_queue, change_callback, tick |
| 39-41 | `CallsDispatcher:onTick()` | Increments tick counter |
| 43-45 | `CallsDispatcher:addChangeCallback(callback, self_value)` | Registers UI change callback |
| 47-49 | `CallsDispatcher:removeChangeCallback(callback)` | Removes UI change callback |
| 51-55 | `CallsDispatcher:onChange()` | Fires all registered callbacks |

### Staff Calls
| Line | Method | Description |
|------|--------|-------------|
| 57-71 | `CallsDispatcher:callForStaff(room)` | Main entry — checks missing staff, plays sound |
| 73-92 | `CallsDispatcher:callForStaffEachRoom(room, attribute, key)` | Creates individual staff call with verification/priority/execute |
| 77-90 | Call table creation | verification, priority, execute callbacks for staff |
| 81-82 | `verifyStaffForRoom` | Staff verification callback |
| 84-85 | `getPriorityForRoom` | Staff priority callback |
| 87-88 | `sendStaffToRoom` | Staff execute callback |

### Repair Calls
| Line | Method | Description |
|------|--------|-------------|
| 95-124 | `CallsDispatcher:callForRepair(object, urgent, manual)` | Creates repair call |
| 99-110 | Call table structure | verification (false), priority (1), execute (sendStaffToRepair) |
| 112-117 | Advisory logic | Urgent/manual flags, handyman count check |
| 119-123 | Queue insertion | Creates object entry if needed, stores under "repair" key |

### Watering Calls
| Line | Method | Description |
|------|--------|-------------|
| 126-146 | `CallsDispatcher:callForWatering(plant)` | Creates watering call |
| 127-140 | Call table structure | verification (false), priority (1), execute (sendStaffToWatering) |
| 141-145 | Queue insertion | Stores under "watering" key |

### Vaccination Calls
| Line | Method | Description |
|------|--------|-------------|
| 148-177 | `CallsDispatcher:callNurseForVaccination(patient)` | Creates vaccination call |
| 152-170 | Call table structure | verification, priority, execute callbacks |
| 171-175 | Queue insertion | Stores under "vaccinate" key |
| 179-205 | `CallsDispatcher.verifyStaffForVaccination(patient, staff)` | Nurse verification: class, idle, proximity ≤5 tiles |
| 207-231 | `CallsDispatcher.getPriorityForVaccination(patient, nurse)` | Priority: path distance + unreachable penalty |
| 233-252 | `CallsDispatcher.sendNurseToVaccinate(patient, nurse)` | Execute: Epidemic vaccination actions |

### Core Queue Operations
| Line | Method | Description |
|------|--------|-------------|
| 255-279 | `CallsDispatcher:enqueue(object, key, description, verification, priority, execute)` | Core enqueue logic — returns true if queued, false if served |
| 259-261 | Duplicate check | Returns assigned status if already queued |
| 262-264 | Object entry creation | Creates call_queue[object] if needed |
| 266-276 | Call table creation | All call properties including created tick |
| 278 | Immediate dispatch | Calls findSuitableStaff, returns negation |

### Dispatch Algorithms
| Line | Method | Description |
|------|--------|-------------|
| 281-317 | `CallsDispatcher:findSuitableStaff(call)` | **Push model** — iterates all entities, finds best staff |
| 284-287 | Dropped check | Early return if call.dropped |
| 289-293 | TODO comments | Preemption for urgent calls, doctor room assignment |
| 294-306 | Entity iteration | Loops world.entities, skips Handymen |
| 299 | Verification + priority | Calls verification, then priority if verified |
| 308-311 | Immediate execute | Calls executeCall, returns true |
| 312-315 | Queue & notify | Calls onChange, returns false |
| 319-363 | `CallsDispatcher:answerCall(staff)` | **Pull model** — idle staff searches for work |
| 322-323 | Assertions | Not on_call, has hospital |
| 328-331 | Handyman delegation | Calls searchForHandymanTask |
| 333-350 | Queue search | Iterates all call_queue, finds best verified call |
| 338-343 | Preemption check | Compares priority with current assignee |
| 352-360 | Execute found call | Preempts if needed, validates object, executes |

### Debug & Dump
| Line | Method | Description |
|------|--------|-------------|
| 365-374 | `CallsDispatcher:dump()` | Prints full queue state |
| 376-398 | `CallsDispatcher.dumpCall(call, message)` | Formats single call for debug output |

### Checkpoint System
| Line | Method | Description |
|------|--------|-------------|
| 400-408 | `CallsDispatcher.queueCallCheckpointAction(humanoid, interrupt_handler)` | Queues CallCheckPointAction with handler |
| 410-418 | `CallsDispatcher.actionInterruptHandler(action, humanoid)` | Default handler: unassigns, re-dispatches |
| 420-428 | `CallsDispatcher.onCheckpointCompleted(call)` | Completion: clears assignment, drops from queue |

### Call Execution & Assignment
| Line | Method | Description |
|------|--------|-------------|
| 430-438 | `CallsDispatcher:executeCall(call, staff)` | Binds call↔staff, fires callbacks |
| 431-433 | Assertions | Not assigned, not dropped, staff not on call |
| 434-437 | Binding & execution | Sets assigned/on_call, onChange, calls execute |

### Drop Mechanism
| Line | Method | Description |
|------|--------|-------------|
| 440-466 | `CallsDispatcher:dropFromQueue(object, key)` | Removes call(s) from queue |
| 447-455 | Specific key drop | Marks dropped, unassigns, removes key |
| 456-463 | All keys drop | Iterates all calls for object, drops each |
| 465 | Change notification | Calls onChange |

### Unassignment
| Line | Method | Description |
|------|--------|-------------|
| 468-480 | `CallsDispatcher.unassignCall(call, answer_next_call)` | Unassigns staff, optionally gives AnswerCallAction |
| 472-473 | Assertions | Staff matches call.assigned |
| 474-479 | Cleanup | Clears call.assigned, staff.on_call, queues next action |

### Staff Verification & Priority (Room)
| Line | Method | Description |
|------|--------|-------------|
| 482-495 | `CallsDispatcher.verifyStaffForRoom(room, attribute, staff)` | Idle, criterion, room policy check |
| 497-531 | `CallsDispatcher.getPriorityForRoom(room, attribute, staff)` | Distance, queue, emergency, fatigue, wandering, specialist |
| 498-505 | Distance score | Path distance to room entrance |
| 507-513 | Queue modifiers | Size bonus, emergency patient bonus |
| 515-516 | Fatigue preference | -fatigue * 40 |
| 518-521 | Wandering bonus | -50 if not in room |
| 525-528 | Specialist bonus | -100000 for Researcher/Psychiatrist/Surgeon |

### Staff Execute & Handlers
| Line | Method | Description |
|------|--------|-------------|
| 533-543 | `CallsDispatcher.sendStaffToRoom(room, staff)` | EnterRoomAction or re-enter + checkpoint |
| 545-553 | `CallsDispatcher.staffActionInterruptHandler(action, humanoid)` | Re-calls callForStaff on interrupt |
| 555-560 | `CallsDispatcher.sendStaffToRepair(object, handyman)` | Delegates to object:createHandymanActions |
| 562-567 | `CallsDispatcher.sendStaffToWatering(plant, handyman)` | Delegates to plant:createHandymanActions |

---

## Related Files

### hospital.lua
| Line | Method | Description |
|------|--------|-------------|
| 657  | `Hospital:notifyRoomRemoved()` | **Drops calls for removed room** — calls dispatcher:dropFromQueue(room) |
| ~657+ | (Search for "notifyRoomRemoved") | Exact line varies — grep for `dropFromQueue` in hospital.lua |

### entity.lua
| Line | Method | Description |
|------|--------|-------------|
| 292-294 | `Entity:onPickUp()` | **Drops all calls for entity** — calls `self.world.dispatcher:dropFromQueue(self)` |

### staff.lua (referenced)
| Method | Description |
|--------|-------------|
| `Staff:searchForHandymanTask()` | Handyman-specific task finding (called from answerCall) |
| `AnswerCallAction` | Action queued when staff should find new work |
| `CallCheckPointAction` | Checkpoint action for call completion |

### actions.lua (referenced)
| Class | Description |
|-------|-------------|
| `CallCheckPointAction` | Checkpoint action with interrupt handler |
| `AnswerCallAction` | Action that triggers answerCall |
| `EnterRoomAction` | Action for staff entering room |

---

## Call Type Quick Reference

| Call Type | Key | Verification | Priority | Execute |
|-----------|-----|--------------|----------|---------|
| Staff | "doctor1", "nurse2", etc. | verifyStaffForRoom | getPriorityForRoom | sendStaffToRoom |
| Repair | "repair" | `function() return false end` | `function() return 1 end` | sendStaffToRepair |
| Watering | "watering" | `function() return false end` | `function() return 1 end` | sendStaffToWatering |
| Vaccination | "vaccinate" | verifyStaffForVaccination | getPriorityForVaccination | sendNurseToVaccinate |

---

## Persistable Callback Tags (for save/load)

| Tag | Used In |
|-----|---------|
| `call_dispatcher_staff_verification` | callForStaffEachRoom (line 81) |
| `call_dispatcher_staff_priority` | callForStaffEachRoom (line 84) |
| `call_dispatcher_staff_execute` | callForStaffEachRoom (line 87) |
| `call_dispatcher_repair_verification` | callForRepair (line 100) |
| `call_dispatcher_repair_priority` | callForRepair (line 101) |
| `call_dispatcher_repair_execute` | callForRepair (line 102) |
| `call_dispatcher_watering_verification` | callForWatering (line 128) |
| `call_dispatcher_watering_priority` | callForWatering (line 130) |
| `call_dispatcher_watering_execute` | callForWatering (line 132) |
| `call_dispatcher_vaccinate_verification` | callNurseForVaccination (line 157) |
| `call_dispatcher_vaccinate_priority` | callNurseForVaccination (line 160) |
| `call_dispatcher_vaccinate_execute` | callNurseForVaccination (line 163) |

---

## Search Patterns for Navigation

```bash
# Find all dispatcher methods
grep -n "^function CallsDispatcher:" Lua/calls_dispatcher.lua

# Find all static functions
grep -n "^function CallsDispatcher\." Lua/calls_dispatcher.lua

# Find queue operations
grep -n "call_queue" Lua/calls_dispatcher.lua

# Find preemption logic
grep -n "preempt\|unassignCall" Lua/calls_dispatcher.lua

# Find drop mechanism
grep -n "dropFromQueue\|dropped" Lua/calls_dispatcher.lua

# Find checkpoint system
grep -n "CheckPoint\|checkpoint" Lua/calls_dispatcher.lua

# Find cross-file references
grep -rn "dropFromQueue" Lua/
grep -rn "callForStaff\|callForRepair\|callForWatering\|callNurseForVaccination" Lua/
```

---

*Line numbers based on calls_dispatcher.lua (567 lines) as of analysis date*


## Related Pages

- [[15-calls-dispatcher/SUMMARY]]
- [[15-calls-dispatcher/CHECKLIST]]
- [[15-calls-dispatcher/SCAFFOLD]]
