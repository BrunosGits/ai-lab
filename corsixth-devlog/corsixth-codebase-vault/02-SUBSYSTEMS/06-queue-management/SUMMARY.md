# Queue Management in CorsixTH — Deep Research Document

## Overview

The queue management system in CorsixTH handles the orderly processing of humanoids (patients, staff, VIPs, Inspectors) waiting to use doors or reception desks. It is implemented primarily in `Lua/queue.lua` (384 lines) with integration points in door objects, reception desks, room logic, and humanoid actions.

The system manages **two distinct queue types**:
- **Door queues** (`Lua/objects/door.lua`) — for room entry/exit via doors
- **Reception desk queues** (`Lua/objects/reception_desk.lua`) — for patient check-in at reception

---

## 1. Queue Class (`Lua/queue.lua`)

### 1.1 Core Data Structure

```lua
class "Queue"
function Queue:Queue()
  self.reported_size = 0      -- Number of real patients visible in door queue UI
  self.expected = {}          -- Humanoids expected to join (with callbacks)
  self.expected_count = 0     -- Count of expected patients only
  self.callbacks = {}         -- Per-humanoid callbacks for queue events
  self.visitor_count = 0      -- Total patients who have passed through
  self.max_size = 6           -- Maximum queue length (default)
  self.bench_threshold = 0    -- Number of people kept standing even if benches exist
  self.same_room_priority = nil  -- Entity whose room gets leaving priority
end
```

The queue is a **Lua array** (1-indexed) where `self[i]` is a humanoid. Access must go through methods.

### 1.2 Size & Capacity Methods

| Method | Purpose |
|--------|---------|
| `Queue:size()` | Total humanoids in queue (patients + staff + leaving) |
| `Queue:reportedSize()` | Real patients only (displayed in UI) |
| `Queue:expectedSize()` | Patients expected to arrive soon |
| `Queue:patientSize()` | `reportedSize() + expectedSize()` |
| `Queue:isFull()` | `size() >= max_size` |
| `Queue:hasEmergencyPatient()` | Scans for `humanoid.is_emergency` |
| `Queue:setMaxQueue(n)` | Set max size (clamped 0–30) |
| `Queue:increaseMaxSize(n)` / `decreaseMaxSize(n)` | Increment/decrement max size |
| `Queue:setBenchThreshold(n)` | People kept standing (reception default: 3) |

**Key distinction**: `size()` includes staff waiting to enter and patients waiting to leave. `reportedSize()` is patients waiting to be served. Usually equal, but diverge when staff/exiting patients are present.

### 1.3 Priority System (Lower = Higher Priority)

Defined in `_getHumanoidQueuePriority(queue, humanoid)` (lines 166–188):

| Priority | Value | Condition |
|----------|-------|-----------|
| **1 — Leaving** | 1 | `_isLeaving(queue, humanoid)` true (same room as `same_room_priority`) |
| **2 — Staff** | 2 | `class.is(humanoid, Staff)` |
| **3 — VIP/Inspector** | 3 | `class.is(humanoid, Vip)` or `class.is(humanoid, Inspector)` |
| **4 — Emergency** | 4 | `humanoid.is_emergency` |
| **5 — Queue-jump cheat** | 5 | Cheat active AND `health < 0.10` |
| **6 — Regular** | 6 | All other patients |

**Display filter** (`_shouldDisplayInDoorQueueInterface`, line 194–197):
- `reported_priority_threshold = 3`
- Only priorities **> 3** (i.e., 4, 5, 6) show in door queue UI
- Leaving (1), Staff (2), VIP/Inspector (3) are **hidden** from patient queue display

### 1.4 Queue Operations

#### `Queue:push(humanoid, callbacks_on)` — Lines 201–231
Inserts humanoid at correct priority position (higher priority = smaller index).
```lua
local index = self:size() + 1
local priority = _getHumanoidQueuePriority(self, humanoid)
while index > 1 do
  if _getHumanoidQueuePriority(self, self[index - 1]) <= priority then break end
  index = index - 1
end
if _shouldDisplayInDoorQueueInterface(priority) then
  self.reported_size = self.reported_size + 1
end
self.callbacks[humanoid] = callbacks_on
table.insert(self, index, humanoid)
-- Notify shifted humanoids of position change
for i = index + 1, self:size() do
  callbacks = self.callbacks[self[i]]
  if callbacks then callbacks:onChangeQueuePosition(self[i]) end
end
```

