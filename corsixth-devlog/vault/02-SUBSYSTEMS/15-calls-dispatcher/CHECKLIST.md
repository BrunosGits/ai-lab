# CallsDispatcher Pre-Fix Checklist

## Before Making Changes

### 1. Understand Current Behavior
- [ ] Read entire `calls_dispatcher.lua` (567 lines)
- [ ] Trace call flow: enqueue → findSuitableStaff/answerCall → executeCall → checkpoint → completion
- [ ] Identify all 5 call types: staff, repair, watering, vaccination, (cleaning)
- [ ] Map verification/priority/execute callbacks for each type
- [ ] Understand preemption logic in `answerCall` (lines 338-343)
- [ ] Understand drop mechanism in `dropFromQueue` (lines 445-466)
- [ ] Review Entity:onPickUp (entity.lua:293) and Hospital:notifyRoomRemoved (hospital.lua:657)

### 2. Backup & Version Control
- [ ] Commit current state: `git add -A && git commit -m "Pre-dispatcher-fix baseline"`
- [ ] Create feature branch: `git checkout -b fix/dispatcher-<issue>`
- [ ] Document issue number/reference in commit messages

### 3. Test Coverage Baseline
- [ ] Run existing tests: `busted Lua/test/`
- [ ] Verify all dispatcher-related tests pass
- [ ] Note any skipped/pending tests
- [ ] Check test coverage for: enqueue, findSuitableStaff, answerCall, preemption, dropFromQueue, callForStaff/Repair/Watering/Vaccination

---

## During Implementation

### 4. Queue Structure Changes
- [ ] **call_queue[object][key]** structure preserved
- [ ] No breaking changes to call table schema
- [ ] Persistable callbacks remain serializable (no upvalues)
- [ ] `created` tick timestamp maintained
- [ ] `dropped` flag semantics unchanged

### 5. Verification Callbacks
- [ ] Staff verification: `verifyStaffForRoom` — idle, criterion, room policy
- [ ] Repair verification: always false (handyman pull model)
- [ ] Watering verification: always false (handyman pull model)
- [ ] Vaccination verification: nurse, idle, proximity, no room
- [ ] Custom verification: pure functions, no closure captures

### 6. Priority Callbacks
- [ ] Staff priority: distance, queue, emergency, fatigue, wandering, specialist
- [ ] Repair/Watering priority: constant 1
- [ ] Vaccination priority: path distance + unreachable penalty
- [ ] Lower score = higher priority (consistent)
- [ ] No division by zero or nil returns

### 7. Execute Callbacks
- [ ] Staff execute: `sendStaffToRoom` → EnterRoomAction + checkpoint
- [ ] Repair execute: `sendStaffToRepair` → object:createHandymanActions
- [ ] Watering execute: `sendStaffToWatering` → plant:createHandymanActions
- [ ] Vaccination execute: `sendNurseToVaccinate` → Epidemic:createVaccinationActions
- [ ] All execute callbacks must queue `CallCheckPointAction`

### 8. Dispatch Algorithm Changes
- [ ] **Push model** (`findSuitableStaff`): iterates all entities
  - [ ] Skips Handymen (correct)
  - [ ] Handles dropped calls
  - [ ] Calls `onChange()` when queued
  - [ ] TODO: Preempt staff on_call for urgent calls
- [ ] **Pull model** (`answerCall`): staff searches queue
  - [ ] Handymen delegate to `searchForHandymanTask`
  - [ ] Preemption logic: compare priority scores
  - [ ] Validates object exists (`tile_x` or `x`)
  - [ ] Calls `executeCall` on match

### 9. Preemption Logic
- [ ] Only in `answerCall` (staff-initiated)
- [ ] Condition: `another_score <= score` blocks preemption
- [ ] `unassignCall(call, true)` gives preempted staff `AnswerCallAction`
- [ ] No preemption in `findSuitableStaff` (documented TODO)

### 10. Drop Mechanism
- [ ] `dropFromQueue(object, key)` — specific call
- [ ] `dropFromQueue(object)` — all calls for object
- [ ] Sets `call.dropped = true`
- [ ] Unassigns staff with `answer_next_call=true`
- [ ] Calls `onChange()` after modification
- [ ] Triggers: Entity:onPickUp, Room removed, Call completed

### 11. Checkpoint System
- [ ] `queueCallCheckpointAction` inserts `CallCheckPointAction`
- [ ] Default handler: `actionInterruptHandler` → re-dispatch
- [ ] Staff handler: `staffActionInterruptHandler` → re-call `callForStaff`
- [ ] Completion: `onCheckpointCompleted` → drop from queue
- [ ] Interrupt handler receives `(action, humanoid)`

### 12. Call Type Specifics

