# CallsDispatcher Area - Complete Technical Summary

## Overview

The `CallsDispatcher` class (Lua/calls_dispatcher.lua, 567 lines) is the central job dispatching system in CorsixTH. It manages a priority-based call queue that matches staff members to tasks across the hospital. The dispatcher handles five distinct call types, each with custom verification, priority scoring, and execution callbacks.

---

## 1. Call Queue Structure

### Data Structure

```lua
self.call_queue = {
  [object] = {
    [key] = call_table
  }
}
```

- **Primary index**: `object` — the entity requesting the call (Room, Machine, Plant, Patient)
- **Secondary index**: `key` — call type identifier string
- **Value**: `call` table containing all metadata and callbacks

### Call Table Schema

```lua
call = {
  verification = function(staff) -> bool|nil,  -- Returns score or nil/false
  priority     = function(staff) -> number,    -- Lower = higher priority
  execute      = function(staff),              -- Action to perform
  object       = object,                       -- Source entity
  key          = "staff|repair|watering|vaccinate",
  description  = "Human-readable description",
  dispatcher   = self,                         -- Back-reference
  created      = tick_number,                  -- Creation timestamp
  assigned     = staff|nil,                    -- Currently assigned staff
  dropped      = bool                          -- Marked for removal
}
```

### Persistable Callbacks

Three callbacks are marked as persistable (serialized in save games):

| Call Type | Verification | Priority | Execute |
|-----------|--------------|----------|---------|
| Staff     | `call_dispatcher_staff_verification` | `call_dispatcher_staff_priority` | `call_dispatcher_staff_execute` |
| Repair    | `call_dispatcher_repair_verification` | `call_dispatcher_repair_priority` | `call_dispatcher_repair_execute` |
| Watering  | `call_dispatcher_watering_verification` | `call_dispatcher_watering_priority` | `call_dispatcher_watering_execute` |
| Vaccinate | `call_dispatcher_vaccinate_verification` | `call_dispatcher_vaccinate_priority` | `call_dispatcher_vaccinate_execute` |

---

## 2. Call Types

### 2.1 Staff Calls (`callForStaff`, `callForStaffEachRoom`)

**Trigger**: Room missing required staff (doctors, nurses, researchers, etc.)

**Entry Point**: `CallsDispatcher:callForStaff(room)` → `callForStaffEachRoom`

**Verification** (`verifyStaffForRoom`):
- Staff must be idle
- Staff must fulfill the required attribute criterion
- If `staff_allowed_to_move` policy disabled, staff cannot be in another room

**Priority** (`getPriorityForRoom`):
- Base score = path distance to room entrance
- Queue size bonus: `- queue_size * 5`
- Emergency patient bonus: `-200,000` (trumps everything)
- Fatigue preference: `- fatigue * 40` (prefer tired staff to avoid sync)
- Wandering bonus: `-50` if not in a room
- Specialist bonus: `-100,000` for Researcher/Psychiatrist/Surgeon

**Execute** (`sendStaffToRoom`):
- If already in room: re-enter with checkpoint
- Otherwise: queue `EnterRoomAction` + checkpoint

### 2.2 Repair Calls (`callForRepair`)

**Trigger**: Machine breakdown (urgent or routine)

**Parameters**: `object` (machine), `urgent` (bool), `manual` (bool)

**Verification**: Always returns `false` (handyman handled separately in `answerCall`)

**Priority**: Always returns `1`

**Execute** (`sendStaffToRepair`):
- Delegates to `object:createHandymanActions(handyman)`

**Advisory Logic**:
- Urgent + not manual → "machines_falling_apart" warning
- No handymen hired → "machinery_damaged2" warning

### 2.3 Watering Calls (`callForWatering`)

**Trigger**: Plant needs watering

**Verification**: Always returns `false` (handyman handled separately)

**Priority**: Always returns `1`

**Execute** (`sendStaffToWatering`):
- Delegates to `plant:createHandymanActions(handyman)`

### 2.4 Vaccination Calls (`callNurseForVaccination`)

**Trigger**: Patient requests vaccination during epidemic

**Verification** (`verifyStaffForVaccination`):
- Must be Nurse class
- Must be idle
- Must not be in a room
- Patient must not be in a room
- Both must have valid tile coordinates
- Within 5-tile radius (Chebyshev distance)