#### `Queue:pop()` — Lines 249–268
Removes and returns front humanoid. Adjusts `reported_size` if popped was a displayed patient.
```lua
if self.reported_size == self:size() then
  self.reported_size = self.reported_size - 1
end
local oldfront = self[1]
table.remove(self, 1)
oldfront:setMood("queue", "deactivate")
-- callbacks:onLeaveQueue(oldfront)
-- Notify all remaining of position change
```

#### `Queue:remove(index)` — Lines 274–292
Removes by absolute index. Used when a specific humanoid leaves queue.
```lua
if index > self:size() - self.reported_size then
  self.reported_size = self.reported_size - 1  -- Was a displayed patient
end
value:setMood("queue", "deactivate")
table.remove(self, index)
-- Notify humanoids at index..end of position change via onAdvanceQueue
```

#### `Queue:removeValue(value)` — Lines 297–305
Finds and removes by reference. Returns `true` if found.

#### `Queue:move(index, new_index)` — Lines 311–329
Swaps adjacent positions iteratively to move a humanoid. Used for UI drag-drop reordering.
```lua
while new_index ~= index do
  local temp = self[index + i]
  self[index + i] = self[index]
  self[index] = temp
  index = index + i
end
```

#### `Queue:movePatient(index, new_index)` — Lines 337–349
Moves **relative to reported patients only** (ignores staff/leaving at front).
- `first_patient_index = size() - reportedSize() + 1`
- `new_index` can be `'front'`, `'back'`, or numeric offset
- Delegates to `move()`

#### `Queue:front()` / `Queue:back()` — Lines 236–244
Return first/last element (may not be a patient).

#### `Queue:reportedHumanoid(index)` — Lines 148–150
Gets the `index`-th **reported patient** (1 = front of patient queue).
```lua
return self[self:size() - self.reported_size + index]
```

### 1.5 Expected Humanoids & Callbacks

```lua
Queue:expect(humanoid, callback)   -- Register expected arrival
Queue:unexpect(humanoid)           -- Cancel expectation
```
Only patients increment `expected_count`. Callbacks fire when queue is destroyed.

### 1.6 Reroute on Destruction

`Queue:rerouteAllPatients(room_id)` — Lines 353–384
Called when door/reception is destroyed. Redirects all queued humanoids:
- **Patients** → `SeekRoomAction(room_id)` or `SeekReceptionAction()`
- **Staff** → `MeanderAction()`
- **Others** → `MeanderAction()`
- Calls all `expected` callbacks and clears expected list.

---

## 2. Door Queues (`Lua/objects/door.lua`)

### 2.1 Initialization
```lua
function Door:Door(...)
  self:Object(...)
  self.queue = Queue()
  self.queue:setPriorityForSameRoom(self)  -- Leaving priority for this room
  self.hover_cursor = TheApp.gfx:loadMainCursor("queue")
end
```

### 2.2 Room Edit Persistence
```lua
function Door:setupDoor(room, old_door)
  if old_door and old_door.queue then
    self.queue.visitor_count = old_door.queue.visitor_count
    self.queue.max_size = old_door.queue.max_size
  end
  self.room = room
end
```

### 2.3 Dynamic Info (Tooltip)
```lua
function Door:updateDynamicInfo()
  if self.room and self.queue then
    if not self.room:hasQueueDialog() then
      self:setDynamicInfo('text', { self.room.room_info.name })
    else
      self:setDynamicInfo('text', {
        self.room.room_info.name,
        _S.dynamic_info.object.queue_size:format(self.queue:reportedSize()),
        _S.dynamic_info.object.queue_expected:format(self.queue:expectedSize())
      })
    end
  end
end
```

### 2.4 Click Handling
```lua
function Door:onClick(ui, button)
  if button == "left" and room:hasQueueDialog() and self.queue then
    local queue_window = UIQueue(ui, self.queue)
    ui:addWindow(queue_window)
  end
end
```

