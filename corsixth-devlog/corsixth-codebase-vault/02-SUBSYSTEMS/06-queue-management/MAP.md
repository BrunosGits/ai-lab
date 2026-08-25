# Queue Management — File:Line Index

Comprehensive cross-reference for all queue-related operations in CorsixTH.

---

## Core Queue Implementation

### `Lua/queue.lua` (384 lines)

| Line | Function/Section | Description |
|------|------------------|-------------|
| 31 | `class "Queue"` | Class definition |
| 37-49 | `Queue:Queue()` | Constructor — initializes reported_size, expected, callbacks, visitor_count, max_size=6, bench_threshold=0 |
| 54-62 | `Queue:expect(humanoid, callback)` | Register expected humanoid (patients increment expected_count) |
| 66-74 | `Queue:unexpect(humanoid)` | Cancel expectation |
| 78-80 | `Queue:decreaseMaxSize(amount)` | Decrement max_size (min 0) |
| 84-86 | `Queue:increaseMaxSize(amount)` | Increment max_size (max 30) |
| 88-90 | `Queue:setBenchThreshold(standing_count)` | Set bench threshold |
| 94-96 | `Queue:setMaxQueue(queue_count)` | Set max queue length |
| 101-108 | `Queue:size()` | Total queue length (#self) — includes staff/leaving |
| 112-114 | `Queue:isFull()` | `size() >= max_size` |
| 118-120 | `Queue:reportedSize()` | Real patients visible in UI |
| 124-126 | `Queue:expectedSize()` | Expected patient count |
| 130-137 | `Queue:hasEmergencyPatient()` | Scans for `humanoid.is_emergency` |
| 141-143 | `Queue:patientSize()` | `reportedSize() + expectedSize()` |
| 148-150 | `Queue:reportedHumanoid(index)` | Gets index-th reported patient |
| 152-154 | `Queue:setPriorityForSameRoom(entity)` | Enables leaving priority for entity's room |
| 156-158 | `_isLeaving(queue, humanoid)` | Helper: checks if humanoid leaving same room |
| 166-188 | `_getHumanoidQueuePriority(queue, humanoid)` | **Priority calculation** (1=leaving, 2=staff, 3=VIP/Inspector, 4=emergency, 5=cheat, 6=regular) |
| 194-197 | `_shouldDisplayInDoorQueueInterface(priority)` | Display filter: `priority > 3` |
| 201-231 | `Queue:push(humanoid, callbacks_on)` | **Priority insert** — maintains order, updates reported_size, notifies shifted |
| 236-238 | `Queue:front()` | First element (any type) |
| 242-244 | `Queue:back()` | Last element (any type) |
| 249-268 | `Queue:pop()` | **Remove front** — adjusts reported_size, fires callbacks, notifies remaining |
| 274-292 | `Queue:remove(index)` | Remove by absolute index — adjusts reported_size, fires onAdvanceQueue |
| 297-305 | `Queue:removeValue(value)` | Find and remove by reference |
| 311-329 | `Queue:move(index, new_index)` | Swap adjacent iteratively for drag-drop |
| 337-349 | `Queue:movePatient(index, new_index)` | **Move relative to reported patients** — handles 'front'/'back' strings |
| 353-384 | `Queue:rerouteAllPatients(room_id)` | **Destruction handler** — patients→SeekRoom/SeekReception, staff→Meander, calls expected callbacks |

---

## Door Queue Integration

### `Lua/objects/door.lua` (209 lines)

| Line | Function/Section | Description |
|------|------------------|-------------|
| 33 | `corsixth.require("queue")` | Module import |
| 42 | `self.queue = Queue()` | Queue creation in constructor |
| 47 | `self.queue:setPriorityForSameRoom(self)` | **Enables leaving priority** for this door's room |
| 48 | `self.hover_cursor = loadMainCursor("queue")` | Queue cursor |
| 57-61 | `Door:setupDoor(room, old_door)` | Room edit: preserves visitor_count, max_size from old door |
| 65-67 | `Door:getRoom()` | Returns room reference |
| 71-83 | `Door:updateDynamicInfo()` | Tooltip: room name + reportedSize + expectedSize |
| 86-92 | `Door:onClick(ui, button)` | Left-click opens UIQueue if room has queue dialog |
| 159-165 | `Door:closeDoor()` | **Destroys queue**: rerouteAllPatients(room_id), nil queue, clear info |
| 171-190 | `Door:checkForDeadlock()` | Verifies reserved humanoid at queue front; calls tryAdvanceQueue |
| 184 | `self:getRoom():tryAdvanceQueue()` | Deadlock resolution |
| 192-208 | `Door:afterLoad(old, new)` | Save/load: updates dynamic info |

---

## Reception Desk Queue Integration

### `Lua/objects/reception_desk.lua` (263 lines)

| Line | Function/Section | Description |
|------|------------------|-------------|
| 69 | `corsixth.require("queue")` | Module import |
| 78 | `self.queue = Queue()` | Queue creation |
| 79 | `self.queue:setBenchThreshold(3)` | **Keep 3 standing** (reception default) |
| 80 | `self.queue:setMaxQueue(20)` | **Larger queue** (door default is 6) |
| 81 | `self.hover_cursor = loadMainCursor("queue")` | Queue cursor |
| 82 | `self.queue_advance_timer = 0` | Skill-based processing timer |
| 85-92 | `ReceptionDesk:onClick(ui, button)` | Left-click opens UIQueue |
| 94-167 | `ReceptionDesk:tick()` | **Main processing loop** |
| 99-112 | `handlePatient(patient, is_new)` | New→GP/home; redirected→next room |
| 115-118 | `handleVIP(vip)` | Idle action, set waiting |
| 121-128 | `handleInspector(inspector)` | Epidemic handling, go home |
| 133-138 | `advanceQueue(humanoid)` | Timer: `4 + hoursPerDay * (1 - skill)` |
| 141-161 | Front humanoid processing | Calls type handler, pop, visitor_count++, reset timer |
| 169-194 | `checkForNearbyStaff()` | Finds receptionist, occupies desk |
| 197-205 | `getUsageScore()` | `patientSize() * 10 + (full ? 1000 : 0)` |
| 207-214 | `setTile(x, y)` | Triggers staff search on placement |
| 221-244 | `resetUsageAndReservaton()` | **Destruction**: rerouteAllPatients(nil), handle receptionist |
| 240 | `self.queue:rerouteAllPatients(nil)` | nil = send to reception |
| 251-261 | `occupy(receptionist)` | Orders receptionist to desk |

---

## Room Queue Advancement

### `Lua/room.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 356 | `self:tryAdvanceQueue()` | After staff enters |
| 408 | `self:tryAdvanceQueue()` | After staff enters (alternate path) |
| 412 | `self:tryAdvanceQueue()` | After patient enters |
| 549-565 | `Room:tryAdvanceQueue()` | **Core advancement logic** |
| 550 | `if self.door.queue and self.door.queue:size() > 0 and not self.door.user and not self.door.reserved_for` | Preconditions |
| 551 | `local front = self.door.queue:front()` | Get front humanoid |
| 554-559 | `if self:canHumanoidEnter(front)` | Can enter → pop, update info, staff wait toggle |
| 560-563 | `elseif self.humanoids[front]` | Already in room → pop without entry check |
| 601 | `self:tryAdvanceQueue()` | After humanoid leaves (non-staff) |
| 643 | `self:tryAdvanceQueue()` | After handyman leaves during repair |
| 739 | `self:tryAdvanceQueue()` | After staff leaves |

---

## Humanoid Queue Action

### `Lua/humanoid_actions/queue.lua` (404 lines)

| Line | Function/Section | Description |
|------|------------------|-------------|
| 21-42 | `QueueAction:QueueAction(x, y, queue)` | Constructor |
| 47-52 | `setReserveWhenDone(door)` | Door to reserve when leaving queue |
| 58-65 | `setFaceDirection(face_x, face_y)` | Facing tile for queue position |
| 201-304 | `action_queue_on_change_position` | **Bench/stand logic** |
| 208-218 | Must-stand check | Non-patient, leaving, disease.must_stand, bench_threshold |
| 212-217 | `for i = 1, queue.bench_threshold do` | First N reported patients stand |
| 221-260 | Sit logic | Distance thresholds (4/10), free bench search |
| 263-303 | Stand logic | Correct standing_index position, facing direction |
| 306-308 | `action_queue_is_standing` | Returns `not current_bench_distance` |
| 310-322 | `action_queue_on_leave` | Cleanup: is_in_queue=false, reserve door, interrupt_head |
| 325-354 | `action_queue_get_soda` | Thirst handling: walk to machine, use, resume queue |
| 356-369 | `action_queue_interrupt` | Remove from queue, update door, cleanup reservation |
| 371-402 | `action_queue_start` | **Action initialization** |
| 380-384 | Callback registration | on_interrupt, onChangeQueuePosition, onLeaveQueue, onGetSoda, isStanding |
| 386-387 | `queue:unexpect(humanoid); queue:push(humanoid, action)` | Join queue |
| 389-395 | Door dynamic info update | Patient mood text |
| 396 | `humanoid:queueAction(IdleAction():setMustHappen(true):setIsLeaving(...), 0)` | Initial idle |
| 397 | `action:onChangeQueuePosition(humanoid)` | Initial position update |
| 399-401 | `queue.same_room_priority:getRoom():tryAdvanceQueue()` | Trigger room advancement |

---

## UI Queue Dialog

### `Lua/dialogs/queue_dialog.lua` (414 lines)

| Line | Function/Section | Description |
|------|------------------|-------------|
| 24 | `class "UIQueue" (Window)` | Queue window class |
| 29-65 | `UIQueue:UIQueue(ui, queue)` | Constructor — panels, buttons, tooltips |
| 67-75 | `decreaseMaxSize()` | -1/-5/-10 (Ctrl/Shift) |
| 77-85 | `increaseMaxSize()` | +1/+5/+10 (Ctrl/Shift) |
| 87-114 | `draw(canvas, x, y)` | Renders metrics + patients |
| 94-97 | Metrics: reportedSize | `queue:reportedSize()` |
| 99-100 | Metrics: expectedSize | `queue:expectedSize()` |
| 102-103 | Metrics: visitor_count | `queue.visitor_count` |
| 105-106 | Metrics: max_size | `queue.max_size` |
| 125-147 | `onMouseDown` | Drag start, right-click popup |
| 149-222 | `onMouseUp` | **Drag-drop reordering** |
| 183-184 | Drop on door → `movePatient(index, 'front')` | Move to front |
| 185-186 | Drop on exit → `movePatient(index, 'back')` | Move to back |
| 187-192 | Drop in queue → `movePatient(index, position)` | Move to position |
| 197-219 | Drop on room → reroute to same-type room | Room transfer |
| 258-297 | `getHoveredPatient(x)` | Hover detection with gap |
| 299-335 | `drawPatients/drawPatient` | Patient sprite rendering |
| 337-353 | `drawPatient` | Animation + mood drawing |
| 362-414 | `UIQueuePopup` | Right-click menu: Send to Reception / Send Home |
| 399-401 | `sendToReception()` | `SeekReceptionAction()` |
| 404-406 | `sendHome()` | `goHome("kicked")` |

---

## Patient Queue Checks

### `Lua/entities/humanoids/patient.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 562 | `self.world.dispatcher:dropFromQueue(self)` | Drop from dispatcher queue |
| 903-928 | `_checkPatientIsStillQueueingForARoom()` | Validates patient still in queue action's queue |
| 1064-1066 | Queue action position change callback | Calls `onChangeQueuePosition` |

---

## Dispatcher Queue

### `Lua/calls_dispatcher.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 426 | `call.dispatcher:dropFromQueue(call.object, call.key)` | Drop call from queue |
| 445 | `CallsDispatcher:dropFromQueue(object, key)` | Remove queued call |

---

## World Dispatcher

### `Lua/world.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 657 | `self.dispatcher:dropFromQueue(room)` | Drop room from dispatcher queue |

---

## Entity Base

### `Lua/entity.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 293 | `self.world.dispatcher:dropFromQueue(self)` | Entity removal from dispatcher queue |

---

## Machine Queue Interaction

### `Lua/entities/machine.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 431 | `self.world.dispatcher:dropFromQueue(self)` | Machine drops from dispatcher |
| 434 | `self:getRoom():tryAdvanceQueue()` | Advance room queue after machine done |

---

## Special Room Queue Calls

### `Lua/rooms/training.lua:196`
```lua
self:tryAdvanceQueue()
```

### `Lua/rooms/staff_room.lua:51`
```lua
self:tryAdvanceQueue()
```

### `Lua/rooms/operating_theatre.lua:141`
```lua
self:tryAdvanceQueue()
```

---

## VIP Queue Interaction

### `Lua/entities/humanoids/vip.lua:466`
```lua
room:tryAdvanceQueue()
```

---

## Humanoid Base

### `Lua/entities/humanoid.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 652 | `dest_room:tryAdvanceQueue()` | After humanoid reaches destination |
| 745 | `_handleEmptyActionQueue()` | Action queue management |
| 894 | `callbacks:onChangeQueuePosition(humanoid)` | Position change callback |
| 942 | `action_queue[i + 1]:onChangeQueuePosition(self)` | Internal queue position callback |

---

## Staff Queue Messages

### `Lua/entities/humanoids/staff.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 229 | `removeQueuedStaffMessage()` | Remove queued message |
| 244 | `removeQueuedStaffMessage()` | Remove queued message |
| 266 | `removeQueuedStaffMessage()` | Remove queued message |

---

## Door Action Queue Interactions

### `Lua/humanoid_actions/knock_door.lua:85`
```lua
door:getRoom():tryAdvanceQueue()
```

### `Lua/objects/doors/swing_door_right.lua:165`
```lua
self:getRoom():tryAdvanceQueue()
```

### `Lua/humanoid_actions/walk.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 83 | `door:getRoom():tryAdvanceQueue()` | After walking through door |
| 299 | `room:tryAdvanceQueue()` | After walking to room |
| 309 | `room:tryAdvanceQueue()` | After walking to room (alternate) |

---

## Hospital Long Queue Warning

### `Lua/hospitals/player_hospital.lua`

| Line | Function/Section | Description |
|------|------------------|-------------|
| 88 | `self:_warnForLongQueues()` | Called periodically |
| 253 | `_warnForLongQueues()` | Checks all rooms for long queues |

---

## Game UI Queue Icons

### `Lua/game_ui.lua:478`
```lua
-- Queueing icons over patients
```

---

## Announcement Queue (Separate System)

### `Lua/announcer.lua:45`
```lua
class "AnnouncementQueue"
```
*Note: Separate from humanoid queue system — for UI announcements*

---

## Language Files (Queue Window Strings)

- `Lua/languages/finnish.lua:1507, 2738`
- `Lua/languages/norwegian.lua:416, 3114`
- `Lua/languages/danish.lua:1365, 2393`
- `Lua/languages/hungarian.lua:1110`

---

## Quick Reference: Key Entry Points

| Operation | Primary File:Line |
|-----------|-------------------|
| Create queue | `queue.lua:37` |
| Join queue (humanoid) | `humanoid_actions/queue.lua:387` |
| Priority calculation | `queue.lua:166` |
| Display filter | `queue.lua:195` |
| Process door queue | `room.lua:549` |
| Process reception queue | `reception_desk.lua:141` |
| UI open door queue | `door.lua:89` |
| UI open reception queue | `reception_desk.lua:87` |
| Drag-drop reorder | `queue_dialog.lua:184` |
| Bench threshold logic | `humanoid_actions/queue.lua:212` |
| Reroute on destroy | `queue.lua:353` |
| Deadlock check | `door.lua:171` |
| Save/load queue UI | `queue_dialog.lua:355` |

---

*Generated from CorsixTH source analysis — Queue Management System*


## Related Pages

- [[06-queue-management/SUMMARY]]
- [[06-queue-management/CHECKLIST]]
- [[06-queue-management/SCAFFOLD]]