**Priority** (`getPriorityForVaccination`):
- Path distance from nurse to patient
- Unreachable penalty: `+10,000`

**Execute** (`sendNurseToVaccinate`):
- Delegates to `Epidemic:createVaccinationActions(patient, nurse)`
- Fallback if epidemic ended: complete call immediately

### 2.5 Cleaning Calls

**Note**: Not explicitly implemented in dispatcher. Cleaning is handled via room's internal logic or handyman tasks.

---

## 3. Core Algorithms

### 3.1 Enqueue (`enqueue`)

```lua
function CallsDispatcher:enqueue(object, key, description, verification, priority, execute)
  -- 1. Check if already queued
  if self.call_queue[object] and self.call_queue[object][key] then
    return call.assigned and true or false  -- true = queued, false = served
  end

  -- 2. Create call table
  local call = { verification, priority, execute, object, key, description, dispatcher=self, created=self.tick }
  self.call_queue[object][key] = call

  -- 3. Try immediate dispatch
  return not self:findSuitableStaff(call)
end
```

**Return Values**:
- `true` = call was queued (not immediately served)
- `false` = call served immediately OR already queued+assigned

### 3.2 Dispatch — Push Model (`findSuitableStaff`)

Called when a new call is enqueued. Iterates **all entities** in world.

```lua
function CallsDispatcher:findSuitableStaff(call)
  if call.dropped then return end

  local min_score = 2^30
  local min_staff = nil

  for _, e in ipairs(self.world.entities) do
    if class.is(e, Staff) and not class.is(e, Handyman) then
      local score = call.verification(e) and call.priority(e) or nil
      if score and score < min_score then
        min_score = score
        min_staff = e
      end
    end
  end

  if min_staff then
    self:executeCall(call, min_staff)
    return true
  else
    self:onChange()
    return false
  end
end
```

**Key Behaviors**:
- Skips Handymen (they use pull model via `answerCall`)
- Returns `true` if dispatched immediately
- Calls `onChange()` to notify UI when queued

**TODO Comments in Code**:
- Preempt staff already on_call for urgent tasks (e.g., machine breakdown)
- Doctors could serve other rooms with real needs despite queued patients

### 3.3 Dispatch — Pull Model (`answerCall`)

Called when staff becomes idle (meandering). Staff searches for work.

```lua
function CallsDispatcher:answerCall(staff)
  assert(not staff.on_call)
  assert(staff.hospital)

  if class.is(staff, Handyman) then
    staff:searchForHandymanTask()  -- Handymen have custom logic
    return true
  end

  local min_score = 2^30
  local min_call = nil

  for _, queue in pairs(self.call_queue) do
    for _, call in pairs(queue) do
      local score = call.verification(staff) and call.priority(staff) or nil
      if score then
        -- Preemption check
        if call.assigned then
          local another_score = call.priority(call.assigned)
          if another_score <= score then
            score = nil  -- Cannot preempt
          end
        end
        if score and score < min_score then
          min_score = score
          min_call = call
        end
      end
    end
  end

  if min_call then
    if min_call.assigned then
      CallsDispatcher.unassignCall(min_call, true)  -- Preempt!
    end
    assert(min_call.object.tile_x or min_call.object.x)
    self:executeCall(min_call, staff)
    return true
  end
  return false
end
```

**Preemption Logic**:
- If call already assigned, compare priority scores
- Current assignee's priority (`another_score`) ≤ new staff's score → **block preemption**
- Current assignee's priority > new staff's score → **preempt allowed**
- Preempted staff gets `AnswerCallAction` queued to find new work

### 3.4 Execute Call (`executeCall`)

```lua
function CallsDispatcher:executeCall(call, staff)
  assert(not call.assigned)
  assert(not call.dropped)
  assert(not staff.on_call)

  call.assigned = staff
  staff.on_call = call
  self:onChange()
  call.execute(staff)
end
```

### 3.5 Checkpoint System (`queueCallCheckpointAction`)

All execute callbacks must insert a `CallCheckPointAction` to signal completion.

```lua
function CallsDispatcher.queueCallCheckpointAction(humanoid, interrupt_handler)
  interrupt_handler = interrupt_handler or CallsDispatcher.actionInterruptHandler
  return humanoid:queueAction(CallCheckPointAction(humanoid.on_call, interrupt_handler))
end
```