### 2.5 Close & Deadlock Check
```lua
function Door:closeDoor()
  if self.queue then
    self.queue:rerouteAllPatients(self:getRoom().room_info.id)
    self.queue = nil
  end
  self:clearDynamicInfo(nil)
  self.hover_cursor = nil
end

function Door:checkForDeadlock()
  if self.queue and self.reserved_for then
    for _, action in ipairs(self.reserved_for.action_queue) do
      if action.name == "queue" then
        if action.queue ~= self.queue or self.queue[1] ~= self.reserved_for then
          self.world:gameLog("Warning: Trying to resolve door deadlock...")
          self.reserved_for = nil
          self:getRoom():tryAdvanceQueue()
        end
        break
      end
    end
  end
end
```

---

## 3. Reception Desk Queues (`Lua/objects/reception_desk.lua`)

### 3.1 Initialization
```lua
function ReceptionDesk:ReceptionDesk(...)
  self:Object(...)
  self.queue = Queue()
  self.queue:setBenchThreshold(3)     -- Keep 3 standing even with benches
  self.queue:setMaxQueue(20)          -- Larger than door default (6)
  self.hover_cursor = TheApp.gfx:loadMainCursor("queue")
  self.queue_advance_timer = 0
end
```

### 3.2 Tick Processing
```lua
function ReceptionDesk:tick()
  local function advanceQueue(humanoid)
    if humanoid:getCurrentAction().name == "idle" then
      self.queue_advance_timer = self.queue_advance_timer + 1
    end
    return self.queue_advance_timer >= 4 + Date.hoursPerDay() * (1.0 - self.receptionist.profile.skill)
  end

  local front_humanoid = self.queue:front()
  if self.receptionist and front_humanoid then
    if not advanceQueue(front_humanoid) then return end  -- Wait

    if class.is(front_humanoid, Patient) then
      -- New patient → GP if agrees to pay, else go home
      -- Redirected patient → send to next room
    elseif class.is(front_humanoid, Inspector) then
      -- Handle epidemic, then go home
    elseif class.is(front_humanoid, Vip) then
      -- Idle action, set waiting
    end

    self.queue:pop()
    self.queue.visitor_count = self.queue.visitor_count + 1
    front_humanoid.has_passed_reception = true
    self.queue_advance_timer = 0
  end
end
```

### 3.3 Usage Score (for patient routing)
```lua
local tile_factor = 10
function ReceptionDesk:getUsageScore()
  local score = self.queue:patientSize() * tile_factor
  if self.queue:isFull() then score = score + 1000 end
  return score
end
```

### 3.4 Destruction Reroute
```lua
function ReceptionDesk:resetUsageAndReservaton()
  self.being_destroyed = true
  -- ... handle receptionist ...
  self.queue:rerouteAllPatients(nil)  -- nil = reception
  self.being_destroyed = nil
end
```

---

## 4. Room Queue Advancement (`[[Lua/room.lua#L549]]-565`)

```lua
function Room:tryAdvanceQueue()
  if self.door.queue and self.door.queue:size() > 0 and not self.door.user and not self.door.reserved_for then
    local front = self.door.queue:front()
    
    if self:canHumanoidEnter(front) then
      self.door.queue:pop()
      self.door:updateDynamicInfo()
      if self:_checkWaitToggleValidTarget() then
        self:_staffWaitToggle(true)  -- Staff are now waiting
      end
    elseif self.humanoids[front] then
      -- Already in room (race condition fix)
      self.door.queue:pop()
      self.door:updateDynamicInfo()
    end
  end
end
```

**Called from:**
- `Room:onHumanoidEnter` (after staff/patient enters)
- `Room:onHumanoidLeave` (after humanoid leaves)
- `Door:checkForDeadlock` (deadlock resolution)
- `QueueAction:action_queue_start` (when humanoid joins queue)
- `humanoid_actions/walk.lua`, `knock_door.lua`, `swing_door_right.lua` (door traversal)

---

## 5. Humanoid Queue Action (`Lua/humanoid_actions/queue.lua`)

### 5.1 QueueAction Creation
```lua
function QueueAction:QueueAction(x, y, queue)
  self:HumanoidAction("queue")
  self.x, self.y = x, y
  self.queue = queue
  self.reserve_when_done = nil  -- Door to reserve when leaving queue
end
```

