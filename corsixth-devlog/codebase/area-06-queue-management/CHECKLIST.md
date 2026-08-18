# Queue Management — Pre-Fix Checklist

Use this checklist before making any changes to queue-related code in CorsixTH.

---

## 1. Understand the Change Scope

- [ ] Identify which queue type(s) affected: Door queue, Reception queue, or both
- [ ] Determine if change affects: Priority logic, Display logic, Capacity, Bench threshold, Rerouting, UI
- [ ] Check if change impacts: Patient flow, Staff flow, VIP/Inspector, Emergency, Cheats
- [ ] Verify multiplayer/savegame compatibility implications

---

## 2. Priority System Changes

### 2.1 Priority Values (queue.lua:166-188)
- [ ] Priority 1: Leaving (same_room_priority) — **Never increase this value**
- [ ] Priority 2: Staff — **Staff must always enter before patients**
- [ ] Priority 3: VIP/Inspector — **Instant service, hidden from UI**
- [ ] Priority 4: Emergency — **Visible in UI, high priority**
- [ ] Priority 5: Queue-jump cheat — **Conditional, health < 10%**
- [ ] Priority 6: Regular — **Default for all patients**

### 2.2 Display Threshold (queue.lua:195)
- [ ] `reported_priority_threshold = 3` — priorities > 3 show in door queue UI
- [ ] Changing this affects: UI display, reportedSize(), bench threshold logic
- [ ] Test: Leaving/Staff/VIP/Inspector remain hidden; Emergency/Cheat/Regular visible

---

## 3. Queue Operations Checklist

### 3.1 Push (queue.lua:201-231)
- [ ] Priority calculation correct for new humanoid type
- [ ] `reported_size` incremented only for displayable priorities (>3)
- [ ] Callbacks registered for `onChangeQueuePosition`
- [ ] Position change notifications sent to shifted humanoids

### 3.2 Pop (queue.lua:249-268)
- [ ] `reported_size` decremented only if popped was displayed patient
- [ ] Mood "queue" deactivated
- [ ] `onLeaveQueue` callback fired
- [ ] Position change notifications sent to all remaining

### 3.3 Remove/RemoveValue (queue.lua:274-305)
- [ ] Index bounds checked
- [ ] `reported_size` adjusted for displayed patients
- [ ] Mood deactivated
- [ ] `onAdvanceQueue` called for affected humanoids (remove only)
- [ ] Callbacks cleaned up

### 3.4 Move/MovePatient (queue.lua:311-349)
- [ ] Swap logic correct for both directions
- [ ] `movePatient` correctly offsets by `first_patient_index`
- [ ] String 'front'/'back' handled
- [ ] No priority re-evaluation (manual reorder only)

---

## 4. Capacity & Thresholds

### 4.1 Max Size (queue.lua:47, 78-96)
- [ ] Default door: 6, Reception: 20
- [ ] Clamp: 0-30 (queue.lua:85)
- [ ] `increaseMaxSize`/`decreaseMaxSize` respect clamp
- [ ] UI +/- buttons (queue_dialog.lua:67-85) work with modifiers (Ctrl=×10, Shift=×5)

### 4.2 Bench Threshold (queue.lua:48, 88-90)
- [ ] Door default: 0, Reception: 3
- [ ] Used in `humanoid_actions/queue.lua:212-217`
- [ ] First N reported patients forced to stand
- [ ] Only applies to patients (not staff/VIP/leaving)

---

## 5. Door Queue Specifics (door.lua)

- [ ] `setPriorityForSameRoom(self)` called in constructor (line 47)
- [ ] `setupDoor` preserves `visitor_count` and `max_size` on room edit (lines 57-61)
- [ ] `updateDynamicInfo` shows room name + queue size + expected (lines 71-82)
- [ ] `onClick` opens UIQueue for rooms with queue dialog (lines 86-92)
- [ ] `closeDoor` calls `rerouteAllPatients(room_id)` then nils queue (lines 159-162)
- [ ] `checkForDeadlock` verifies reserved humanoid at queue front (lines 171-190)

---

## 6. Reception Desk Specifics (reception_desk.lua)

- [ ] `setBenchThreshold(3)` and `setMaxQueue(20)` in constructor (lines 79-80)
- [ ] `tick()` processes front humanoid with skill-based timer (lines 133-165)
- [ ] Patient handling: new → GP or home; redirected → next room (lines 99-112)
- [ ] VIP: idle + waiting; Inspector: epidemic check + go home (lines 115-128)
- [ ] `getUsageScore` uses `patientSize() * 10` + 1000 if full (lines 198-204)
- [ ] `resetUsageAndReservaton` calls `rerouteAllPatients(nil)` (line 240)

---

## 7. Room Queue Advancement (room.lua:549-565)

- [ ] `tryAdvanceQueue` checks: queue exists, not empty, door not in use, not reserved
- [ ] Front humanoid checked with `canHumanoidEnter(front)`
- [ ] If can enter: pop, update dynamic info, staff wait toggle
- [ ] If already in room (race): pop without entry check
- [ ] Called from: onHumanoidEnter, onHumanoidLeave, deadlock check, queue action start, walk actions