**Default Interrupt Handler** (`actionInterruptHandler`):
- Resets `call.assigned = nil`, `humanoid.on_call = nil`
- Re-dispatches call via `findSuitableStaff`

**Staff-Specific Handler** (`staffActionInterruptHandler`):
- Same reset logic
- If not dropped: re-calls `callForStaff` on the room (re-queue)

**Completion Handler** (`onCheckpointCompleted`):
```lua
function CallsDispatcher.onCheckpointCompleted(call)
  if not call.dropped and call.assigned then
    call.assigned.on_call = nil
    call.assigned = nil
    call.dispatcher:dropFromQueue(call.object, call.key)
  end
end
```

---

## 4. Preemption Logic

### When Preemption Occurs

1. **Staff-initiated** (`answerCall`): Idle staff finds higher-priority call
2. **Call-initiated** (`findSuitableStaff`): New call finds better staff (currently NOT implemented — TODO)

### Preemption Conditions

```lua
if call.assigned then
  local another_score = call.priority(call.assigned)
  if another_score <= score then
    score = nil  -- Block: current assignee has equal/better priority
  end
end
```

### Preemption Flow

```
Idle Staff A calls answerCall()
  → Finds Call X assigned to Staff B
  → Compares priority(A) vs priority(B)
  → If priority(A) < priority(B):  -- A has higher priority (lower score)
       unassignCall(Call X, true)  -- B gets AnswerCallAction
       executeCall(Call X, A)      -- A takes over
  → Else: continue searching
```

### Unassign Call (`unassignCall`)

```lua
function CallsDispatcher.unassignCall(call, answer_next_call)
  local assigned = call.assigned
  assert(assigned.on_call == call)
  call.assigned = nil
  assigned.on_call = nil
  if answer_next_call then
    assigned:setNextAction(AnswerCallAction())
  end
end
```

---

## 5. Drop Mechanism

### `dropFromQueue(object, key)`

Removes calls when no longer needed (object destroyed, room deleted, machine replaced).

```lua
function CallsDispatcher:dropFromQueue(object, key)
  if key and self.call_queue[object] then
    -- Drop specific call
    local call = self.call_queue[object][key]
    if call then
      call.dropped = true
      if call.assigned then
        CallsDispatcher.unassignCall(call, true)
      end
      self.call_queue[object][key] = nil
    end
  elseif self.call_queue[object] then
    -- Drop ALL calls for object
    for _, call in pairs(self.call_queue[object]) do
      call.dropped = true
      if call.assigned then
        CallsDispatcher.unassignCall(call, true)
      end
    end
    self.call_queue[object] = nil
  end
  self:onChange()
end
```

### Drop Triggers

| Trigger | Location | Call |
|---------|----------|------|
| Entity picked up | `Entity:onPickUp()` (entity.lua:293) | `dropFromQueue(self)` — all calls |
| Room removed | `Hospital:notifyRoomRemoved()` (hospital.lua:657+) | `dropFromQueue(room)` — all calls |
| Call completed | `onCheckpointCompleted()` | `dropFromQueue(call.object, call.key)` |
| Machine repaired | Machine's repair completion | `dropFromQueue(machine, "repair")` |
| Plant watered | Plant's watering completion | `dropFromQueue(plant, "watering")` |

### Drop Flow

```
dropFromQueue(object, key)
  → call.dropped = true
  → if call.assigned: unassignCall(call, true)
       → staff.on_call = nil
       → staff:setNextAction(AnswerCallAction())
  → Remove from call_queue
  → onChange() → UI update
```

---

## 6. Code Examples

### Example 1: Adding a Custom Call Type

```lua
function CallsDispatcher:callForCustomTask(object, task_name, verification, priority, execute)
  local call = {
    verification = verification,
    priority = priority,
    execute = execute,
    object = object,
    key = task_name,
    description = "Custom: " .. task_name,
    dispatcher = self,
    created = self.tick,
    assigned = nil,
    dropped = nil
  }
  if not self.call_queue[object] then
    self.call_queue[object] = {}
  end
  self.call_queue[object][task_name] = call
  return not self:findSuitableStaff(call)
end
```