### 5.2 Start (when action executes)
```lua
local function action_queue_start(action, humanoid)
  action.done_init = true
  action.must_happen = true
  action.on_interrupt = action_queue_interrupt
  action.onChangeQueuePosition = action_queue_on_change_position
  action.onLeaveQueue = action_queue_on_leave
  action.onGetSoda = action_queue_get_soda
  action.isStanding = action_queue_is_standing
  action.is_in_queue = true
  
  action.queue:unexpect(humanoid)
  action.queue:push(humanoid, action)
  
  if action.reserve_when_done then
    action.reserve_when_done:updateDynamicInfo()
  end
  humanoid:queueAction(IdleAction():setMustHappen(true):setIsLeaving(humanoid:isLeaving()), 0)
  action:onChangeQueuePosition(humanoid)
  
  if action.queue.same_room_priority then
    action.queue.same_room_priority:getRoom():tryAdvanceQueue()
  end
end
```

### 5.3 Position Change — Bench Logic
`action_queue_on_change_position` (lines 201–304):
1. **Must stand if**: not a Patient, is leaving, has disease requiring standing
2. **Bench threshold**: First `queue.bench_threshold` reported patients must stand (reception: 3)
3. **Sit down if**: beyond threshold, find free bench within distance thresholds
4. **Stand up**: Walk to correct standing position in queue based on `standing_index`

### 5.4 Interrupt & Leave
```lua
local action_queue_interrupt = function(action, humanoid)
  if action.is_in_queue then
    action.queue:removeValue(humanoid)
    if action.reserve_when_done then action.reserve_when_done:updateDynamicInfo() end
  end
  if action.reserve_when_done and action.reserve_when_done:isReservedFor(humanoid) then
    action.reserve_when_done:removeReservedUser(humanoid)
  end
  humanoid:finishAction()
end
```

---

## 6. UI Queue Dialog (`Lua/dialogs/queue_dialog.lua`)

### 6.1 Display Metrics
- **Num in queue**: `queue:reportedSize()`
- **Num expected**: `queue:expectedSize()`
- **Num entered**: `queue.visitor_count`
- **Max queue size**: `queue.max_size` (adjustable via +/- buttons)

### 6.2 Patient Drag-Drop Reordering
- Click-drag patient sprite within queue area → `queue:movePatient(index, new_pos)`
- Drop on **door icon** (front) → `movePatient(index, 'front')`
- Drop on **exit sign** (back) → `movePatient(index, 'back')`
- Drop on **another room** of same type → reroute patient to that room

### 6.3 Right-Click Popup
- **Send to Reception** → `SeekReceptionAction()`
- **Send Home** → `goHome("kicked")`

---

## 7. Priority & Display Summary

| Entity Type | Priority | Shown in Door Queue UI? | Bench Threshold Applies? |
|-------------|----------|------------------------|-------------------------|
| Leaving (same room) | 1 | ❌ (≤3) | N/A (leaving) |
| Staff | 2 | ❌ (≤3) | ❌ (not patient) |
| VIP / Inspector | 3 | ❌ (≤3) | ❌ (not patient) |
| Emergency Patient | 4 | ✅ (>3) | ✅ if in first N |
| Queue-jump Cheat | 5 | ✅ (>3) | ✅ if in first N |
| Regular Patient | 6 | ✅ (>3) | ✅ if in first N |

**Bench threshold** (`queue.bench_threshold`):
- Door queues: 0 (all sit if benches available)
- Reception desk: 3 (first 3 patients stand)
- Evaluated in `action_queue_on_change_position` lines 212–217

---

## 8. Key Integration Points

