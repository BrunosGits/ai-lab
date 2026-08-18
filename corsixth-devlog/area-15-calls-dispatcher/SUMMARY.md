# CallsDispatcher Deep Research - CorsixTH

## Overview

The `CallsDispatcher` class (`/tmp/CorsixTH/CorsixTH/Lua/calls_dispatcher.lua`) is the central job queue and assignment system in CorsixTH. It manages all "calls" — requests for staff to perform tasks — and matches them with available staff members based on verification, priority scoring, and execution callbacks.

---

## 1. Call Queue Structure

### Data Structure: `call_queue[object][key]`

The call queue is a nested table indexed by **object** (the entity requesting work) and **key** (the call type identifier):

```lua
self.call_queue = {
  [room] = {
    ["doctor-1"] = { ... call table ... },
    ["nurse-2"] = { ... call table ... },
  },
  [machine] = {
    ["repair"] = { ... call table ... },
  },
  [plant] = {
    ["watering"] = { ... call table ... },
  },
  [patient] = {
    ["vaccinate"] = { ... call table ... },
  },
}
```

- **object**: Any entity that can request work (Room, Machine, Plant, Patient)
- **key**: String identifier for the call type (`"repair"`, `"watering"`, `"vaccinate"`, or staff attribute + index like `"doctor1"`)

### Call Table Fields

Every call table contains:

| Field | Type | Description |
|-------|------|-------------|
| `verification` | function(staff) → bool | Returns true if staff member is eligible for this call |
| `priority` | function(staff) → number | Returns a score (lower = higher priority) |
| `execute` | function(staff) → nil | Action to perform when staff accepts the call |
| `object` | Entity | The object that created the call |
| `key` | string | Call type identifier |
| `description` | string | Human-readable description for debugging |
| `dispatcher` | CallsDispatcher | Back-reference to dispatcher |
| `created` | number | Tick when call was created |
| `assigned` | Staff \| nil | Currently assigned staff member |
| `dropped` | bool | Whether call has been cancelled/removed |

---

## 2. Call Types

### 2.1 Staff Calls (`callForStaff`, `callForStaffEachRoom`)

**Created by**: Rooms needing staff (GP Office, Ward, Pharmacy, etc.)

**Trigger**: Room detects missing required staff via `room:getMissingStaff(room:getRequiredStaffCriteria())`

**Verification** (`verifyStaffForRoom`):
- Staff must be idle
- Staff must fulfill the required criterion (Doctor, Nurse, Researcher, etc.)
- If `staff_allowed_to_move` policy is false, staff must not be in another room

**Priority** (`getPriorityForRoom`):
- Path distance to room entrance (closer = better)
- Queue size penalty: `- queue_size * 5`
- Emergency patient bonus: `- 200000`
- Fatigue bonus: `- fatigue * 40` (tired staff preferred to prevent sync issues)
- Wandering bonus: `- 50` if not in a room
- Specialist bonus: `- 100000` for Researcher/Psychiatrist/Surgeon

**Execute** (`sendStaffToRoom`):
- If already in room: leave and re-enter (triggers room logic)
- Else: queue enter action + checkpoint

**Key format**: `"attribute" + index` (e.g., `"doctor1"`, `"nurse2"`)

---

### 2.2 Repair Calls (`callForRepair`)

**Created by**: Machines when they break down (`Machine:breakDown`)

**Parameters**:
- `object`: The machine needing repair
- `urgent`: Boolean, triggers advisor warning
- `manual`: Boolean, suppresses "machines falling apart" advisor