### Example 2: Custom Verification Function

```lua
local function verifyResearcherForLab(lab, staff)
  -- Must be researcher, idle, not in another room (unless policy allows)
  if not class.is(staff, Researcher) or not staff:isIdle() then
    return false
  end
  local current_room = staff:getRoom()
  if current_room and current_room ~= lab and
     not staff.hospital.policies["staff_allowed_to_move"] then
    return false
  end
  -- Must have Research skill ≥ 3
  if staff:getAttribute("research") < 3 then
    return false
  end
  return true
end
```

### Example 3: Custom Priority Function

```lua
local function getPriorityForLab(lab, staff)
  local score = 0
  local x, y = lab:getEntranceXY()
  local distance = lab.world:getPathDistance(staff.tile_x, staff.tile_y, x, y)
  if distance then score = score + distance else score = score + 10000 end

  -- Prefer researchers with higher skill
  score = score - staff:getAttribute("research") * 100

  -- Prefer wandering staff
  if not staff:getRoom() then score = score - 50 end

  return score
end
```

### Example 4: Monitoring Queue Changes

```lua
-- In UI or AI code
local function onDispatcherChange()
  -- Refresh call indicator UI
  ui:updateCallIndicators()
end

world.dispatcher:addChangeCallback(onDispatcherChange, ui)

-- Later, when UI closes:
world.dispatcher:removeChangeCallback(onDispatcherChange)
```

### Example 5: Debugging Queue State

```lua
-- Call from console or debug key
function debugDumpCalls()
  world.dispatcher:dump()
  -- Output format:
  -- --- Queue ---
  -- staff-3@15,20: queued
  -- repair@10,5: assigned
  -- vaccinate@8,12: queued
  -- ----
end
```

### Example 6: Forcing Preemption (Manual)

```lua
function CallsDispatcher:forcePreemptCall(call, new_staff)
  assert(call.assigned ~= new_staff)
  if call.assigned then
    CallsDispatcher.unassignCall(call, true)
  end
  self:executeCall(call, new_staff)
end
```

---

## 7. Integration Points

### World Tick

```lua
function CallsDispatcher:onTick()
  self.tick = self.tick + 1
end
```
Called every game tick. Used for call timestamps.

### Staff Lifecycle

- `Staff:onPickUp()` → `dropFromQueue(self)` (entity.lua:293)
- `Staff:setNextAction(AnswerCallAction())` → triggers `answerCall` when action runs
- `CallCheckPointAction` interrupt → `actionInterruptHandler` or `staffActionInterruptHandler`

### Room Lifecycle

- `Room:callForStaff()` → triggered by room's staff requirement check
- `Hospital:notifyRoomRemoved(room)` → `dispatcher:dropFromQueue(room)` (hospital.lua:657)

### Save/Load (Persistable Callbacks)

The `persistable:` prefix in callback comments indicates these functions must be:
- Pure functions (no upvalues referencing non-serializable objects)
- Re-loadable after game load
- Identical across save/load cycles

---

## 8. Known Issues / TODOs (from source)

1. **Preemption in `findSuitableStaff`** (line 289-293): New urgent calls (machine breakdown) should preempt staff already on lower-priority calls (watering distant plant)

2. **Doctor room assignment** (line 292-293): Doctors could serve rooms with actual patients even if other rooms have queued patients

3. **Specialist assignment** (line 523): "Assign doctor with higher ability" — not implemented

4. **Handyman unification**: Handymen bypass normal verification/priority via `searchForHandymanTask`

---

## 9. File References

| File | Key Lines |
|------|-----------|
| Lua/calls_dispatcher.lua | 1-567 (entire file) |
| Lua/hospital.lua | 657 (notifyRoomRemoved) |
| Lua/entity.lua | 293 (onPickUp drop) |
| Lua/staff.lua | `searchForHandymanTask`, `AnswerCallAction` |
| Lua/actions.lua | `CallCheckPointAction`, `AnswerCallAction` |

---

*Generated from CorsixTH source analysis. Total: ~567 lines in calls_dispatcher.lua*


## Related Pages

- [[15-calls-dispatcher/CHECKLIST]]
- [[15-calls-dispatcher/MAP]]
- [[15-calls-dispatcher/SCAFFOLD]]