| File | Line | Operation |
|------|------|-----------|
| `queue.lua` | 201 | `push()` — priority insert |
| `queue.lua` | 249 | `pop()` — remove front |
| `queue.lua` | 274 | `remove(index)` — remove by index |
| `queue.lua` | 297 | `removeValue()` — remove by reference |
| `queue.lua` | 311 | `move()` — swap positions |
| `queue.lua` | 337 | `movePatient()` — UI reorder |
| `queue.lua` | 353 | `rerouteAllPatients()` — destruction |
| `door.lua` | 42 | Door queue creation |
| `door.lua` | 47 | `setPriorityForSameRoom(self)` |
| `door.lua` | 159 | `closeDoor()` → reroute |
| `door.lua` | 171 | `checkForDeadlock()` |
| `reception_desk.lua` | 78 | Reception queue creation |
| `reception_desk.lua` | 79 | `setBenchThreshold(3)` |
| `reception_desk.lua` | 80 | `setMaxQueue(20)` |
| `reception_desk.lua` | 144 | `tick()` — process front |
| `reception_desk.lua` | 240 | `resetUsageAndReservaton()` → reroute |
| `room.lua` | 549 | `tryAdvanceQueue()` — core advancement |
| `humanoid_actions/queue.lua` | 371 | `action_queue_start()` — join queue |
| `humanoid_actions/queue.lua` | 201 | `onChangeQueuePosition` — bench/stand |
| `dialogs/queue_dialog.lua` | 184 | UI drag to front/back |
| `dialogs/queue_dialog.lua` | 400 | UI send to reception/home |

---

## 9. Code Examples

### 9.1 Creating a Custom Queue
```lua
local queue = Queue()
queue:setMaxQueue(10)
queue:setBenchThreshold(2)
queue:setPriorityForSameRoom(myDoor)  -- Enable leaving priority
```

### 9.2 Adding a Humanoid to Queue
```lua
local action = QueueAction(x, y, queue)
action:setReserveWhenDone(door)
action:setFaceDirection(door.tile_x, door.tile_y)
humanoid:setNextAction(action)
```

### 9.3 Checking Queue State
```lua
if queue:isFull() then
  -- Queue full logic
end

if queue:hasEmergencyPatient() then
  -- Emergency handling
end

local patient = queue:reportedHumanoid(1)  -- First waiting patient
```

### 9.4 Programmatic Reordering
```lua
-- Move 3rd patient to front
queue:movePatient(3, 'front')

-- Move 1st patient to back
queue:movePatient(1, 'back')

-- Move patient at absolute index 5 to index 2
queue:move(5, 2)
```

### 9.5 Handling Queue Destruction
```lua
function MyObject:onDestroy()
  if self.queue then
    self.queue:rerouteAllPatients(target_room_id or nil)
    self.queue = nil
  end
end
```

---

## 10. Edge Cases & Known Behaviors

1. **Staff in patient queue**: Staff get priority 2, appear in `size()` but not `reportedSize()`. They block patients from entering until they clear.

2. **Leaving patients**: Get priority 1 (highest) when `same_room_priority` is set. Prevents deadlock where entering patient blocks leaving patient.

3. **VIP/Inspector instant service**: Priority 3, hidden from UI, processed immediately at reception.

4. **Queue-jump cheat**: Only activates for critical health (<10%) when cheat enabled.

5. **Bench threshold**: Only affects patients beyond threshold who aren't forced to stand (disease, leaving). First N reported patients stand.

6. **Expected humanoids**: Tracked separately; increment `expected_count` only for patients. Callbacks fire on destruction.

7. **Deadlock detection**: `Door:checkForDeadlock()` verifies reserved humanoid is at queue front.

8. **Race condition fix**: `tryAdvanceQueue()` checks `self.humanoids[front]` — if already in room, pop without entry check.

---

## 11. Configuration Constants

| Constant | Default | Location |
|----------|---------|----------|
| Default max queue (door) | 6 | `queue.lua:47` |
| Default max queue (reception) | 20 | `reception_desk.lua:80` |
| Max queue clamp | 30 | `queue.lua:85` |
| Bench threshold (door) | 0 | `queue.lua:48` |
| Bench threshold (reception) | 3 | `reception_desk.lua:79` |
| Display priority threshold | 3 | `queue.lua:195` |
| Tile factor (reception score) | 10 | `reception_desk.lua:197` |
| Full queue penalty | 1000 | `reception_desk.lua:202` |
| Reception advance base time | 4 ticks | `reception_desk.lua:137` |

---

*End of SUMMARY.md*


## Related Pages

- [[06-queue-management/CHECKLIST]]
- [[06-queue-management/MAP]]
- [[06-queue-management/SCAFFOLD]]