**Verification**: Always returns `false` (handymen don't use dispatcher verification)

**Priority**: Always returns `1`

**Execute** (`sendStaffToRepair`):
- Delegates to `object:createHandymanActions(handyman)`
- Machine creates meander → walk → repair action sequence
- Adds checkpoint action

**Key**: `"repair"`

---

### 2.3 Watering Calls (`callForWatering`)

**Created by**: Plants when they need water (`Plant:update`)

**Verification**: Always returns `false`

**Priority**: Always returns `1`

**Execute** (`sendStaffToWatering`):
- Delegates to `plant:createHandymanActions(handyman)`

**Key**: `"watering"`

---

### 2.4 Cleaning Calls

**Note**: Cleaning is handled **outside** the CallsDispatcher. Handymen search for cleaning tasks via `Hospital:searchForHandymanTask(handyman, "cleaning")` which scans `hospital.handyman_tasks.cleaning` subtable. This is a separate task system, not the call queue.

---

### 2.5 Vaccination Calls (`callNurseForVaccination`)

**Created by**: Patients during epidemics (`Patient:requestVaccination`)

**Verification** (`verifyStaffForVaccination`):
- Must be a Nurse
- Must be idle
- Must not be in a room
- Patient must not be in a room
- Both must be within 5 tiles of each other

**Priority** (`getPriorityForVaccination`):
- Path distance (lower = better)
- Unreachable penalty: `+ 10000`

**Execute** (`sendNurseToVaccinate`):
- Delegates to `Epidemic:createVaccinationActions(patient, nurse)`
- If epidemic ended: immediate completion

**Key**: `"vaccinate"`

---

## 3. Verification / Priority / Execute Callbacks

### Pattern

Every call type provides three persistable callbacks (marked with `--[[persistable:...]]` for save/load):

```lua
local call = {
  verification = function(staff) return ... end,
  priority     = function(staff) return ... end,
  execute      = function(staff) ... end,
  ...
}
```

### Verification Callback
- **Purpose**: Filter eligible staff
- **Returns**: `true` if staff can handle this call, `false` otherwise
- **Called by**: `findSuitableStaff` and `answerCall`

### Priority Callback
- **Purpose**: Rank eligible staff (lower score = higher priority)
- **Returns**: Number score, or `nil` if not eligible
- **Called by**: `findSuitableStaff` and `answerCall`

### Execute Callback
- **Purpose**: Perform the actual work assignment
- **Called by**: `executeCall` after assignment
- **Must**: Queue actions on the staff member and add a `CallCheckPointAction`

---

## 4. Dispatch Algorithm

### 4.1 `findSuitableStaff(call)` — Called when call is enqueued

```lua
function CallsDispatcher:findSuitableStaff(call)
  if call.dropped then return end
  
  local min_score = 2^30
  local min_staff = nil
  
  for _, e in ipairs(self.world.entities) do
    if class.is(e, Staff) and not class.is(e, Handyman) then
      local score = call.verification(e) and call.priority(e) or nil
      if score ~= nil and score < min_score then
        min_score = score
        min_staff = e
      end
    end
  end
  
  if min_staff then
    self:executeCall(call, min_staff)  -- Assign immediately
    return true
  else
    self:onChange()  -- Notify UI, call stays queued
    return false
  end
end
```

**Key characteristics**:
- Iterates **ALL entities** in world (`self.world.entities`)
- Filters to `Staff` but **excludes `Handyman`** (handymen use separate task system)
- Finds single best match by priority score
- If found: executes immediately (call never enters queue visibly)
- If not found: queues call, fires `onChange` callback

**TODO comments in code**:
- Preempt staff already on_call (e.g., handyman watering far plant → preempt for nearby repair)
- Doctor could go to other room with real needs despite queued patients

---

### 4.2 `answerCall(staff)` — Called when staff becomes idle

```lua
function CallsDispatcher:answerCall(staff)
  assert(not staff.on_call, "Staff already on call")
  
  if class.is(staff, Handyman) then
    staff:searchForHandymanTask()  -- Handymen use separate system
    return true
  end
  
  local min_score = 2^30
  local min_call = nil
  
  for _, queue in pairs(self.call_queue) do
    for _, call in pairs(queue) do
      local score = call.verification(staff) and call.priority(staff) or nil
      if score ~= nil then
        -- Preemption check
        if call.assigned then
          local another_score = call.priority(call.assigned)
          if another_score <= score then
            score = nil  -- Can't preempt
          end
        end
        if score ~= nil and score < min_score then
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
    assert(min_call.object.tile_x or min_call.object.x, "Destroyed object in queue")
    self:executeCall(min_call, staff)
    return true
  end
  return false
end
```

**Key characteristics**:
- Staff-initiated: called when staff goes to meandering/idle state
- Scans **entire call queue** (all objects, all keys)
- **Preemption logic**: If call already assigned, compares priority scores
  - If current staff has *better or equal* priority (`another_score <= score`), cannot preempt
  - If new staff has *strictly better* priority (`score < another_score`), preempts
- On preemption: `unassignCall(call, true)` → old staff gets `AnswerCallAction()` to find new work
- Validates object still exists in world

---

## 5. Preemption Logic

### When Preemption Occurs

1. **Staff-initiated** (`answerCall`): Idle staff finds a call where they have strictly better priority than currently assigned staff
2. **Call-initiated** (`findSuitableStaff`): **Does NOT preempt** — only assigns to unassigned calls

### Preemption Flow

```lua
-- In answerCall:
if min_call.assigned then
  CallsDispatcher.unassignCall(min_call, true)  -- true = answer next call
end
self:executeCall(min_call, staff)
```

### `unassignCall(call, answer_next_call)`

```lua
function CallsDispatcher.unassignCall(call, answer_next_call)
  local assigned = call.assigned
  assert(assigned.on_call == call)
  call.assigned = nil
  assigned.on_call = nil
  if answer_next_call then
    assigned:setNextAction(AnswerCallAction())  -- Old staff looks for new work
  end
end
```

### Interrupt Handlers (Checkpoint Actions)

When a staff member is interrupted mid-task (preempted, picked up, call dropped):

```lua
-- Default handler (actionInterruptHandler)
function CallsDispatcher.actionInterruptHandler(action, humanoid)
  if action.call.assigned == humanoid then
    action.call.assigned = nil
    humanoid.on_call = nil
    humanoid.world.dispatcher:findSuitableStaff(action.call)  -- Re-queue call
  end
end

-- Staff-specific handler (staffActionInterruptHandler)
function CallsDispatcher.staffActionInterruptHandler(action, humanoid)
  if action.call.assigned == humanoid then
    action.call.assigned = nil
    humanoid.on_call = nil
    if not action.call.dropped then
      humanoid.world.dispatcher:callForStaff(action.call.object)  -- Re-create staff call
    end
  end
end
```

---

## 6. Drop Mechanism

### 6.1 `dropFromQueue(object, key)`

```lua
function CallsDispatcher:dropFromQueue(object, key)
  if key and self.call_queue[object] then
    local call = self.call_queue[object][key]
    if call then
      call.dropped = true
      if call.assigned then
        CallsDispatcher.unassignCall(call, true)  -- Unassign staff, they find new work
      end
      self.call_queue[object][key] = nil
    end
  elseif self.call_queue[object] then
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

**Two modes**:
- **Specific key**: Drop single call type for object
- **No key**: Drop ALL calls for object

### 6.2 Drop Triggers

| Trigger | Location | Code |
|---------|----------|------|
| Entity picked up | `Entity:onPickUp()` (entity.lua:293) | `self.world.dispatcher:dropFromQueue(self)` |
| Room removed/deactivated | `World:notifyRoomRemoved()` (world.lua:657) | `self.dispatcher:dropFromQueue(room)` |
| Call completed | `CallsDispatcher.onCheckpointCompleted()` (calls_dispatcher.lua:421) | `call.dispatcher:dropFromQueue(call.object, call.key)` |
| Machine replaced | `Machine:replaceMachine()` (machine.lua:363) | `self:removeHandymanRepairTask()` → drops repair call |
| Machine repaired | `Machine:machineRepaired()` (machine.lua:382) | `self:removeHandymanRepairTask()` |

### 6.3 `onPickUp` Drop (entity.lua:293)

```lua
function Entity:onPickUp()
  self.world.dispatcher:dropFromQueue(self)
end
```

- Called when player picks up any entity (machine, plant, room object)
- Drops **ALL** calls for that object (no key specified)
- Staff assigned to dropped calls get `AnswerCallAction()` to find new work

### 6.4 `notifyRoomRemoved` Drop (world.lua:657)

```lua
function World:notifyRoomRemoved(room)
  self.dispatcher:dropFromQueue(room)
  for callback in pairs(self.room_remove_callbacks) do
    callback(room)
  end
end
```

- Called when room is deactivated (crashed, edited, deleted)
- Drops all staff calls for that room
- Room calls use keys like `"doctor1"`, `"nurse2"` — all dropped

---

## 7. Code Examples

### Example 1: Enqueueing a Staff Call

```lua
-- Room detects missing doctor
function CallsDispatcher:callForStaff(room)
  local missing = room:getMissingStaff(room:getRequiredStaffCriteria())
  for attribute, count in pairs(missing) do
    for i = 1, count do
      self:callForStaffEachRoom(room, attribute, attribute .. i)
    end
  end
end

function CallsDispatcher:callForStaffEachRoom(room, attribute, key)
  local new_call = self:enqueue(
    room,
    key,
    _S.calls_dispatcher.staff:format(room.room_info.name, attribute),
    function(staff) return CallsDispatcher.verifyStaffForRoom(room, attribute, staff) end,
    function(staff) return CallsDispatcher.getPriorityForRoom(room, attribute, staff) end,
    function(staff) return CallsDispatcher.sendStaffToRoom(room, staff) end
  )
end
```

### Example 2: Enqueueing a Repair Call

```lua
function CallsDispatcher:callForRepair(object, urgent, manual)
  local call = {
    verification = function() return false end,
    priority = function() return 1 end,
    execute = function(staff) return CallsDispatcher.sendStaffToRepair(object, staff) end,
    object = object,
    key = "repair",
    description = _S.calls_dispatcher.repair:format(object.object_type.name),
    dispatcher = self,
    created = self.tick,
    assigned = nil,
    dropped = nil
  }
  
  if not self.call_queue[object] then
    self.call_queue[object] = {}
  end
  self.call_queue[object]["repair"] = call
  return call
end
```

### Example 3: Staff Answering a Call

```lua
-- In humanoid_actions/meander.lua
function MeanderAction:update(action, humanoid)
  if humanoid:searchForHandymanTask() == true then
    return  -- Handyman found task
  end
  -- For non-handymen:
  if humanoid.world.dispatcher:answerCall(humanoid) then
    return  -- Found and started a call
  end
  -- No calls available, continue meandering
end
```

### Example 4: Checkpoint Completion

```lua
-- In humanoid_actions/call_checkpoint.lua
local function action_call_checkpoint_start(action, humanoid)
  action.must_happen = true
  CallsDispatcher.onCheckpointCompleted(action.call)
  humanoid:finishAction(action)
end

-- In calls_dispatcher.lua
function CallsDispatcher.onCheckpointCompleted(call)
  if not call.dropped and call.assigned then
    call.assigned.on_call = nil
    call.assigned = nil
    call.dispatcher:dropFromQueue(call.object, call.key)
  end
end
```

### Example 5: Preemption in Action

```lua
-- Staff A (junior doctor) assigned to Room 1 (score: 50)
-- Staff B (consultant doctor) becomes idle, checks calls
-- Room 1 call priority for Staff B = 25 (better due to consultant multiplier)
-- In answerCall:
if min_call.assigned then  -- Staff A
  CallsDispatcher.unassignCall(min_call, true)  -- Staff A gets AnswerCallAction
end
self:executeCall(min_call, staff)  -- Staff B gets the call
```

---

## 8. Save/Load Persistence

Callbacks are marked with `--[[persistable:call_dispatcher_<type>_<callback>]]` comments for the persistence system:

- `call_dispatcher_staff_verification`
- `call_dispatcher_staff_priority`
- `call_dispatcher_staff_execute`
- `call_dispatcher_repair_verification`
- `call_dispatcher_repair_priority`
- `call_dispatcher_repair_execute`
- `call_dispatcher_watering_verification`
- `call_dispatcher_watering_priority`
- `call_dispatcher_watering_execute`
- `call_dispatcher_vaccinate_verification`
- `call_dispatcher_vaccinate_priority`
- `call_dispatcher_vaccinate_execute`

The `call_queue` table itself is persisted, with `assigned` and `dropped` flags maintaining state across saves.

---

## 9. Debugging Support

```lua
local debug_enabled = false  -- Set to true for debug output

function CallsDispatcher:dump()
  print("--- Queue ---")
  for _, queue in pairs(self.call_queue) do
    for _, call in pairs(queue) do
      CallsDispatcher.dumpCall(call, (call.assigned and 'assigned' or 'unassigned'))
    end
  end
  print("----")
end

function CallsDispatcher.dumpCall(call, message)
  -- Prints: key@position : message
  -- e.g., "doctor1@10,5 : assigned"
end
```

UI debugger available at `Lua/dialogs/resizables/calls_dispatcher.lua` (accessible via debug menu).

---

## 10. Key Files Summary

| File | Purpose |
|------|---------|
| `calls_dispatcher.lua` | Main dispatcher implementation (567 lines) |
| `hospital.lua:657` | `notifyRoomRemoved` → drops room calls |
| `entity.lua:293` | `onPickUp` → drops all calls for entity |
| `world.lua:656` | `World:notifyRoomRemoved` bridge |
| `room.lua:1017` | `Room:deactivate` → triggers notifyRoomRemoved |
| `staff.lua:307` | Debug dump shows `on_call` |
| `handyman.lua:212` | `unassignCall` for handymen |
| `humanoid.lua:506` | `setCallCompleted` → checkpoint completion |
| `call_checkpoint.lua` | Checkpoint action implementation |
| `answer_call.lua` | AnswerCall action implementation |
| `machine.lua:343` | Repair action adds checkpoint |
| `plant.lua:227` | Watering action adds checkpoint |

---

*Document generated from CorsixTH source code analysis*
*Primary file: `/tmp/CorsixTH/CorsixTH/Lua/calls_dispatcher.lua` (567 lines)*