---

## 8. Humanoid Queue Action (humanoid_actions/queue.lua)

### 8.1 Start (lines 371-402)
- [ ] Callbacks registered: on_interrupt, onChangeQueuePosition, onLeaveQueue, onGetSoda, isStanding
- [ ] `unexpect` called before `push`
- [ ] Door dynamic info updated
- [ ] Idle action queued with `isLeaving` flag
- [ ] `tryAdvanceQueue` triggered for same_room_priority

### 8.2 Position Change (lines 201-304)
- [ ] Must-stand logic: non-patient, leaving, disease.must_stand
- [ ] Bench threshold: first `bench_threshold` reported patients stand
- [ ] Sit logic: distance thresholds (4/10), free bench search
- [ ] Stand logic: correct `standing_index` position, facing direction

### 8.3 Interrupt/Leave (lines 310-369)
- [ ] `removeValue` from queue
- [ ] Door dynamic info updated
- [ ] Reserved door user cleanup
- [ ] `finishAction` called

---

## 9. UI Queue Dialog (dialogs/queue_dialog.lua)

- [ ] Metrics displayed: reportedSize, expectedSize, visitor_count, max_size (lines 96-106)
- [ ] Patient drag-drop reordering calls `movePatient` (lines 183-192)
- [ ] Drop on door icon → 'front', exit sign → 'back' (lines 183-186)
- [ ] Drop on same-type room → reroute patient (lines 197-219)
- [ ] Right-click popup: Send to Reception / Send Home (lines 399-407)
- [ ] Hover detection with gap spacing (lines 258-297)

---

## 10. Testing Requirements

### 10.1 Unit Tests (run via busted)
- [ ] Priority ordering for all 6 types
- [ ] Push/pop with mixed types
- [ ] Move/movePatient with staff at front
- [ ] Size limits and clamping
- [ ] Bench threshold behavior
- [ ] Display filtering (reportedSize vs size)
- [ ] Remove by index and value
- [ ] Expected humanoid tracking
- [ ] Reroute on destruction
- [ ] Same-room leaving priority

### 10.2 Integration Tests
- [ ] Patient enters room via door queue
- [ ] Staff enters room via door queue
- [ ] Patient leaves room (priority 1)
- [ ] Reception desk processes VIP/Inspector/Patient
- [ ] Queue full blocks new entries
- [ ] Door close reroutes correctly
- [ ] Room edit preserves queue state
- [ ] Deadlock detection triggers
- [ ] UI drag-drop reorders patients
- [ ] Bench sitting/standing transitions

### 10.3 Edge Cases
- [ ] Empty queue operations
- [ ] Queue with only staff
- [ ] Queue with only leaving patients
- [ ] Emergency patient with queue-jump cheat
- [ ] Max size 0 queue
- [ ] Bench threshold > queue size
- [ ] Rapid push/pop sequences
- [ ] Save/load queue state

---

## 11. Regression Risk Areas

| Area | Risk | Mitigation |
|------|------|------------|
| Priority changes | Breaks staff/leaving precedence | Test all 6 priority combos |
| Display threshold | Patients invisible in UI | Verify reportedSize() matches UI |
| Bench threshold | Patients stuck standing/sitting | Test sit/stand transitions |
| Reroute logic | Patients lost on room delete | Test door close, room edit, reception destroy |
| MovePatient | UI drag corrupts queue | Test drag to front/back/middle/room |
| Same-room priority | Deadlocks on exit | Test concurrent enter/exit |
| Save/load | Queue state lost | Test save mid-queue |

---

## 12. Code Review Checklist

- [ ] No direct array access (`queue[i]`) — use methods
- [ ] Priority logic uses `_getHumanoidQueuePriority` (not duplicated)
- [ ] Display logic uses `_shouldDisplayInDoorQueueInterface`
- [ ] Callbacks properly registered and cleaned up
- [ ] `reported_size` maintained consistently
- [ ] `expected` table managed correctly
- [ ] No memory leaks in callback tables
- [ ] Thread safety (single-threaded Lua, but check for yield points)
- [ ] Save/load serialization handled (afterLoad in queue_dialog.lua:355)

---

## 13. Documentation Updates

- [ ] Update SUMMARY.md if priority values change
- [ ] Update MAP.md if new queue methods added
- [ ] Update CHECKLIST.md if new edge cases found
- [ ] Add inline comments for complex logic
- [ ] Update UI tooltips if display changes

---

## 14. Sign-Off

- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Manual playtest: GP office, Ward, Reception, Emergency
- [ ] Save/load tested
- [ ] Room edit tested
- [ ] Multiplayer sync verified (if applicable)
- [ ] Code reviewed by second developer

---

*Checklist Version: 1.0*
*Last Updated: Based on CorsixTH queue.lua (384 lines), door.lua, reception_desk.lua, room.lua:549-565*