#### Staff Calls (`callForStaff`)
- [ ] Creates one call per missing staff slot (`attribute + index`)
- [ ] Plays announcement sound once per room
- [ ] Uses room-specific verification/priority/execute

#### Repair Calls (`callForRepair`)
- [ ] Parameters: object, urgent, manual
- [ ] Advisory: urgent+!manual → machines_falling_apart
- [ ] Advisory: no handymen → machinery_damaged2
- [ ] Key: "repair"

#### Watering Calls (`callForWatering`)
- [ ] Key: "watering"
- [ ] Description includes tile coordinates

#### Vaccination Calls (`callNurseForVaccination`)
- [ ] Key: "vaccinate"
- [ ] Verification: nurse, idle, proximity ≤5 tiles
- [ ] Priority: path distance
- [ ] Execute: Epidemic vaccination actions

---

## Testing Requirements

### 13. Unit Tests (Busted)
- [ ] **enqueue**: new call, duplicate, immediate serve, assigned
- [ ] **findSuitableStaff**: dropped, no staff, selects best, skips handymen
- [ ] **answerCall**: handyman delegation, finds best, preemption, object validation
- [ ] **preemption**: unassigns current, gives AnswerCallAction, blocks when appropriate
- [ ] **dropFromQueue**: by key, all calls, unassigns staff, change callback
- [ ] **executeCall**: assigns, callbacks, assertions
- [ ] **checkpoints**: default handler, staff handler, completion
- [ ] **callForStaff**: multiple criteria, sound, callbacks
- [ ] **callForRepair**: urgent, manual, no handymen advisories
- [ ] **callForWatering**: structure
- [ ] **callNurseForVaccination**: verification, priority, execute
- [ ] **verifyStaffForRoom**: idle, criterion, room policy
- [ ] **getPriorityForRoom**: distance, queue, emergency, fatigue, wandering, specialist
- [ ] **sendStaffToRoom**: enter action, re-enter
- [ ] **sendStaffToRepair/Watering**: delegates correctly

### 14. Integration Tests
- [ ] Entity picked up → drops calls
- [ ] Room removed → drops calls
- [ ] Call completed → drops from queue
- [ ] Staff interrupted → re-queues correctly
- [ ] Save/load persistable callbacks work

### 15. Edge Cases
- [ ] Empty queue operations
- [ ] Destroyed objects in queue
- [ ] Staff destroyed while on call
- [ ] Multiple calls for same object/key
- [ ] Simultaneous enqueue/answerCall
- [ ] Policy changes mid-dispatch (staff_allowed_to_move)

---

## Code Quality

### 16. Code Style
- [ ] Consistent indentation (2 spaces)
- [ ] Type annotations in comments (---@type, --!param)
- [ ] Persistable callbacks marked with `--[[persistable:...]]`
- [ ] Local variables for performance (min_score, min_staff)
- [ ] Assert statements for invariants

### 17. Documentation
- [ ] Function headers with param/return descriptions
- [ ] TODO comments for known limitations
- [ ] Inline comments for complex logic
- [ ] Debug dump functions preserved

### 18. Performance
- [ ] `findSuitableStaff` iterates all entities — consider caching
- [ ] `answerCall` iterates all queues — consider indexing
- [ ] Path distance calculations cached where possible
- [ ] Avoid creating tables in hot paths

---

## Post-Fix Verification

### 19. Regression Testing
- [ ] Run full test suite: `busted Lua/test/`
- [ ] Manual test: Start game, build rooms, hire staff, verify calls dispatch
- [ ] Test machine breakdown → handyman repair
- [ ] Test plant watering
- [ ] Test epidemic vaccination
- [ ] Test room staffing
- [ ] Test staff pickup → calls dropped
- [ ] Test room deletion → calls dropped

### 20. Save/Load Testing
- [ ] Save game with active calls
- [ ] Load game → calls restored correctly
- [ ] Persistable callbacks execute after load
- [ ] No "attempt to call nil value" errors

### 21. Performance Testing
- [ ] Large hospital (50+ staff, 20+ rooms)
- [ ] Monitor tick time with debug_enabled=true
- [ ] Check for memory leaks in call_queue

### 22. Documentation Update
- [ ] Update SUMMARY.md if algorithms changed
- [ ] Update MAP.md with new line numbers
- [ ] Update CHECKLIST.md with new considerations
- [ ] Add comments for any new TODOs

---

## Sign-Off

- [ ] All checklist items verified
- [ ] Code reviewed by teammate
- [ ] Tests passing
- [ ] No regressions in manual testing
- [ ] PR created with clear description
- [ ] Linked to issue tracker

---

*Checklist version: 1.0 | Generated for CorsixTH CallsDispatcher area*
